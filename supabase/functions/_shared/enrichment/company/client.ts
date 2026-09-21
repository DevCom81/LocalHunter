// Dirigeant + finances — API Recherche d'entreprises (Phase company).
// https://recherche-entreprises.api.gouv.fr — publique, sans clé.
// ≠ SIRENE (identité) ≠ BODACC (annonces).
// Best-effort : ne jette jamais.

const SEARCH_URL = "https://recherche-entreprises.api.gouv.fr/search";

export const COMPANY_CACHE_TTL_DAYS = 30;
export const COMPANY_CACHE_MISS_TTL_DAYS = 7;
export const COMPANY_CONCURRENCY = 3;

export interface CompanyInfo {
  manager_name: string | null;
  annual_revenue: number | null;
  annual_revenue_year: number | null;
  net_income: number | null;
  /** Borne basse tranche effectif INSEE ; null = inconnu (≠ 0). */
  employee_count: number | null;
  /** Établissements ouverts si dispo ; null = inconnu. */
  establishment_count: number | null;
}

interface Dirigeant {
  type_dirigeant?: string;
  prenoms?: string;
  nom?: string;
  denomination?: string;
}

interface FinanceYear {
  ca?: number;
  resultat_net?: number;
}

/** Borne basse de la tranche INSEE `tranche_effectif_salarie`. */
export function employeeCountFromTranche(
  code: string | null | undefined,
): number | null {
  if (code == null) return null;
  const c = String(code).trim().toUpperCase();
  if (c === "" || c === "NN") return null;
  const map: Record<string, number> = {
    "00": 0,
    "01": 1,
    "02": 3,
    "03": 6,
    "11": 10,
    "12": 20,
    "21": 50,
    "22": 100,
    "31": 200,
    "32": 250,
    "41": 500,
    "42": 1000,
    "51": 2000,
    "52": 5000,
    "53": 10000,
  };
  return map[c] ?? null;
}

export function companyCacheKey(siren: string): string {
  return `company_v2:${siren}`;
}

export { cacheExpiryIso } from "../cache_ttl.ts";

function managerFrom(dirigeants: Dirigeant[] | undefined): string | null {
  if (!dirigeants || dirigeants.length === 0) return null;
  const physique = dirigeants.find(
    (d) => d.type_dirigeant === "personne physique" && (d.nom || d.prenoms),
  );
  if (physique) {
    return [physique.prenoms, physique.nom].filter(Boolean).join(" ") || null;
  }
  return dirigeants[0].denomination ?? null;
}

function latestFinances(
  finances: Record<string, FinanceYear> | undefined,
): { year: number; ca: number | null; net: number | null } | null {
  if (!finances) return null;
  const years = Object.keys(finances)
    .map(Number)
    .filter(Number.isFinite)
    .sort((a, b) => b - a);
  if (years.length === 0) return null;
  const latest = finances[String(years[0])];
  return {
    year: years[0],
    ca: latest?.ca ?? null,
    net: latest?.resultat_net ?? null,
  };
}

/**
 * Recherche l'unité légale par SIREN. Retourne null si introuvable
 * ou en cas d'erreur — best-effort, ne jette jamais.
 */
export async function lookupCompanyInfo(
  siren: string,
): Promise<CompanyInfo | null> {
  const params = new URLSearchParams({
    q: siren,
    page: "1",
    per_page: "1",
  });
  try {
    const res = await fetch(`${SEARCH_URL}?${params}`, {
      headers: { Accept: "application/json" },
      signal: AbortSignal.timeout(10_000),
    });
    if (!res.ok) {
      console.warn(`Recherche entreprises ${res.status}`);
      return null;
    }
    const data = await res.json();
    const company = data?.results?.[0];
    if (!company || company.siren !== siren) return null;

    const fin = latestFinances(company.finances);
    const openEst = company.nombre_etablissements_ouverts;
    const allEst = company.nombre_etablissements;
    let establishmentCount: number | null = null;
    if (typeof openEst === "number" && Number.isFinite(openEst)) {
      establishmentCount = openEst;
    } else if (typeof allEst === "number" && Number.isFinite(allEst)) {
      establishmentCount = allEst;
    }

    return {
      manager_name: managerFrom(company.dirigeants),
      annual_revenue: fin?.ca ?? null,
      annual_revenue_year: fin ? fin.year : null,
      net_income: fin?.net ?? null,
      employee_count: employeeCountFromTranche(
        company.tranche_effectif_salarie,
      ),
      establishment_count: establishmentCount,
    };
  } catch (e) {
    console.warn(`Recherche entreprises erreur: ${e}`);
    return null;
  }
}
