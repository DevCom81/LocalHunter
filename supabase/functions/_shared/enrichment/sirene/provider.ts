// SireneProvider — EnrichmentProvider niveau 2 (Phase 3).
// Lookup + cache ; la fusion dans le payload HTTP reste dans enrich-prospects.

import type { EnrichmentProvider } from "../provider.ts";
import { shouldEmitSignal } from "../run_provider.ts";
import type {
  EnrichmentContext,
  EnrichmentSignal,
  ProviderEnrichmentResult,
} from "../types.ts";
import {
  cacheExpiryIso,
  lookupSirene,
  normalizeForSirene,
  SIRENE_CACHE_MISS_TTL_DAYS,
  SIRENE_CACHE_TTL_DAYS,
  sireneCacheKey,
  type SireneMatch,
} from "./client.ts";

export interface SireneCachePayload {
  found: boolean;
  match: SireneMatch | null;
}

/** Accès cache injecté par l'adaptateur HTTP (batch préchargé). */
export interface SireneCacheAccess {
  get(cacheKey: string): SireneCachePayload | null;
  scheduleUpsert(args: {
    cacheKey: string;
    found: boolean;
    match: SireneMatch | null;
    fetchedAt: string;
  }): void;
}

/** Budget d'appels API partagé sur un batch (plafond SIRENE_MAX_LOOKUPS). */
export interface SireneCallBudget {
  remaining: number;
}

export interface SireneProviderDeps {
  apiKey: string;
  cache: SireneCacheAccess;
  callBudget: SireneCallBudget;
  lookupFn?: typeof lookupSirene;
}

function nowIso(): string {
  return new Date().toISOString();
}

function matchConfidence(match: SireneMatch | null): number {
  if (!match) return 0;
  return Math.min(1, Math.max(0, match.match_score / 100));
}

function toEnrichmentSignals(
  match: SireneMatch | null,
  fetchedAt: string,
): EnrichmentSignal[] {
  if (!match) return [];
  const conf = matchConfidence(match);
  const out: EnrichmentSignal[] = [];
  const push = (
    key: string,
    value: string | number | boolean | null,
    category: EnrichmentSignal["category"] = "identity",
  ) => {
    if (!shouldEmitSignal(value)) return;
    out.push({
      key,
      category,
      value,
      source: "sirene",
      confidence: conf,
      observedAt: fetchedAt,
    });
  };

  push("siren", match.siren);
  push("siret", match.siret);
  push("naf_code", match.naf_code);
  push("legal_form", match.legal_form);
  push("creation_date", match.creation_date);
  push("sirene_active", match.active);
  push("sirene_match_score", match.match_score);
  if (match.match_ambiguous) {
    push("sirene_match_ambiguous", true);
  }
  return out;
}

function resultFromMatch(
  match: SireneMatch | null,
  cacheStatus: "hit" | "miss" | "bypass",
  fetchedAt: string,
): ProviderEnrichmentResult {
  const found = match != null;
  return {
    provider: "sirene",
    status: "success",
    data: {
      found,
      match,
      // Champs plats pour assign facile côté HTTP.
      ...(match ?? {}),
    },
    signals: toEnrichmentSignals(match, fetchedAt),
    confidence: matchConfidence(match),
    fetchedAt,
    expiresAt: cacheExpiryIso(
      found ? SIRENE_CACHE_TTL_DAYS : SIRENE_CACHE_MISS_TTL_DAYS,
    ),
    metadata: { cacheStatus },
  };
}

export function createSireneProvider(
  deps: SireneProviderDeps,
): EnrichmentProvider {
  const lookupFn = deps.lookupFn ?? lookupSirene;

  return {
    name: "sirene",
    dependencyLevel: 2,

    canRun(ctx: EnrichmentContext): boolean {
      // Aligné sur le runtime historique : name+city toujours fournis ;
      // lookup gère les chaînes vides (retourne null sans throw).
      return ctx.knownData.name != null && ctx.knownData.city != null;
    },

    async enrich(ctx: EnrichmentContext): Promise<ProviderEnrichmentResult> {
      const name = ctx.knownData.name ?? "";
      const city = ctx.knownData.city ?? "";
      const fetchedAt = nowIso();
      const forceRefresh = ctx.options.forceRefresh === true;
      const key = sireneCacheKey(name, city);

      if (!forceRefresh) {
        const cached = deps.cache.get(key);
        if (cached != null) {
          return resultFromMatch(
            cached.match,
            "hit",
            fetchedAt,
          );
        }
      }

      if (deps.callBudget.remaining <= 0) {
        return {
          provider: "sirene",
          status: "skipped",
          data: {},
          signals: [],
          fetchedAt,
          error: {
            type: "cap",
            message: "sirene_cap",
            retryable: true,
          },
          metadata: { cacheStatus: "none" },
        };
      }

      deps.callBudget.remaining -= 1;

      let match: SireneMatch | null = null;
      try {
        match = await lookupFn(deps.apiKey, name, city);
      } catch {
        // Aligné historique : échec → cache miss + statut failed (métrique apiFail).
        deps.cache.scheduleUpsert({
          cacheKey: key,
          found: false,
          match: null,
          fetchedAt,
        });
        return {
          provider: "sirene",
          status: "failed",
          data: { found: false, match: null },
          signals: [],
          fetchedAt,
          error: {
            type: "other",
            message: "sirene_lookup_failed",
            retryable: true,
          },
          metadata: {
            cacheStatus: forceRefresh ? "bypass" : "miss",
          },
        };
      }

      deps.cache.scheduleUpsert({
        cacheKey: key,
        found: match != null,
        match,
        fetchedAt,
      });

      return resultFromMatch(
        match,
        forceRefresh ? "bypass" : "miss",
        fetchedAt,
      );
    },
  };
}

/** Exposé pour tests / miroir Dart. */
export function sireneCanRunKnownData(known: {
  name?: string | null;
  city?: string | null;
}): boolean {
  return known.name != null && known.city != null;
}

export function normalizeSireneInputs(name: string, city: string): {
  name: string;
  city: string;
} {
  return {
    name: normalizeForSirene(name),
    city: normalizeForSirene(city),
  };
}
