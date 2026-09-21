// Contrats communs du pipeline d'enrichissement (Phase 1–7).
// Source de vérité Edge. Ne pas logger knownData (SIREN, URL, etc.) dans les métriques.

export type ProviderStatus = "success" | "partial" | "skipped" | "failed";

export type CacheStatus = "hit" | "miss" | "bypass" | "none";

export type SignalCategory =
  | "identity"
  | "activity"
  | "stability"
  | "digital_presence"
  | "accessibility"
  | "risk";

export interface ProviderError {
  /** Type basse cardinalité : timeout, http_4xx, http_5xx, parse, ssrf, other… */
  type: string;
  /** Message sans PII (pas de SIREN, URL, email, nom). */
  message: string;
  retryable: boolean;
}

export interface EnrichmentSignal {
  key: string;
  category: SignalCategory;
  value: string | number | boolean | null;
  /** Nom du provider source. */
  source: string;
  /** Confiance 0–1. */
  confidence: number;
  observedAt?: string;
  /** Métadonnées non sensibles uniquement. */
  metadata?: Record<string, unknown>;
}

export interface EnrichmentKnownData {
  placeId?: string | null;
  siren?: string | null;
  siret?: string | null;
  websiteUrl?: string | null;
  /** false = SIRENE indique fermé / inactif (utilisé par BODACC radiation). */
  sireneActive?: boolean | null;
  /** Nom commercial / enseigne (lookup SIRENE). */
  name?: string | null;
  /** Ville de recherche (lookup SIRENE). */
  city?: string | null;
  /**
   * Résultat analyse site légère (C3).
   * false → PageSpeed skip (site injoignable).
   */
  websiteReachable?: boolean | null;
  /** Secteur Places (ex. restaurant). */
  sector?: string | null;
  /** Rayon km (clé de cache Places ; non envoyé à l'API aujourd'hui). */
  radiusKm?: number | null;
  /** Plafond résultats Places (clampé côté provider). */
  maxResults?: number | null;
}

export interface EnrichmentOptions {
  forceRefresh?: boolean;
  enabledProviders?: string[];
}

/**
 * Contexte d'enrichissement d'un prospect.
 * userId volontairement absent : l'auth reste au niveau HTTP Edge.
 * Ne jamais exposer knownData dans les labels de métriques.
 */
export interface EnrichmentContext {
  prospectId: string;
  campaignId?: string;
  knownData: EnrichmentKnownData;
  options: EnrichmentOptions;
}

export interface ProviderEnrichmentResult {
  provider: string;
  status: ProviderStatus;
  data: Record<string, unknown>;
  signals: EnrichmentSignal[];
  confidence?: number;
  fetchedAt: string;
  expiresAt?: string;
  error?: ProviderError;
  metadata?: {
    durationMs?: number;
    cacheStatus?: CacheStatus;
  };
}

/**
 * Finances / company (doc Phase 1 — provider non créé ici) :
 * source actuelle = enrich-prospects/finances.ts
 * (recherche-entreprises.api.gouv.fr : dirigeant, CA, résultat net).
 * Distinct de SIRENE (identité légale) et BODACC (annonces).
 */
export const PROVIDER_NAMES = [
  "places",
  "sirene",
  "company",
  "bodacc",
  "website",
  "pagespeed",
] as const;

export type ProviderName = (typeof PROVIDER_NAMES)[number];
