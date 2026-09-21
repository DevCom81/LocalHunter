// Google Places (New) — recherche textuelle (Phase 6).
// Découverte niveau 1. Cache dédié `places_search_cache` (pas enrichment_cache).

export const PLACES_CACHE_TTL_DAYS = 30;
/** Google Places (New) : 20 résultats max par page, 60 max au total. */
export const PLACES_MAX_RESULTS_LIMIT = 60;
export const PLACES_PAGE_SIZE = 20;
/** Invalide le cache antérieur à internationalPhoneNumber (Phase 11). */
export const PLACES_FIELD_MASK_VERSION = 3;

export const PLACES_FIELD_MASK =
  "nextPageToken,places.id,places.displayName,places.formattedAddress," +
  "places.rating,places.userRatingCount,places.types," +
  "places.nationalPhoneNumber,places.internationalPhoneNumber," +
  "places.websiteUri,places.businessStatus";

export interface PlaceProspect {
  name: string;
  city: string;
  address: string;
  phone: string | null;
  website: string | null;
  google_rating: number | null;
  google_reviews: number;
  category: string;
  google_place_id: string;
  /** OPERATIONAL | CLOSED_TEMPORARILY | CLOSED_PERMANENTLY */
  business_status: string | null;
}

export interface PlacesQueryPayload {
  city: string;
  sector: string;
  radiusKm: number;
  maxResults: number;
  fieldMaskVersion: number;
}

interface NewPlace {
  id?: string;
  displayName?: { text?: string };
  formattedAddress?: string;
  rating?: number;
  userRatingCount?: number;
  types?: string[];
  nationalPhoneNumber?: string;
  internationalPhoneNumber?: string;
  websiteUri?: string;
  businessStatus?: string;
}

export async function sha256Hex(input: string): Promise<string> {
  const data = new TextEncoder().encode(input);
  const hash = await crypto.subtle.digest("SHA-256", data);
  return Array.from(new Uint8Array(hash))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

export function buildPlacesQueryPayload(args: {
  city: string;
  sector: string;
  radiusKm?: number;
  maxResults?: number;
}): PlacesQueryPayload {
  return {
    city: args.city,
    sector: args.sector,
    radiusKm: args.radiusKm ?? 15,
    maxResults: Math.min(
      args.maxResults ?? 20,
      PLACES_MAX_RESULTS_LIMIT,
    ),
    fieldMaskVersion: PLACES_FIELD_MASK_VERSION,
  };
}

export async function placesCacheKey(
  payload: PlacesQueryPayload,
): Promise<string> {
  return sha256Hex(JSON.stringify(payload));
}

export { cacheExpiryIso } from "../cache_ttl.ts";

export function mapPlace(place: NewPlace, city: string): PlaceProspect {
  const types = place.types ?? [];
  const category =
    types.find((t) => !["point_of_interest", "establishment"].includes(t)) ??
    "établissement";
  return {
    name: place.displayName?.text ?? "Sans nom",
    city,
    address: place.formattedAddress ?? city,
    phone: place.nationalPhoneNumber ??
      place.internationalPhoneNumber ??
      null,
    website: place.websiteUri ?? null,
    google_rating: place.rating ?? null,
    google_reviews: place.userRatingCount ?? 0,
    category,
    google_place_id: place.id ?? "",
    business_status: place.businessStatus ?? null,
  };
}

/**
 * Recherche textuelle paginée (searchText).
 * Lève en cas d'erreur HTTP Google.
 */
export async function searchPlacesNewApi(
  apiKey: string,
  textQuery: string,
  maxResults: number,
): Promise<PlaceProspect[]> {
  const collected: PlaceProspect[] = [];
  let pageToken: string | undefined;

  while (collected.length < maxResults) {
    const res = await fetch(
      "https://places.googleapis.com/v1/places:searchText",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-Goog-Api-Key": apiKey,
          "X-Goog-FieldMask": PLACES_FIELD_MASK,
        },
        body: JSON.stringify({
          textQuery,
          pageSize: PLACES_PAGE_SIZE,
          ...(pageToken ? { pageToken } : {}),
          languageCode: "fr",
          regionCode: "FR",
        }),
      },
    );

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

export function buildTextQuery(sector: string, city: string): string {
  return `${sector} ${city} France`;
}
