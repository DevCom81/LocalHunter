// Recherche SIRENE (INSEE) — module partagé (Phase 3).
// Correspondance établissement par nom + ville, score de rapprochement (B3).
// Quota public : 30 appels/minute → plafond SIRENE_MAX_LOOKUPS.

const SIRENE_BASE = "https://api.insee.fr/api-sirene/3.11";
const FIELDS = [
  "siren",
  "siret",
  "dateCreationEtablissement",
  "etatAdministratifEtablissement",
  "activitePrincipaleUniteLegale",
  "categorieJuridiqueUniteLegale",
  "denominationUniteLegale",
  "enseigne1Etablissement",
  "denominationUsuelleEtablissement",
].join(",");

/** Nombre de candidats récupérés pour ranking (au lieu de nombre=1). */
const CANDIDATE_LIMIT = 5;

/** Score minimum pour accepter un rapprochement. */
export const SIRENE_MIN_SCORE = 50;

/** Écart max entre 1er et 2e pour signaler une ambiguïté. */
const AMBIGUITY_GAP = 12;

export const SIRENE_MAX_LOOKUPS = 25;

export const SIRENE_CACHE_TTL_DAYS = 30;
export const SIRENE_CACHE_MISS_TTL_DAYS = 7;

export interface SireneMatch {
  siren: string | null;
  siret: string | null;
  naf_code: string | null;
  legal_form: string | null;
  creation_date: string | null;
  active: boolean;
  /** 0–100 : qualité du rapprochement nom/ville. */
  match_score: number;
  /** true si un second candidat est proche du premier. */
  match_ambiguous: boolean;
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

export function sireneCacheKey(name: string, city: string): string {
  return `sirene_v2:${normalizeForSirene(name)}|${normalizeForSirene(city)}`;
}

export { cacheExpiryIso } from "../cache_ttl.ts";

interface SireneEtablissement {
  siren?: string;
  siret?: string;
  dateCreationEtablissement?: string;
  uniteLegale?: {
    activitePrincipaleUniteLegale?: string;
    categorieJuridiqueUniteLegale?: string;
    denominationUniteLegale?: string;
  };
  periodesEtablissement?: Array<{
    dateFin?: string | null;
    etatAdministratifEtablissement?: string;
    enseigne1Etablissement?: string;
    denominationUsuelleEtablissement?: string;
  }>;
}

function currentPeriod(etab: SireneEtablissement) {
  return etab.periodesEtablissement?.find((p) => p.dateFin == null) ??
    etab.periodesEtablissement?.[0];
}

function currentState(etab: SireneEtablissement): string | null {
  return currentPeriod(etab)?.etatAdministratifEtablissement ?? null;
}

function candidateLabels(etab: SireneEtablissement): string[] {
  const period = currentPeriod(etab);
  const raw = [
    etab.uniteLegale?.denominationUniteLegale,
    period?.enseigne1Etablissement,
    period?.denominationUsuelleEtablissement,
  ];
  return raw
    .filter((x): x is string => Boolean(x && x.trim()))
    .map(normalizeForSirene);
}

/** Similarité tokenielle + bonus exact/inclusion (exportée pour tests manuels). */
export function nameSimilarity(query: string, candidate: string): number {
  if (!query || !candidate) return 0;
  if (query === candidate) return 100;
  if (candidate.includes(query) || query.includes(candidate)) {
    const ratio = Math.min(query.length, candidate.length) /
      Math.max(query.length, candidate.length);
    return Math.round(70 + ratio * 25);
  }
  const qTokens = new Set(query.split(" ").filter((t) => t.length > 1));
  const cTokens = new Set(candidate.split(" ").filter((t) => t.length > 1));
  if (qTokens.size === 0 || cTokens.size === 0) return 0;
  let inter = 0;
  for (const t of qTokens) if (cTokens.has(t)) inter++;
  const union = qTokens.size + cTokens.size - inter;
  return Math.round((inter / union) * 100);
}

export function scoreEtablissement(
  queryName: string,
  etab: SireneEtablissement,
): number {
  const labels = candidateLabels(etab);
  if (labels.length === 0) return 0;
  let best = 0;
  for (const label of labels) {
    best = Math.max(best, nameSimilarity(queryName, label));
  }
  // Préférence légère pour les établissements actifs (A), sans exclure les fermés.
  if (currentState(etab) === "F") best = Math.round(best * 0.85);
  return best;
}

function toMatch(
  etab: SireneEtablissement,
  matchScore: number,
  ambiguous: boolean,
): SireneMatch {
  return {
    siren: etab.siren ?? null,
    siret: etab.siret ?? null,
    naf_code: etab.uniteLegale?.activitePrincipaleUniteLegale ?? null,
    legal_form: etab.uniteLegale?.categorieJuridiqueUniteLegale ?? null,
    creation_date: etab.dateCreationEtablissement ?? null,
    active: currentState(etab) !== "F",
    match_score: matchScore,
    match_ambiguous: ambiguous,
  };
}

/**
 * Cherche l'établissement par enseigne ou dénomination dans la commune,
 * classe jusqu'à 5 candidats, refuse les scores < SIRENE_MIN_SCORE.
 * Best-effort : erreurs → null (pas de throw).
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
    `&nombre=${CANDIDATE_LIMIT}&champs=${FIELDS}`;

  try {
    const res = await fetch(url, {
      headers: {
        Accept: "application/json",
        "X-INSEE-Api-Key-Integration": apiKey,
      },
      signal: AbortSignal.timeout(15_000),
    });
    if (res.status === 404) return null;
    if (!res.ok) {
      console.warn(`SIRENE ${res.status}`);
      return null;
    }
    const data = await res.json();
    const etabs = (data?.etablissements as SireneEtablissement[]) ?? [];
    if (etabs.length === 0) return null;

    const ranked = etabs
      .map((etab) => ({ etab, score: scoreEtablissement(n, etab) }))
      .sort((a, b) => b.score - a.score);

    const top = ranked[0];
    if (top.score < SIRENE_MIN_SCORE) return null;

    const second = ranked[1];
    const ambiguous = Boolean(
      second &&
        second.score >= SIRENE_MIN_SCORE &&
        top.score - second.score <= AMBIGUITY_GAP,
    );

    return toMatch(top.etab, top.score, ambiguous);
  } catch (e) {
    console.warn(`SIRENE erreur: ${e}`);
    return null;
  }
}
