// Score de performance mobile via PageSpeed Insights (même clé Google
// que Places). Un audit prend 10 à 25 s : les appels sont parallélisés
// par petits lots et plafonnés à PAGESPEED_MAX_SITES par invocation.

const PAGESPEED_URL =
  "https://www.googleapis.com/pagespeedonline/v5/runPagespeed";

export const PAGESPEED_MAX_SITES = 20;
export const PAGESPEED_CONCURRENCY = 5;

/** URL canonique pour la clé de cache (host + chemin, sans query). */
export function normalizeUrl(raw: string): string | null {
  try {
    const u = new URL(raw.startsWith("http") ? raw : `https://${raw}`);
    return `${u.hostname}${u.pathname}`.replace(/\/+$/, "").toLowerCase();
  } catch {
    return null;
  }
}

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
      console.warn(`PageSpeed ${res.status} pour ${website}`);
      return null;
    }
    const data = await res.json();
    const score = data?.lighthouseResult?.categories?.performance?.score;
    return typeof score === "number" ? Math.round(score * 100) : null;
  } catch (e) {
    console.warn(`PageSpeed erreur pour ${website}: ${e}`);
    return null;
  }
}

/** Exécute `tasks` avec au plus `limit` promesses simultanées. */
export async function runWithConcurrency<T>(
  tasks: Array<() => Promise<T>>,
  limit: number,
): Promise<T[]> {
  const results: T[] = new Array(tasks.length);
  let next = 0;
  const workers = Array.from(
    { length: Math.min(limit, tasks.length) },
    async () => {
      while (next < tasks.length) {
        const i = next++;
        results[i] = await tasks[i]();
      }
    },
  );
  await Promise.all(workers);
  return results;
}
