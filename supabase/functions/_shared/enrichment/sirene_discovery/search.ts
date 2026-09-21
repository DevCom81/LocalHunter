// Discovery SIRENE via Recherche d'entreprises (Phase 9).
// ≠ lookup INSEE nom/ville (enrichissement). Publique, sans clé.

const SEARCH_URL = "https://recherche-entreprises.api.gouv.fr/search";
const GEO_URL = "https://geo.api.gouv.fr/communes";

export interface SireneDiscoveryProspect {
  name: string;
  city: string | null;
  address: string | null;
  category: string | null;
  siren: string;
  siret: string | null;
  naf_code: string | null;
  legal_form: string | null;
  creation_date: string | null;
}

function normalizeCity(raw: string): string {
  return raw
    .toUpperCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^A-Z0-9 ]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

/** Résout le 1er code postal de la commune (geo.api.gouv.fr). */
export async function resolvePostalCode(city: string): Promise<string | null> {
  const params = new URLSearchParams({
    nom: city.trim(),
    fields: "nom,codesPostaux",
    boost: "population",
    limit: "1",
  });
  try {
    const res = await fetch(`${GEO_URL}?${params}`, {
      headers: { Accept: "application/json" },
      signal: AbortSignal.timeout(8_000),
    });
    if (!res.ok) return null;
    const rows = await res.json();
    const cps = rows?.[0]?.codesPostaux as string[] | undefined;
    return cps?.[0] ?? null;
  } catch {
    return null;
  }
}

// deno-lint-ignore no-explicit-any
function mapResult(row: any, cityHint: string): SireneDiscoveryProspect | null {
  const siren = String(row?.siren ?? "").replace(/\D/g, "");
  if (siren.length !== 9) return null;
  const siege = row?.siege ?? {};
  const match = (row?.matching_etablissements as unknown[] | undefined)?.find(
    // deno-lint-ignore no-explicit-any
    (e: any) => e?.etat_administratif === "A",
  ) ?? siege;
  const name = String(
    row?.nom_complet || row?.nom_raison_sociale || "Sans nom",
  ).trim();
  const city = (match?.libelle_commune as string | undefined) ??
    (siege?.libelle_commune as string | undefined) ??
    cityHint;
  return {
    name,
    city,
    address: (match?.adresse as string | undefined) ??
      (siege?.adresse as string | undefined) ??
      null,
    category: (match?.activite_principale as string | undefined) ??
      (row?.activite_principale as string | undefined) ??
      null,
    siren,
    siret: (match?.siret as string | undefined) ??
      (siege?.siret as string | undefined) ??
      null,
    naf_code: (match?.activite_principale as string | undefined) ??
      (row?.activite_principale as string | undefined) ??
      null,
    legal_form: (row?.nature_juridique as string | undefined) ?? null,
    creation_date: (row?.date_creation as string | undefined) ?? null,
  };
}

/**
 * Recherche établissements actifs par mot-clé + code postal ville.
 * [radiusKm] ignoré (API sans rayon) — filtre = commune via CP.
 */
export async function searchSireneDiscovery(opts: {
  city: string;
  sector: string;
  maxResults: number;
}): Promise<SireneDiscoveryProspect[]> {
  const city = opts.city.trim();
  const sector = opts.sector.trim() || "entreprise";
  const max = Math.min(Math.max(opts.maxResults, 1), 50);
  const postal = await resolvePostalCode(city);
  if (!postal) {
    throw new Error(`Ville introuvable pour SIRENE : ${city}`);
  }

  const out: SireneDiscoveryProspect[] = [];
  const seen = new Set<string>();
  const cityNorm = normalizeCity(city);
  let page = 1;
  const perPage = Math.min(max, 25);

  while (out.length < max && page <= 5) {
    const params = new URLSearchParams({
      q: sector,
      code_postal: postal,
      etat_administratif: "A",
      page: String(page),
      per_page: String(perPage),
    });
    const res = await fetch(`${SEARCH_URL}?${params}`, {
      headers: { Accept: "application/json" },
      signal: AbortSignal.timeout(15_000),
    });
    if (!res.ok) {
      throw new Error(`Recherche entreprises ${res.status}`);
    }
    const data = await res.json();
    const results = (data?.results as unknown[]) ?? [];
    if (results.length === 0) break;

    for (const row of results) {
      const mapped = mapResult(row, city);
      if (!mapped) continue;
      if (seen.has(mapped.siren)) continue;
      // Garde les sièges / établissements de la commune ciblée.
      if (
        mapped.city &&
        normalizeCity(mapped.city) !== cityNorm &&
        !normalizeCity(mapped.city).includes(cityNorm)
      ) {
        continue;
      }
      seen.add(mapped.siren);
      out.push(mapped);
      if (out.length >= max) break;
    }

    const totalPages = Number(data?.total_pages ?? 1);
    if (page >= totalPages) break;
    page++;
  }

  return out;
}
