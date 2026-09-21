// PageSpeed Insights — module partagé (Phase 4).
// Score performance mobile. Best-effort : ne jette jamais.

const PAGESPEED_URL =
  "https://www.googleapis.com/pagespeedonline/v5/runPagespeed";

export const PAGESPEED_MAX_SITES = 20;
export const PAGESPEED_CONCURRENCY = 5;
export const PAGESPEED_CACHE_TTL_DAYS = 30;
export const PAGESPEED_CACHE_MISS_TTL_DAYS = 7;

/** URL canonique pour la clé de cache (host + chemin, sans query). */
export function normalizeUrl(raw: string): string | null {
  try {
    const u = new URL(raw.startsWith("http") ? raw : `https://${raw}`);
    return `${u.hostname}${u.pathname}`.replace(/\/+$/, "").toLowerCase();
  } catch {
    return null;
  }
}

export function pagespeedCacheKey(normalizedUrl: string): string {
  return `pagespeed:${normalizedUrl}`;
}

export { cacheExpiryIso } from "../cache_ttl.ts";

/**
 * Score performance mobile 0-100, ou null si l'audit échoue
 * (site injoignable, timeout…). Best-effort : ne jette jamais.
 */
export async function runPagespeed(
  apiKey: string,
  website: string,
): Promise<number | null> {
  const params = new URLSearchParams({
    url: website,
    strategy: "mobile",
    category: "performance",
    key: apiKey,
  });
  try {
    const res = await fetch(`${PAGESPEED_URL}?${params}`, {
      signal: AbortSignal.timeout(45_000),
    });
    if (!res.ok) {
      console.warn(`PageSpeed ${res.status}`);
      return null;
    }
    const data = await res.json();
    const score = data?.lighthouseResult?.categories?.performance?.score;
    return typeof score === "number" ? Math.round(score * 100) : null;
  } catch (e) {
    console.warn(`PageSpeed erreur: ${e}`);
    return null;
  }
}
