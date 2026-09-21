// Barrel public du pipeline d'enrichissement (Phase 7).
// Les endpoints HTTP importent les sous-modules `*/mod.ts` ou ce barrel.

export type {
  CacheStatus,
  EnrichmentContext,
  EnrichmentKnownData,
  EnrichmentOptions,
  EnrichmentSignal,
  ProviderEnrichmentResult,
  ProviderError,
  ProviderName,
  ProviderStatus,
  SignalCategory,
} from "./types.ts";
export { PROVIDER_NAMES } from "./types.ts";

export type { EnrichmentProvider } from "./provider.ts";
export { isProviderEnabled } from "./provider.ts";

export { EnrichmentError, classifyThrown, sanitizeErrorMessage } from "./errors.ts";
export { runProviderSafe, shouldEmitSignal } from "./run_provider.ts";
export {
  runEnrichmentPipeline,
  runSingleProvider,
} from "./pipeline.ts";
export { runWithConcurrency } from "./concurrency.ts";
export { cacheExpiryIso } from "./cache_ttl.ts";

export {
  createBodaccProvider,
  persistBodaccResult,
} from "./bodacc/mod.ts";
export { createSireneProvider } from "./sirene/mod.ts";
export { createCompanyProvider } from "./company/mod.ts";
export { createPagespeedProvider } from "./pagespeed/mod.ts";
export { createWebsiteProvider } from "./website/mod.ts";
export { createPlacesProvider } from "./places/mod.ts";
