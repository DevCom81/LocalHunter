// Dirigeant et données financières via l'API Recherche d'entreprises
// (https://recherche-entreprises.api.gouv.fr — publique, sans clé).
// Les finances proviennent des bilans déposés à l'INPI : disponibles
// uniquement pour les sociétés qui publient leurs comptes.

const SEARCH_URL = "https://recherche-entreprises.api.gouv.fr/search";

export interface CompanyInfo {
  manager_name: string | null;
  annual_revenue: number | null;
  annual_revenue_year: number | null;
  net_income: number | null;
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
      console.warn(`Recherche entreprises ${res.status} pour ${siren}`);
      return null;
    }
    const data = await res.json();
    const company = data?.results?.[0];
    if (!company || company.siren !== siren) return null;

    const fin = latestFinances(company.finances);
    return {
      manager_name: managerFrom(company.dirigeants),
      annual_revenue: fin?.ca ?? null,
      annual_revenue_year: fin ? fin.year : null,
      net_income: fin?.net ?? null,
    };
  } catch (e) {
    console.warn(`Recherche entreprises erreur pour ${siren}: ${e}`);
    return null;
  }
}
