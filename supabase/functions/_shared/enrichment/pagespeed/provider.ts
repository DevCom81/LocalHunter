// PageSpeedProvider — EnrichmentProvider niveau 3 (Phase 4).

import type { EnrichmentProvider } from "../provider.ts";
import { shouldEmitSignal } from "../run_provider.ts";
import type {
  EnrichmentContext,
  EnrichmentSignal,
  ProviderEnrichmentResult,
} from "../types.ts";
import {
  cacheExpiryIso,
  normalizeUrl,
  pagespeedCacheKey,
  PAGESPEED_CACHE_MISS_TTL_DAYS,
  PAGESPEED_CACHE_TTL_DAYS,
  runPagespeed,
} from "./client.ts";

export interface PagespeedCachePayload {
  score: number | null;
}

export interface PagespeedCacheAccess {
  get(cacheKey: string): PagespeedCachePayload | null;
  scheduleUpsert(args: {
    cacheKey: string;
    score: number | null;
    fetchedAt: string;
  }): void;
}

export interface PagespeedCallBudget {
  remaining: number;
}

export interface PagespeedProviderDeps {
  apiKey: string;
  cache: PagespeedCacheAccess;
  callBudget: PagespeedCallBudget;
  runFn?: typeof runPagespeed;
}

function nowIso(): string {
  return new Date().toISOString();
}

function toSignals(
  score: number | null,
  fetchedAt: string,
): EnrichmentSignal[] {
  if (!shouldEmitSignal(score)) return [];
  return [{
    key: "pagespeed_score",
    category: "digital_presence",
    value: score,
    source: "pagespeed",
    confidence: 0.8,
    observedAt: fetchedAt,
  }];
}

function successResult(
  score: number | null,
  cacheStatus: "hit" | "miss" | "bypass",
  fetchedAt: string,
): ProviderEnrichmentResult {
  return {
    provider: "pagespeed",
    status: "success",
    data: { pagespeed_score: score, score },
    signals: toSignals(score, fetchedAt),
    confidence: score != null ? 0.8 : 0,
    fetchedAt,
    expiresAt: cacheExpiryIso(
      score != null ? PAGESPEED_CACHE_TTL_DAYS : PAGESPEED_CACHE_MISS_TTL_DAYS,
    ),
    metadata: { cacheStatus },
  };
}

export function createPagespeedProvider(
  deps: PagespeedProviderDeps,
): EnrichmentProvider {
  const runFn = deps.runFn ?? runPagespeed;

  return {
    name: "pagespeed",
    dependencyLevel: 3,

    canRun(ctx: EnrichmentContext): boolean {
      const raw = ctx.knownData.websiteUrl;
      if (raw == null || raw === "") return false;
      return normalizeUrl(raw) != null;
    },

    async enrich(ctx: EnrichmentContext): Promise<ProviderEnrichmentResult> {
      const fetchedAt = nowIso();
      const rawUrl = ctx.knownData.websiteUrl ?? "";
      const normalized = normalizeUrl(rawUrl);
      if (!normalized) {
        return {
          provider: "pagespeed",
          status: "skipped",
          data: {},
          signals: [],
          fetchedAt,
          error: {
            type: "skipped",
            message: "invalid_url",
            retryable: false,
          },
          metadata: { cacheStatus: "none" },
        };
      }

      // Skip si analyse légère a prouvé l'injoignabilité (C3).
      if (ctx.knownData.websiteReachable === false) {
        return {
          provider: "pagespeed",
          status: "skipped",
          data: {},
          signals: [],
          fetchedAt,
          error: {
            type: "unreachable",
            message: "website_unreachable",
            retryable: false,
          },
          metadata: { cacheStatus: "none" },
        };
      }

      const forceRefresh = ctx.options.forceRefresh === true;
      const key = pagespeedCacheKey(normalized);

      if (!forceRefresh) {
        const cached = deps.cache.get(key);
        if (cached != null) {
          return successResult(cached.score, "hit", fetchedAt);
        }
      }

      if (deps.callBudget.remaining <= 0) {
        return {
          provider: "pagespeed",
          status: "skipped",
          data: {},
          signals: [],
          fetchedAt,
          error: {
            type: "cap",
            message: "pagespeed_cap",
            retryable: true,
          },
          metadata: { cacheStatus: "none" },
        };
      }

      deps.callBudget.remaining -= 1;

      let score: number | null = null;
      try {
        score = await runFn(deps.apiKey, rawUrl);
      } catch {
        deps.cache.scheduleUpsert({
          cacheKey: key,
          score: null,
          fetchedAt,
        });
        return {
          provider: "pagespeed",
          status: "failed",
          data: { pagespeed_score: null, score: null },
          signals: [],
          fetchedAt,
          error: {
            type: "other",
            message: "pagespeed_failed",
            retryable: true,
          },
          metadata: {
            cacheStatus: forceRefresh ? "bypass" : "miss",
          },
        };
      }

      deps.cache.scheduleUpsert({
        cacheKey: key,
        score,
        fetchedAt,
      });

      return successResult(
        score,
        forceRefresh ? "bypass" : "miss",
        fetchedAt,
      );
    },
  };
}

export function pagespeedCanRunKnownData(known: {
  websiteUrl?: string | null;
}): boolean {
  const raw = known.websiteUrl;
  if (raw == null || raw === "") return false;
  return normalizeUrl(raw) != null;
}
