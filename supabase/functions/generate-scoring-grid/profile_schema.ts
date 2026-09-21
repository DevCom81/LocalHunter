// Profil de prospection (Phase 5) — étape avant génération de grille.
// JSON lisible par l'utilisateur ; pas de critères techniques ici.
// Signaux = observables LocalHunter uniquement (Phase 11).

export interface ProspectingProfile {
  offer: string;
  target_summary: string;
  signals: string[];
  exclusions: string[];
  geography_hint?: string;
  client_size_hint?: string;
}

const FORBIDDEN_CLAIM = [
  /budget/i,
  /croissance/i,
  /\bcroit\b/i,
  /intention/i,
  /flotte/i,
  /cherche\s+(un\s+)?fournisseur/i,
  /forte\s+activit/i,
  /potentiel\s+d.?achat/i,
  /solvable/i,
  /capacit[eé]\s+(financi|d.?achat|budg)/i,
  /marketing\s+d[eé]di/i,
];

function hasForbiddenClaim(text: string): boolean {
  return FORBIDDEN_CLAIM.some((re) => re.test(text));
}

export function buildProfilePrompt(
  business: string,
  productsServices: string,
) {
  const system = `Tu es un expert en prospection B2B en France.
Tu aides un professionnel à clarifier QUI il doit prospecter, sans inventer
de grille de scoring technique.

Tu réponds UNIQUEMENT avec un objet JSON valide :
{
  "offer": "ce que vend l'utilisateur (1 phrase)",
  "target_summary": "cible idéale en langage commercial (2-4 phrases max)",
  "signals": ["signaux qui rendent une entreprise intéressante", "..."],
  "exclusions": ["profils à exclure", "..."],
  "geography_hint": "zone si mentionnée, sinon chaîne vide",
  "client_size_hint": "taille d'entreprise si pertinente, sinon chaîne vide"
}

Règles STRICTES :
- Français uniquement.
- 3 à 6 signaux, 1 à 5 exclusions.
- Chaque SIGNAL doit être observables via des données LocalHunter FR :
  activité/NAF, effectif, nb établissements, CA publié, ancienneté / création récente,
  contact (tél, email), SIREN/SIRET, événements BODACC (cession, dépôt de comptes…),
  note/avis Google, site web / PageSpeed / réseaux détectés sur le site
  UNIQUEMENT si l'offre le justifie (web, SEO, social…).
- INTERDIT dans signaux, exclusions ET target_summary :
  budget (marketing ou autre), croissance, intention d'achat, flotte automobile,
  "cherche un fournisseur", solvabilité, capacité financière non publiée.
  Ces faits ne sont PAS récupérables en ligne par LocalHunter.
- Ne dis PAS "entreprise en croissance" : tu peux dire "création récente",
  "plusieurs établissements", "dépôt de comptes récent" — faits mesurables.
- Ne propose PAS PageSpeed, SEO, qualité de site, réseaux sociaux
  SAUF si l'offre le justifie clairement (agence web, refonte, SEO…).
- N'affirme jamais de faits non vérifiables sur des entreprises précises.`;

  const user = `Mon métier : ${business}.
${productsServices ? `Ce que je propose : ${productsServices}.` : ""}
Propose mon profil de prospection (cible + signaux mesurables + exclusions).`;

  return [
    { role: "system", content: system },
    { role: "user", content: user },
  ];
}

function asString(v: unknown, fallback = ""): string {
  return typeof v === "string" ? v.trim() : fallback;
}

function asStringList(v: unknown, min: number, max: number): string[] | null {
  if (!Array.isArray(v)) return null;
  const items = v
    .map((x) => asString(x))
    .filter((s) => s.length > 0 && !hasForbiddenClaim(s))
    .slice(0, max);
  if (items.length < min) return null;
  return items;
}

export function validateProspectingProfile(
  raw: unknown,
): ProspectingProfile | null {
  if (!raw || typeof raw !== "object") return null;
  const o = raw as Record<string, unknown>;
  const offer = asString(o.offer);
  const target = asString(o.target_summary);
  const signals = asStringList(o.signals, 3, 6);
  const exclusions = asStringList(o.exclusions, 1, 5);
  if (!offer || offer.length < 3 || !target || target.length < 10) return null;
  if (!signals || !exclusions) return null;
  return {
    offer: offer.slice(0, 240),
    target_summary: target.slice(0, 800),
    signals,
    exclusions,
    geography_hint: asString(o.geography_hint).slice(0, 120),
    client_size_hint: asString(o.client_size_hint).slice(0, 120),
  };
}

/** Convertit un profil validé en entrée compatible buildPrompt (grille). */
export function prospectingToCommercialInput(
  p: ProspectingProfile,
): {
  offer: string;
  target_client_type: string;
  positive_signals: string;
  exclusion_criteria: string;
  service_area: string;
  client_size: string;
} {
  return {
    offer: p.offer,
    target_client_type: p.target_summary,
    positive_signals: p.signals.join(" ; "),
    exclusion_criteria: p.exclusions.join(" ; "),
    service_area: p.geography_hint ?? "",
    client_size: p.client_size_hint ?? "",
  };
}
