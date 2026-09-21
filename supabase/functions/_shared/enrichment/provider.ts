// Interface EnrichmentProvider (Phase 1).

import type { EnrichmentContext, ProviderEnrichmentResult } from "./types.ts";

export interface EnrichmentProvider {
  readonly name: string;
  /**
   * Niveau de dépendance :
   * 1 = découverte (places),
   * 2 = identité (sirene),
   * 3 = parallélisables (bodacc, website, pagespeed, company).
   */
  readonly dependencyLevel: number;

  canRun(ctx: EnrichmentContext): boolean;

  enrich(ctx: EnrichmentContext): Promise<ProviderEnrichmentResult>;
}

/** true si le provider est listé dans options.enabledProviders (ou liste absente). */
export function isProviderEnabled(
  ctx: EnrichmentContext,
  name: string,
): boolean {
  const list = ctx.options.enabledProviders;
  if (list == null || list.length === 0) return true;
  return list.includes(name);
}
