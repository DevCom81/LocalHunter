// Contrat JSON de grille générée + validation stricte.
// Le format correspond aux DTO Dart (scoring_grid_dto.dart / criterion_rule.dart).

const KNOWN_FIELDS = [
  "name",
  "city",
  "address",
  "manager_name",
  "email",
  "phone",
  "website",
  "website_exists",
  "facebook_url",
  "instagram_url",
  "linkedin_url",
  "tiktok_url",
  "youtube_url",
  "x_url",
  "facebook_detected",
  "instagram_detected",
  "linkedin_detected",
  "tiktok_detected",
  "youtube_detected",
  "x_detected",
  "social_presence_detected",
  "social_network_count",
  "google_rating",
  "google_reviews",
  "google_business_status",
  "category",
  "siren",
  "siret",
  "naf_code",
  "activity_code",
  "legal_form",
  "pagespeed_score",
  "company_age_years",
  "company_created_recently",
  "annual_revenue",
  "revenue",
  "annual_revenue_year",
  "net_income",
  "employee_count",
  "establishment_count",
  "bodacc_has_creation",
  "bodacc_has_accounts_filing",
  "bodacc_has_modification",
  "bodacc_has_sale",
  "bodacc_has_radiation",
  "bodacc_has_liquidation",
  "bodacc_has_collective_proceeding",
  "bodacc_has_manager_change",
  "bodacc_has_address_change",
];

const RULE_TYPES = ["prospect_field", "boolean", "threshold", "keyword_match"];
const EXCLUSION_TYPES = ["known_chain", "website_pattern", "email_pattern"];

export interface GeneratedGrid {
  name: string;
  description: string;
  criteria: unknown[];
  exclusion_config: { rules: unknown[] };
  recommendation_config: { rules: unknown[] };
}

/** Profil commercial / prospection — injecté dans le prompt grille.
 * Cache clé = hash(offer|target|métier) côté index.ts (Phase 5). */
export interface CommercialProfileInput {
  activity?: string;
  offer?: string;
  target_client_type?: string;
  problem_solved?: string;
  average_basket?: string;
  service_area?: string;
  client_size?: string;
  positive_signals?: string;
  negative_signals?: string;
  exclusion_criteria?: string;
  version?: number;
}

