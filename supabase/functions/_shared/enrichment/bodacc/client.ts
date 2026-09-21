// BODACC — config + fetch OpenDataSoft (partagé, Phase 2).
// Endpoint public, sans clé. Aucun secret Supabase requis.

export const BODACC_BASE =
  "https://bodacc-datadila.opendatasoft.com/api/explore/v2.1/catalog/datasets/annonces-commerciales/records";

export const BODACC_MAX_PROSPECTS = 20;
export const BODACC_MAX_RECORDS = 20;
export const BODACC_LOOKBACK_YEARS = 5;
export const BODACC_TIMEOUT_MS = 10_000;
export const BODACC_CONCURRENCY = 3;
export const BODACC_CACHE_TTL_DAYS = 30;
export const BODACC_CACHE_MISS_TTL_DAYS = 7;

export interface BodaccRawRecord {
  id?: string;
  dateparution?: string;
  familleavis?: string;
  familleavis_lib?: string;
  typeavis?: string;
  typeavis_lib?: string;
  commercant?: string;
  registre?: string[] | string | null;
  ville?: string | null;
  url_complete?: string | null;
  radiationaurcs?: unknown;
  jugement?: unknown;
  depot?: unknown;
  modificationsgenerales?: unknown;
  listepersonnes?: unknown;
  parutionavisprecedent?: unknown;
}

export interface BodaccApiResponse {
  total_count?: number;
  results?: BodaccRawRecord[];
}

/** SIREN : 9 chiffres, sans espaces. */
export function normalizeSiren(raw: string): string | null {
  const digits = raw.replace(/\D/g, "");
  return digits.length === 9 ? digits : null;
}

export function cacheKey(siren: string): string {
  return `bodacc_v1:${siren}`;
}

/** Le registre BODACC contient parfois SIREN formaté ; on accepte les deux. */
export function recordMatchesSiren(
  record: BodaccRawRecord,
  siren: string,
): boolean {
  const reg = record.registre;
  if (reg == null) return false;
  const values = Array.isArray(reg) ? reg : [String(reg)];
  return values.some((v) => normalizeSiren(String(v)) === siren);
}

export async function fetchBodaccRecords(
  siren: string,
): Promise<{ records: BodaccRawRecord[]; totalCount: number }> {
  const url = new URL(BODACC_BASE);
  url.searchParams.set("where", `registre='${siren}'`);
  url.searchParams.set("order_by", "dateparution desc");
  url.searchParams.set("limit", String(BODACC_MAX_RECORDS));

  const res = await fetch(url.toString(), {
    method: "GET",
    headers: { Accept: "application/json" },
    signal: AbortSignal.timeout(BODACC_TIMEOUT_MS),
  });
  if (!res.ok) {
    throw new Error(`http_${res.status}`);
  }
  const data = (await res.json()) as BodaccApiResponse;
  const results = Array.isArray(data.results) ? data.results : [];
  return {
    records: results,
    totalCount: typeof data.total_count === "number"
      ? data.total_count
      : results.length,
  };
}

export { cacheExpiryIso } from "../cache_ttl.ts";
