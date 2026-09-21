// Exécution isolée d'un provider (Phase 1).
// Jamais de throw métier vers l'appelant : skipped / failed encapsulés.

import { classifyThrown } from "./errors.ts";
import {
  isProviderEnabled,
  type EnrichmentProvider,
} from "./provider.ts";
import type {
  EnrichmentContext,
  ProviderEnrichmentResult,
} from "./types.ts";

function nowIso(): string {
  return new Date().toISOString();
}

function skippedResult(
  provider: string,
  reason: string,
): ProviderEnrichmentResult {
  return {
    provider,
    status: "skipped",
    data: {},
    signals: [],
    fetchedAt: nowIso(),
    error: {
      type: "skipped",
      message: reason,
      retryable: false,
    },
    metadata: { cacheStatus: "none" },
  };
}

/**
 * Exécute un provider de façon sûre.
 * - canRun false ou désactivé → skipped
 * - timeoutMs → Abort via Promise.race
 * - throw → failed (classifié)
 */
export async function runProviderSafe(
  provider: EnrichmentProvider,
  ctx: EnrichmentContext,
  opts?: { timeoutMs?: number },
): Promise<ProviderEnrichmentResult> {
  const started = Date.now();

  if (!isProviderEnabled(ctx, provider.name)) {
    return skippedResult(provider.name, "provider_disabled");
  }
  if (!provider.canRun(ctx)) {
    return skippedResult(provider.name, "can_run_false");
  }

  try {
    const enrichPromise = provider.enrich(ctx);
    const result = opts?.timeoutMs != null && opts.timeoutMs > 0
      ? await Promise.race([
        enrichPromise,
        new Promise<never>((_, reject) => {
          setTimeout(
            () => reject(new Error("timeout")),
            opts.timeoutMs,
          );
        }),
      ])
      : await enrichPromise;

    const durationMs = Date.now() - started;
    return {
      ...result,
      provider: result.provider || provider.name,
      metadata: {
        cacheStatus: result.metadata?.cacheStatus ?? "none",
        durationMs: result.metadata?.durationMs ?? durationMs,
      },
    };
  } catch (err) {
    const error = classifyThrown(err);
    return {
      provider: provider.name,
      status: "failed",
      data: {},
      signals: [],
      fetchedAt: nowIso(),
      error,
      metadata: {
        durationMs: Date.now() - started,
        cacheStatus: "none",
      },
    };
  }
}

/**
 * Règle produit : ne pas créer un signal « positif » à partir d'une absence.
 * value === null / undefined → ne pas pousser de signal positif.
 */
export function shouldEmitSignal(value: unknown): boolean {
  return value !== null && value !== undefined;
}