export function buildPrompt(
  business: string,
  productsServices: string,
  profile?: CommercialProfileInput | null,
) {
  const system = `Tu es un expert en prospection commerciale B2B locale.
Tu génères des grilles de scoring pour évaluer des prospects (entreprises locales)
selon leur probabilité de devenir clients d'un professionnel donné.

Tu réponds UNIQUEMENT avec un objet JSON valide, sans texte autour, au format :
{
  "name": "nom court de la grille",
  "description": "1 phrase décrivant la cible idéale",
  "criteria": [
    {
      "key": "cle_snake_case_unique",
      "label": "Libellé français court",
      "kind": "component" | "sub_score",
      "max_points": entier,
      "rule": {
        "type": "prospect_field" | "threshold" | "keyword_match",
        "field": "un champ de la liste autorisée (pour prospect_field/threshold)",
        "match": "mot-clé (pour keyword_match)",
        "threshold": nombre (pour threshold),
        "presence_only": true (pour prospect_field)
      }
    }
  ],
  "exclusion_config": {
    "rules": [
      { "type": "known_chain", "keywords": ["mots du nom à exclure"] },
      { "type": "website_pattern", "patterns": ["fragments d'URL à exclure"] },
      { "type": "email_pattern", "patterns": ["fragments d'email à exclure"] }
    ]
  },
  "recommendation_config": {
    "rules": [
      { "criterion_key": "cle d'un sub_score", "min_stars": nombre }
    ]
  }
}

Les règles de recommandation désignent les prospects pertinents pour l'offre
du professionnel : si un sous-score atteint le seuil, son offre est recommandée.

Contraintes STRICTES :
- 4 à 6 critères "component" dont la somme des max_points fait EXACTEMENT 100.
- Critères "sub_score" : optionnels. Uniquement si l'offre le justifie
  (ex. pagespeed_score pour une offre web). Sinon aucun sub_score.
- "field" doit appartenir STRICTEMENT à : ${KNOWN_FIELDS.join(", ")}.
  N'invente AUCUN autre champ.
- INTERDIT dans key ET label (même avec un field autorisé) :
  budget, croissance, intention d'achat, flotte automobile, "cherche un fournisseur",
  "forte activité", solvabilité, capacité financière. Ces faits ne sont PAS mesurables.
- annual_revenue = chiffre d'affaires PUBLIÉ (bilan), PAS un "budget".
  Libellé autorisé ex. : "CA connu", "CA au-dessus de X".
- company_created_recently / company_age_years / bodacc_has_creation =
  ancienneté ou événement BODACC, PAS "entreprise en croissance".
  Libellés autorisés ex. : "Création récente", "Ancienneté", "Dépôt de comptes BODACC".
- establishment_count = nombre d'établissements connus, PAS une preuve de croissance.
- keyword_match : uniquement mots du nom/catégorie métier (ex. pharmacie), jamais
  des claims non vérifiables (budget, croissance…).
- Les exclusions ciblent les franchises/chaînes nationales et les décisions non locales.
- Si un profil commercial validé est fourni, aligne critères et exclusions dessus
  UNIQUEMENT avec des champs de la liste autorisée et des libellés honnêtes.
- N'introduis PAS de critères site web / PageSpeed / SEO / réseaux sociaux
  sauf si le profil ou l'offre le justifie clairement.
- Réseaux sociaux : utilise social_presence_detected / social_network_count /
  *_detected — détection depuis le site analysé, PAS absence absolue.
- Pour une offre B2B hors web (ex. flottes, labo, industriel) : privilégie
  employee_count, establishment_count, naf_code, annual_revenue, net_income,
  company_age_years, company_created_recently, contact, SIREN/SIRET, BODACC —
  sans prétendre mesurer flotte ou croissance.
- Libellés et description en français.`;

  let user = `Mon métier : ${business}.
${productsServices ? `Mes produits et services : ${productsServices}.` : ""}
`;
  if (profile) {
    user += `
Profil commercial VALIDÉ par l'utilisateur (à respecter) :
- Offre : ${profile.offer ?? ""}
- Client cible : ${profile.target_client_type ?? ""}
- Problème résolu : ${profile.problem_solved ?? ""}
- Panier moyen : ${profile.average_basket ?? ""}
- Zone : ${profile.service_area ?? ""}
- Taille client : ${profile.client_size ?? ""}
- Signaux positifs : ${profile.positive_signals ?? ""}
- Signaux négatifs : ${profile.negative_signals ?? ""}
- Critères éliminatoires : ${profile.exclusion_criteria ?? ""}
`;
  }
  user +=
    `Génère la grille de scoring pour identifier mes meilleurs prospects locaux.`;

  return [
    { role: "system", content: system },
    { role: "user", content: user },
  ];
}

function asString(v: unknown, fallback = ""): string {
  return typeof v === "string" ? v.trim() : fallback;
}

function slugKey(raw: string, index: number): string {
  const slug = raw
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-z0-9]+/g, "_")
    .replace(/^_+|_+$/g, "");
  return slug || `criterion_${index + 1}`;
}

function hasForbiddenClaim(key: string, label: string, match = ""): boolean {
  const hay = `${key} ${label} ${match}`.toLowerCase();
  const patterns = [
    /budget/,
    /croissance/,
    /\bcroit\b/,
    /intention/,
    /flotte/,
    /cherche\s+(un\s+)?fournisseur/,
    /forte\s+activite/,
    /potentiel\s+d.?achat/,
    /solvable/,
    /capacit[eé]\s+(financi|d.?achat|budg)/,
    /marketing\s+d[eé]di/,
  ];
  return patterns.some((re) => re.test(hay));
}

// deno-lint-ignore no-explicit-any
function validateRule(raw: any): Record<string, unknown> | null {
  const type = asString(raw?.type);
  if (!RULE_TYPES.includes(type)) return null;

  if (type === "keyword_match") {
    const match = asString(raw.match);
    if (!match) return null;
    if (hasForbiddenClaim("", "", match)) return null;
    return { type, match };
  }

  const field = asString(raw.field);
  if (!KNOWN_FIELDS.includes(field)) return null;

  if (type === "threshold") {
    const threshold = Number(raw.threshold);
    if (!Number.isFinite(threshold)) return null;
    return { type, field, threshold };
  }
  return { type, field, presence_only: true };
}

