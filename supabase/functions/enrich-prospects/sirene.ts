// Recherche SIRENE (INSEE, nouveau portail) : correspondance d'un
// établissement par nom + ville. Quota public : 30 appels/minute,
// d'où le plafond SIRENE_MAX_LOOKUPS par invocation (le cache partagé
// absorbe les recherches répétées).

const SIRENE_BASE = "https://api.insee.fr/api-sirene/3.11";
const FIELDS = [
  "siren",
  "siret",
  "dateCreationEtablissement",
  "etatAdministratifEtablissement",
  "activitePrincipaleUniteLegale",
  "categorieJuridiqueUniteLegale",
  "denominationUniteLegale",
].join(",");

export const SIRENE_MAX_LOOKUPS = 25;

export interface SireneMatch {
  siren: string | null;
  siret: string | null;
  naf_code: string | null;
  legal_form: string | null;
  creation_date: string | null;
  active: boolean;
}

/** Majuscules sans accents ni ponctuation — format des libellés SIRENE. */
export function normalizeForSirene(raw: string): string {
  return raw
    .toUpperCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^A-Z0-9 ]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

interface SireneEtablissement {
  siren?: string;
  siret?: string;
  dateCreationEtablissement?: string;
  uniteLegale?: {
    activitePrincipaleUniteLegale?: string;
    categorieJuridiqueUniteLegale?: string;
  };
  periodesEtablissement?: Array<{
    dateFin?: string | null;
    etatAdministratifEtablissement?: string;
  }>;
}

function currentState(etab: SireneEtablissement): string | null {
  const current = etab.periodesEtablissement?.find((p) => p.dateFin == null);
  return current?.etatAdministratifEtablissement ?? null;
}

function toMatch(etab: SireneEtablissement): SireneMatch {
  return {
    siren: etab.siren ?? null,
    siret: etab.siret ?? null,
    naf_code: etab.uniteLegale?.activitePrincipaleUniteLegale ?? null,
    legal_form: etab.uniteLegale?.categorieJuridiqueUniteLegale ?? null,
    creation_date: etab.dateCreationEtablissement ?? null,
    // A = actif ; F/C = fermé. Sans période exploitable, on suppose actif.
    active: currentState(etab) !== "F",
  };
}

/**
 * Cherche l'établissement par enseigne ou dénomination dans la commune.
 * Retourne null si aucune correspondance (404 SIRENE) ou en cas d'erreur :
 * l'enrichissement est best-effort et ne doit jamais bloquer la recherche.
 */
export async function lookupSirene(
  apiKey: string,
  name: string,
  city: string,
): Promise<SireneMatch | null> {
  const n = normalizeForSirene(name);
  const c = normalizeForSirene(city);
  if (!n || !c) return null;

  const q =
    `(periode(enseigne1Etablissement:"${n}") ` +
    `OR periode(denominationUsuelleEtablissement:"${n}") ` +
    `OR denominationUniteLegale:"${n}") ` +
    `AND libelleCommuneEtablissement:"${c}"`;
  const url = `${SIRENE_BASE}/siret?q=${encodeURIComponent(q)}` +
    `&nombre=1&champs=${FIELDS}`;

  try {
    const res = await fetch(url, {
      headers: {
        Accept: "application/json",
        "X-INSEE-Api-Key-Integration": apiKey,
      },
      signal: AbortSignal.timeout(15_000),
    });
    if (res.status === 404) return null; // aucun résultat
    if (!res.ok) {
      console.warn(`SIRENE ${res.status} pour "${name}" (${city})`);
      return null;
    }
    const data = await res.json();
    const etabs = (data?.etablissements as SireneEtablissement[]) ?? [];
    return etabs.length > 0 ? toMatch(etabs[0]) : null;
  } catch (e) {
    console.warn(`SIRENE erreur pour "${name}": ${e}`);
    return null;
  }
}
