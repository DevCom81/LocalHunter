import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const CACHE_TTL_DAYS = 30;
// Google Places (New) : 20 résultats max par page, 60 max au total
// via pagination (nextPageToken).
const MAX_RESULTS_LIMIT = 60;
const PAGE_SIZE = 20;
const PLACES_FIELD_MASK =
  "nextPageToken,places.id,places.displayName,places.formattedAddress,places.rating,places.userRatingCount,places.types,places.nationalPhoneNumber,places.websiteUri";

interface SearchRequest {
  city: string;
  sector: string;
  radiusKm?: number;
  maxResults?: number;
}

interface PlaceProspect {
  name: string;
  city: string;
  address: string;
  phone: string | null;
  website: string | null;
  google_rating: number | null;
  google_reviews: number;
  category: string;
  google_place_id: string;
}

interface NewPlace {
  id?: string;
  displayName?: { text?: string };
  formattedAddress?: string;
  rating?: number;
  userRatingCount?: number;
  types?: string[];
  nationalPhoneNumber?: string;
  websiteUri?: string;
}

async function sha256(input: string): Promise<string> {
  const data = new TextEncoder().encode(input);
  const hash = await crypto.subtle.digest("SHA-256", data);
  return Array.from(new Uint8Array(hash))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

function mapPlace(place: NewPlace, city: string): PlaceProspect {
  const types = place.types ?? [];
  const category =
    types.find((t) => !["point_of_interest", "establishment"].includes(t)) ??
    "établissement";
  return {
    name: place.displayName?.text ?? "Sans nom",
    city,
    address: place.formattedAddress ?? city,
    phone: place.nationalPhoneNumber ?? null,
    website: place.websiteUri ?? null,
    google_rating: place.rating ?? null,
    google_reviews: place.userRatingCount ?? 0,
    category,
    google_place_id: place.id ?? "",
  };
}

async function searchPlacesNewApi(
  apiKey: string,
  textQuery: string,
  maxResults: number,
): Promise<PlaceProspect[]> {
  const collected: PlaceProspect[] = [];
  let pageToken: string | undefined;

  // Pagination : l'API renvoie 20 résultats max par appel, on suit
  // nextPageToken jusqu'à maxResults (plafond Google : 60).
  while (collected.length < maxResults) {
    const res = await fetch("https://places.googleapis.com/v1/places:searchText", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": apiKey,
        "X-Goog-FieldMask": PLACES_FIELD_MASK,
      },
      // pageSize constant : l'API exige des paramètres identiques entre
      // la requête initiale et les requêtes paginées (pageToken).
      body: JSON.stringify({
        textQuery,
        pageSize: PAGE_SIZE,
        ...(pageToken ? { pageToken } : {}),
        languageCode: "fr",
        regionCode: "FR",
      }),
    });

    const data = await res.json();
    if (!res.ok) {
      const msg = data?.error?.message ?? JSON.stringify(data);
      throw new Error(`Google Places (New): ${msg}`);
    }

    const places = (data.places as NewPlace[]) ?? [];
    collected.push(
      ...places.map((p) => mapPlace(p, textQuery.split(" ")[1] ?? "")),
    );

    pageToken = data.nextPageToken as string | undefined;
    if (!pageToken || places.length === 0) break;
  }

  return collected.slice(0, maxResults);
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "authorization, content-type",
      },
    });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return Response.json({ error: "Non authentifié" }, { status: 401 });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const apiKey = Deno.env.get("GOOGLE_PLACES_API_KEY");
    if (!apiKey) {
      return Response.json({ error: "GOOGLE_PLACES_API_KEY manquante" }, { status: 500 });
    }

    const userClient = createClient(supabaseUrl, Deno.env.get("SUPABASE_ANON_KEY")!, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: userData, error: userError } = await userClient.auth.getUser();
    if (userError || !userData.user) {
      return Response.json({ error: "Token invalide" }, { status: 401 });
    }
    const userId = userData.user.id;

    const body: SearchRequest = await req.json();
    const city = body.city?.trim();
    const sector = body.sector?.trim() ?? "restaurant";
    // Le plafond de 20 clampait toute demande plus large, produisant le
    // même cache_key qu'une recherche à 20 : le cache répondait à la place
    // d'une vraie recherche élargie.
    const maxResults = Math.min(body.maxResults ?? 20, MAX_RESULTS_LIMIT);
    if (!city) {
      return Response.json({ error: "city requis" }, { status: 400 });
    }

    const queryPayload = { city, sector, radiusKm: body.radiusKm ?? 15, maxResults };
    const cacheKey = await sha256(JSON.stringify(queryPayload));

    const admin = createClient(supabaseUrl, serviceKey);
    const { data: cached } = await admin
      .from("places_search_cache")
      .select("results, expires_at")
      .eq("user_id", userId)
      .eq("cache_key", cacheKey)
      .maybeSingle();

    if (cached && new Date(cached.expires_at) > new Date()) {
      return Response.json({
        prospects: cached.results,
        fromCache: true,
        count: (cached.results as unknown[]).length,
      });
    }

    const textQuery = `${sector} ${city} France`;
    const results = await searchPlacesNewApi(apiKey, textQuery, maxResults)
      .then((items) => items.map((p) => ({ ...p, city })));

    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + CACHE_TTL_DAYS);

    await admin.from("places_search_cache").upsert({
      user_id: userId,
      cache_key: cacheKey,
      query: queryPayload,
      results,
      expires_at: expiresAt.toISOString(),
    }, { onConflict: "user_id,cache_key" });

    return Response.json({ prospects: results, fromCache: false, count: results.length });
  } catch (e) {
    return Response.json({ error: String(e) }, { status: 502 });
  }
});
