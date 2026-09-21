// Métriques Edge (C1) — agrégation journalière, labels basse cardinalité.
// Best-effort : un échec d'écriture ne doit jamais faire échouer la requête métier.

export type MetricSource =
  | "places"
  | "sirene"
  | "pagespeed"
  | "company"
  | "grid_gen"
  | "enrichment"
  | "website"
  | "bodacc";

export type MetricStatus = "success" | "failure" | "cache_hit" | "skip";

export interface MetricEvent {
  source: MetricSource;
  status: MetricStatus;
  /** Type d'erreur court (ex. http_502, timeout) — jamais d'URL/SIREN/email. */
  errorType?: string;
  durationMs?: number;
  count?: number;
}

// deno-lint-ignore no-explicit-any
type AdminClient = { rpc: (...args: any[]) => Promise<{ error: unknown }> };

/** Normalise error_type pour limiter la cardinalité. */
export function classifyError(err: unknown): string {
  const msg = String(err ?? "").toLowerCase();
  if (msg.includes("timeout") || msg.includes("abort")) return "timeout";
  if (msg.includes("401") || msg.includes("unauthorized")) return "http_401";
  if (msg.includes("403") || msg.includes("forbidden")) return "http_403";
  if (msg.includes("429")) return "http_429";
  if (msg.includes("404")) return "http_404";
  if (msg.includes("500") || msg.includes("502") || msg.includes("503")) {
    return "http_5xx";
  }
  if (msg.includes("quota")) return "quota";
  return "other";
}

export async function recordMetric(
  admin: AdminClient,
  event: MetricEvent,
): Promise<void> {
  const payload = {
    p_source: event.source,
    p_status: event.status,
    p_error_type: (event.errorType ?? "").slice(0, 64),
    p_duration_ms: Math.max(0, Math.round(event.durationMs ?? 0)),
    p_count: Math.max(1, event.count ?? 1),
  };

  // Log structuré (visible dans les logs Supabase) + table agrégée.
  console.log(JSON.stringify({ metric: true, ...payload }));

  try {
    const { error } = await admin.rpc("increment_edge_metric", payload);
    if (error) console.warn("increment_edge_metric:", error);
  } catch (e) {
    console.warn("recordMetric failed:", e);
  }
}

export function nowMs(): number {
  return Date.now();
}
