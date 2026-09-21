// BodaccProvider — EnrichmentProvider niveau 3 (Phase 2).
// Fetch + dérivation uniquement ; la persistance reste dans l'adaptateur HTTP.

import { EnrichmentError } from "../errors.ts";
import type { EnrichmentProvider } from "../provider.ts";
import { shouldEmitSignal } from "../run_provider.ts";
import type {
  EnrichmentContext,
  EnrichmentSignal,
  ProviderEnrichmentResult,
  SignalCategory,
} from "../types.ts";
import {
  BODACC_CACHE_MISS_TTL_DAYS,
  BODACC_CACHE_TTL_DAYS,
  cacheExpiryIso,
  cacheKey,
  fetchBodaccRecords,
  normalizeSiren,
  type BodaccRawRecord,
} from "./client.ts";
import {
  deriveSignals,
  signalsToProspectPatch,
  type BodaccSignals,
  type NormalizedBodaccEvent,
  type SignalConfidence,
} from "./signals.ts";

/** Accès cache injecté par l'adaptateur HTTP (batch préchargé). */
export interface BodaccCacheAccess {
  getRecords(siren: string): BodaccRawRecord[] | null;
  scheduleUpsert(args: {
    siren: string;
    records: BodaccRawRecord[];
    totalCount: number;
    fetchedAt: string;
  }): void;
}

export interface BodaccProviderDeps {
  cache: BodaccCacheAccess;
  fetchFn?: typeof fetchBodaccRecords;
}

function confidenceScore(c: SignalConfidence): number {
  if (c === "high") return 0.9;
  if (c === "medium") return 0.6;
  return 0.3;
}

function toEnrichmentSignals(
  signals: BodaccSignals,
  fetchedAt: string,
): EnrichmentSignal[] {
  const out: EnrichmentSignal[] = [];
  const push = (
    key: string,
    category: SignalCategory,
    value: string | number | boolean | null,
  ) => {
    if (!shouldEmitSignal(value)) return;
    // Absence / false : pas de signal « positif » inventé pour les flags.
    if (value === false) return;
    out.push({
      key,
      category,
      value,
      source: "bodacc",
      confidence: confidenceScore(signals.signal_confidence),
      observedAt: fetchedAt,
    });
  };

  push("bodacc_no_results", "activity", signals.no_results ? true : null);
  push("bodacc_has_creation", "activity", signals.has_creation);
  push("bodacc_has_accounts_filing", "activity", signals.has_accounts_filing);
  push("bodacc_has_modification", "activity", signals.has_modification);
  push("bodacc_has_sale", "activity", signals.has_sale);
  push("bodacc_has_radiation", "risk", signals.has_radiation);
  push("bodacc_has_liquidation", "risk", signals.has_liquidation);
  push(
    "bodacc_has_collective_proceeding",
    "risk",
    signals.has_collective_proceeding,
  );
  push("bodacc_has_manager_change", "stability", signals.has_manager_change);
  push("bodacc_has_address_change", "stability", signals.has_address_change);
  if (signals.radiation_status !== "none") {
    push("bodacc_radiation_status", "risk", signals.radiation_status);
  }
  push("bodacc_last_event_at", "activity", signals.last_event_at);

  return out;
}

export function createBodaccProvider(
  deps: BodaccProviderDeps,
): EnrichmentProvider {
  const fetchFn = deps.fetchFn ?? fetchBodaccRecords;

  return {
    name: "bodacc",
    dependencyLevel: 3,

    canRun(ctx: EnrichmentContext): boolean {
      return normalizeSiren(ctx.knownData.siren ?? "") != null;
    },

    async enrich(ctx: EnrichmentContext): Promise<ProviderEnrichmentResult> {
      const siren = normalizeSiren(ctx.knownData.siren ?? "");
      if (!siren) {
        throw new EnrichmentError("skipped", "missing_siren", false);
      }

      const fetchedAt = new Date().toISOString();
      const forceRefresh = ctx.options.forceRefresh === true;
      let records: BodaccRawRecord[] = [];
      let fromCache = false;
      let totalCount = 0;

      if (!forceRefresh) {
        const cached = deps.cache.getRecords(siren);
        if (cached != null) {
          fromCache = true;
          records = cached;
          totalCount = cached.length;
        }
      }

      if (!fromCache) {
        try {
          const fetched = await fetchFn(siren);
          records = fetched.records;
          totalCount = fetched.totalCount;
          deps.cache.scheduleUpsert({
            siren,
            records,
            totalCount,
            fetchedAt,
          });
        } catch (err) {
          const raw = String(err ?? "");
          const httpMatch = raw.match(/http_(\d+)/);
          if (httpMatch) {
            throw new EnrichmentError(
              `http_${httpMatch[1]}`,
              "bodacc_fetch_failed",
              true,
            );
          }
          throw new EnrichmentError("other", "bodacc_fetch_failed", true);
        }
      }

      let signals: BodaccSignals;
      try {
        signals = deriveSignals(
          records,
          siren,
          ctx.knownData.sireneActive,
        );
      } catch {
        throw new EnrichmentError("parse", "bodacc_parse_failed", false);
      }

      const patch = signalsToProspectPatch(signals, fetchedAt);
      const enrichmentSignals = toEnrichmentSignals(signals, fetchedAt);
      const expiresAt = cacheExpiryIso(
        records.length > 0
          ? BODACC_CACHE_TTL_DAYS
          : BODACC_CACHE_MISS_TTL_DAYS,
      );

      return {
        provider: "bodacc",
        status: "success",
        data: {
          siren,
          patch,
          events: signals.events as NormalizedBodaccEvent[],
          events_count: signals.events.length,
          events_in_lookback: signals.events_in_lookback,
          from_cache: fromCache,
          total_count: totalCount,
          no_results: signals.no_results,
        },
        signals: enrichmentSignals,
        confidence: confidenceScore(signals.signal_confidence),
        fetchedAt,
        expiresAt,
        metadata: {
          cacheStatus: fromCache
            ? "hit"
            : forceRefresh
            ? "bypass"
            : "miss",
        },
      };
    },
  };
}

/** Clé cache stable pour un SIREN déjà normalisé. */
export function bodaccCacheKey(siren: string): string {
  return cacheKey(siren);
}
