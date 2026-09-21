// ProspectEnrichmentPipeline — moteur partagé (Phase 2).
// Exécute les providers par niveau de dépendance ; best-effort via runProviderSafe.

import type { EnrichmentProvider } from "./provider.ts";
import { runProviderSafe } from "./run_provider.ts";
import type {
  EnrichmentContext,
  ProviderEnrichmentResult,
} from "./types.ts";

export interface PipelineRunOptions {
  /** Timeout par provider (ms). */
  timeoutMs?: number;
}

/**
 * Orchestre les providers : niveaux croissants, parallèle intra-niveau.
 * Un provider failed/skipped n'arrête pas les autres.
 */
export async function runEnrichmentPipeline(
  providers: EnrichmentProvider[],
  ctx: EnrichmentContext,
  opts?: PipelineRunOptions,
): Promise<ProviderEnrichmentResult[]> {
  const byLevel = new Map<number, EnrichmentProvider[]>();
  for (const p of providers) {
    const list = byLevel.get(p.dependencyLevel) ?? [];
    list.push(p);
    byLevel.set(p.dependencyLevel, list);
  }

  const levels = [...byLevel.keys()].sort((a, b) => a - b);
  const all: ProviderEnrichmentResult[] = [];

  for (const level of levels) {
    const batch = byLevel.get(level) ?? [];
    const results = await Promise.all(
      batch.map((p) =>
        runProviderSafe(p, ctx, { timeoutMs: opts?.timeoutMs })
      ),
    );
    all.push(...results);
  }

  return all;
}

/** Raccourci : un seul provider (cas enrich-bodacc). */
export async function runSingleProvider(
  provider: EnrichmentProvider,
  ctx: EnrichmentContext,
  opts?: PipelineRunOptions,
): Promise<ProviderEnrichmentResult> {
  const [result] = await runEnrichmentPipeline([provider], ctx, opts);
  return result;
}
