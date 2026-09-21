// CompanyProvider — EnrichmentProvider niveau 3 (finances / dirigeant).
// Distinct de SIRENE (identité) et BODACC (annonces).

import type { EnrichmentProvider } from "../provider.ts";
import { shouldEmitSignal } from "../run_provider.ts";
import type {
  EnrichmentContext,
  EnrichmentSignal,
  ProviderEnrichmentResult,
} from "../types.ts";
import {
  cacheExpiryIso,
  COMPANY_CACHE_MISS_TTL_DAYS,
  COMPANY_CACHE_TTL_DAYS,
  companyCacheKey,
  lookupCompanyInfo,
  type CompanyInfo,
} from "./client.ts";

export interface CompanyCachePayload {
  found: boolean;
  info: CompanyInfo | null;
}

export interface CompanyCacheAccess {
  get(cacheKey: string): CompanyCachePayload | null;
  scheduleUpsert(args: {
    cacheKey: string;
    found: boolean;
    info: CompanyInfo | null;
    fetchedAt: string;
  }): void;
}

export interface CompanyProviderDeps {
  cache: CompanyCacheAccess;
  lookupFn?: typeof lookupCompanyInfo;
}

function nowIso(): string {
  return new Date().toISOString();
}

function toSignals(
  info: CompanyInfo | null,
  fetchedAt: string,
): EnrichmentSignal[] {
  if (!info) return [];
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
      source: "company",
      confidence: 0.75,
      observedAt: fetchedAt,
    });
  };

  push("manager_name", info.manager_name);
  push("annual_revenue", info.annual_revenue, "activity");
  push("annual_revenue_year", info.annual_revenue_year, "activity");
  push("net_income", info.net_income, "activity");
  push("employee_count", info.employee_count, "activity");
  push("establishment_count", info.establishment_count, "activity");
  return out;
}

function successResult(
  info: CompanyInfo | null,
  cacheStatus: "hit" | "miss" | "bypass",
  fetchedAt: string,
): ProviderEnrichmentResult {
  const found = info != null;
  return {
    provider: "company",
    status: "success",
    data: {
      found,
      info,
      ...(info ?? {}),
      manager_name: info?.manager_name ?? null,
      annual_revenue: info?.annual_revenue ?? null,
      annual_revenue_year: info?.annual_revenue_year ?? null,
      net_income: info?.net_income ?? null,
      employee_count: info?.employee_count ?? null,
      establishment_count: info?.establishment_count ?? null,
    },
    signals: toSignals(info, fetchedAt),
    confidence: found ? 0.75 : 0,
    fetchedAt,
    expiresAt: cacheExpiryIso(
      found ? COMPANY_CACHE_TTL_DAYS : COMPANY_CACHE_MISS_TTL_DAYS,
    ),
    metadata: { cacheStatus },
  };
}

export function createCompanyProvider(
  deps: CompanyProviderDeps,
): EnrichmentProvider {
  const lookupFn = deps.lookupFn ?? lookupCompanyInfo;

  return {
    name: "company",
    dependencyLevel: 3,

    canRun(ctx: EnrichmentContext): boolean {
      const siren = (ctx.knownData.siren ?? "").replace(/\D/g, "");
      return siren.length === 9;
    },

    async enrich(ctx: EnrichmentContext): Promise<ProviderEnrichmentResult> {
      const fetchedAt = nowIso();
      const siren = (ctx.knownData.siren ?? "").replace(/\D/g, "");
      if (siren.length !== 9) {
        return {
          provider: "company",
          status: "skipped",
          data: {},
          signals: [],
          fetchedAt,
          error: {
            type: "skipped",
            message: "missing_siren",
            retryable: false,
          },
          metadata: { cacheStatus: "none" },
        };
      }

      const forceRefresh = ctx.options.forceRefresh === true;
      const key = companyCacheKey(siren);

      if (!forceRefresh) {
        const cached = deps.cache.get(key);
        if (cached != null) {
          return successResult(cached.info, "hit", fetchedAt);
        }
      }

      let info: CompanyInfo | null = null;
      try {
        info = await lookupFn(siren);
      } catch {
        deps.cache.scheduleUpsert({
          cacheKey: key,
          found: false,
          info: null,
          fetchedAt,
        });
        return {
          provider: "company",
          status: "failed",
          data: { found: false, info: null },
          signals: [],
          fetchedAt,
          error: {
            type: "other",
            message: "company_lookup_failed",
            retryable: true,
          },
          metadata: {
            cacheStatus: forceRefresh ? "bypass" : "miss",
          },
        };
      }

      deps.cache.scheduleUpsert({
        cacheKey: key,
        found: info != null,
        info,
        fetchedAt,
      });

      return successResult(
        info,
        forceRefresh ? "bypass" : "miss",
        fetchedAt,
      );
    },
  };
}

export function companyCanRunKnownData(known: {
  siren?: string | null;
}): boolean {
  const siren = (known.siren ?? "").replace(/\D/g, "");
  return siren.length === 9;
}