// deno-lint-ignore no-explicit-any
function validateCriteria(raw: any[]): unknown[] {
  const seen = new Set<string>();
  const components: Record<string, unknown>[] = [];
  const subScores: Record<string, unknown>[] = [];

  for (const [i, c] of raw.entries()) {
    const kind = asString(c?.kind);
    if (kind !== "component" && kind !== "sub_score") continue;
    const label = asString(c?.label);
    if (!label) continue;
    const rule = validateRule(c?.rule);
    if (!rule) continue;

    let key = slugKey(asString(c?.key) || label, i);
    if (hasForbiddenClaim(key, label)) continue;
    while (seen.has(key)) key = `${key}_2`;
    seen.add(key);

    const maxPoints = kind === "sub_score"
      ? 5
      : Math.max(1, Math.min(100, Math.round(Number(c?.max_points) || 0)));

    const entry = { key, label, kind, max_points: maxPoints, rule };
    (kind === "component" ? components : subScores).push(entry);
  }

  if (components.length < 3) {
    throw new Error("Grille invalide : moins de 3 critères principaux exploitables");
  }

  // Re-normalise la somme des composants à exactement 100 points.
  const total = components.reduce((s, c) => s + (c.max_points as number), 0);
  if (total !== 100) {
    let acc = 0;
    for (const [i, c] of components.entries()) {
      const scaled = i === components.length - 1
        ? 100 - acc
        : Math.max(1, Math.round(((c.max_points as number) / total) * 100));
      c.max_points = scaled;
      acc += scaled;
    }
  }

  return [...components, ...subScores];
}

// deno-lint-ignore no-explicit-any
function validateExclusions(raw: any): { rules: unknown[] } {
  const rules: unknown[] = [];
  for (const r of raw?.rules ?? []) {
    const type = asString(r?.type);
    if (!EXCLUSION_TYPES.includes(type)) continue;
    const keywords = Array.isArray(r?.keywords)
      ? r.keywords.filter((k: unknown) => typeof k === "string" && k.trim())
      : [];
    const patterns = Array.isArray(r?.patterns)
      ? r.patterns.filter((p: unknown) => typeof p === "string" && p.trim())
      : [];
    if (type === "known_chain" && keywords.length > 0) {
      rules.push({ type, keywords });
    } else if (type !== "known_chain" && patterns.length > 0) {
      rules.push({ type, patterns });
    }
  }
  return { rules };
}

// deno-lint-ignore no-explicit-any
function validateRecommendations(raw: any, criteria: unknown[]): { rules: unknown[] } {
  const subScoreKeys = new Set(
    (criteria as Record<string, unknown>[])
      .filter((c) => c.kind === "sub_score")
      .map((c) => c.key as string),
  );
  const rules: unknown[] = [];
  for (const r of raw?.rules ?? []) {
    const criterionKey = asString(r?.criterion_key);
    const minStars = Number(r?.min_stars);
    if (!subScoreKeys.has(criterionKey)) continue;
    if (!Number.isFinite(minStars) || minStars < 0 || minStars > 5) continue;
    rules.push({ criterion_key: criterionKey, min_stars: minStars });
  }
  return { rules };
}

export function validateGrid(raw: unknown): GeneratedGrid {
  if (typeof raw !== "object" || raw === null) {
    throw new Error("Grille invalide : la réponse n'est pas un objet");
  }
  // deno-lint-ignore no-explicit-any
  const obj = raw as any;
  const name = asString(obj.name).slice(0, 80);
  if (!name) throw new Error("Grille invalide : nom manquant");
  if (!Array.isArray(obj.criteria)) {
    throw new Error("Grille invalide : critères manquants");
  }

  const criteria = validateCriteria(obj.criteria);
  return {
    name,
    description: asString(obj.description).slice(0, 300),
    criteria,
    exclusion_config: validateExclusions(obj.exclusion_config),
    recommendation_config: validateRecommendations(obj.recommendation_config, criteria),
  };
}
