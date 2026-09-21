// PlacesProvider — EnrichmentProvider niveau 1 (Phase 6).
// Découverte campagne (searchText), pas un enrichissement unitaire SIREN.

import { EnrichmentError } from "../errors.ts";
import type { EnrichmentProvider } from "../provider.ts";
import type {
  EnrichmentContext,
  ProviderEnrichmentResult,
} from "../types.ts";
import {
  buildPlacesQueryPayload,
  buildTextQuery,
  cacheExpiryIso,
  placesCacheKey,
  PLACES_CACHE_TTL_DAYS,
  searchPlacesNewApi,
  type PlaceProspect,
  type PlacesQueryPayload,
} from "./client.ts";

export interface PlacesSearchCacheHit {
  results: PlaceProspect[];
  expiresAt: string;
}

/** Cache user-scoped (`places_search_cache`) injecté par l'adaptateur HTTP. */
export interface PlacesSearchCacheAccess {
  get(cacheKey: string): Promise<PlacesSearchCacheHit | null>;
  upsert(args: {
    cacheKey: string;
    query: PlacesQueryPayload;
    results: PlaceProspect[];
    expiresAt: string;
  }): Promise<void>;
}

export interface PlacesProviderDeps {
  apiKey: string;
  cache: PlacesSearchCacheAccess;
  searchFn?: typeof searchPlacesNewApi;
}

function nowIso(): string {
  return new Date().toISOString();
}

function successResult(
  prospects: PlaceProspect[],
  fromCache: boolean,
  fetchedAt: string,
  query: PlacesQueryPayload,
): ProviderEnrichmentResult {
  return {
    provider: "places",
    status: "success",
    data: {
      prospects,
      fromCache,
      count: prospects.length,
      query,
    },
    // Découverte : pas de signaux unitaires (absence ≠ inventer un signal).
    signals: [],
    confidence: prospects.length > 0 ? 0.9 : 0.4,
    fetchedAt,
    expiresAt: cacheExpiryIso(PLACES_CACHE_TTL_DAYS),
    metadata: {
      cacheStatus: fromCache ? "hit" : "miss",
    },
  };
}

export function createPlacesProvider(
  deps: PlacesProviderDeps,
): EnrichmentProvider {
  const searchFn = deps.searchFn ?? searchPlacesNewApi;

  return {
    name: "places",
    dependencyLevel: 1,

    canRun(ctx: EnrichmentContext): boolean {
      const city = (ctx.knownData.city ?? "").trim();
      return city.length > 0;
    },

    async enrich(ctx: EnrichmentContext): Promise<ProviderEnrichmentResult> {
      const fetchedAt = nowIso();
      const city = (ctx.knownData.city ?? "").trim();
      if (!city) {
        throw new EnrichmentError("skipped", "missing_city", false);
      }

      const sector = (ctx.knownData.sector ?? "restaurant").trim() ||
        "restaurant";
      const query = buildPlacesQueryPayload({
        city,
        sector,
        radiusKm: ctx.knownData.radiusKm ?? undefined,
        maxResults: ctx.knownData.maxResults ?? undefined,
      });
      const key = await placesCacheKey(query);
      const forceRefresh = ctx.options.forceRefresh === true;

      if (!forceRefresh) {
        const cached = await deps.cache.get(key);
        if (cached && new Date(cached.expiresAt) > new Date()) {
          return successResult(cached.results, true, fetchedAt, query);
        }
      }

      try {
        const textQuery = buildTextQuery(sector, city);
        const raw = await searchFn(deps.apiKey, textQuery, query.maxResults);
        const results = raw.map((p) => ({ ...p, city }));
        const expiresAt = cacheExpiryIso(PLACES_CACHE_TTL_DAYS);
        await deps.cache.upsert({
          cacheKey: key,
          query,
          results,
          expiresAt,
        });
        return successResult(results, false, fetchedAt, query);
      } catch (err) {
        const raw = String(err ?? "places_failed");
        throw new EnrichmentError("other", raw.slice(0, 200), true);
      }
    },
  };
}

export function placesCanRunKnownData(known: {
  city?: string | null;
}): boolean {
  return (known.city ?? "").trim().length > 0;
}
