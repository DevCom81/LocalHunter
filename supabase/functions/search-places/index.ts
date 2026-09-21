// Recherche Google Places (New) — coquille HTTP (Phase 6).
// Auth + cache user-scoped + métriques ici ; logique métier dans `_shared/enrichment/places`.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsJson, corsPreflight } from "../_shared/cors.ts";
import {
  createPlacesProvider,
  type PlacesSearchCacheAccess,
  type PlaceProspect,
} from "../_shared/enrichment/places/mod.ts";
import { runSingleProvider } from "../_shared/enrichment/pipeline.ts";
import type { EnrichmentContext } from "../_shared/enrichment/types.ts";
import {
  classifyError,
  nowMs,
  recordMetric,
} from "../_shared/metrics.ts";

interface SearchRequest {
  city: string;
  sector: string;
  radiusKm?: number;
  maxResults?: number;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return corsPreflight();
  }

  const started = nowMs();
  // deno-lint-ignore no-explicit-any
  let admin: any = null;
  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return corsJson({ error: "Non authentifié" }, { status: 401 });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const apiKey = Deno.env.get("GOOGLE_PLACES_API_KEY");
    if (!apiKey) {
      return corsJson(
        { error: "GOOGLE_PLACES_API_KEY manquante" },
        { status: 500 },
      );
    }

    const userClient = createClient(
      supabaseUrl,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } },
    );
    const { data: userData, error: userError } = await userClient.auth
      .getUser();
    if (userError || !userData.user) {
      return corsJson({ error: "Token invalide" }, { status: 401 });
    }
    const userId = userData.user.id;

    const body: SearchRequest = await req.json();
    const city = body.city?.trim();
    const sector = body.sector?.trim() ?? "restaurant";
    if (!city) {
      return corsJson({ error: "city requis" }, { status: 400 });
    }

    admin = createClient(supabaseUrl, serviceKey);

    const cache: PlacesSearchCacheAccess = {
      async get(cacheKey) {
        const { data: cached } = await admin
          .from("places_search_cache")
          .select("results, expires_at")
          .eq("user_id", userId)
          .eq("cache_key", cacheKey)
          .maybeSingle();
        if (!cached) return null;
        return {
          results: cached.results as PlaceProspect[],
          expiresAt: cached.expires_at as string,
        };
      },
      async upsert({ cacheKey, query, results, expiresAt }) {
        await admin.from("places_search_cache").upsert({
          user_id: userId,
          cache_key: cacheKey,
          query,
          results,
          expires_at: expiresAt,
        }, { onConflict: "user_id,cache_key" });
      },
    };

    const provider = createPlacesProvider({ apiKey, cache });
    const ctx: EnrichmentContext = {
      prospectId: "places-search",
      knownData: {
        city,
        sector,
        radiusKm: body.radiusKm ?? null,
        maxResults: body.maxResults ?? null,
      },
      options: { enabledProviders: ["places"] },
    };

    const result = await runSingleProvider(provider, ctx);

    if (result.status === "skipped") {
      return corsJson({ error: "city requis" }, { status: 400 });
    }
    if (result.status === "failed") {
      await recordMetric(admin, {
        source: "places",
        status: "failure",
        errorType: result.error?.type ?? "other",
        durationMs: nowMs() - started,
      });
      return corsJson(
        { error: result.error?.message ?? "places_failed" },
        { status: 502 },
      );
    }

    const prospects = (result.data.prospects ?? []) as PlaceProspect[];
    const fromCache = result.data.fromCache === true;

    await recordMetric(admin, {
      source: "places",
      status: fromCache ? "cache_hit" : "success",
      durationMs: nowMs() - started,
    });

    return corsJson({
      prospects,
      fromCache,
      count: typeof result.data.count === "number"
        ? result.data.count
        : prospects.length,
    });
  } catch (e) {
    if (admin) {
      await recordMetric(admin, {
        source: "places",
        status: "failure",
        errorType: classifyError(e),
        durationMs: nowMs() - started,
      });
    }
    return corsJson({ error: String(e) }, { status: 502 });
  }
});
