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
  "facebook_url",
  "instagram_url",
  "google_rating",
  "google_reviews",
  "category",
  "siren",
  "naf_code",
  "legal_form",
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

export function buildPrompt(business: string, productsServices: string) {
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
- 3 à 6 critères "sub_score" avec max_points = 5 (notation en étoiles).
- "field" doit appartenir à : ${KNOWN_FIELDS.join(", ")}.
- Les exclusions ciblent les franchises/chaînes nationales et les décisions non locales.
- Libellés et description en français.`;

  const user = `Mon métier : ${business}.
${productsServices ? `Mes produits et services : ${productsServices}.` : ""}
Génère la grille de scoring pour identifier mes meilleurs prospects locaux.`;

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

// deno-lint-ignore no-explicit-any
function validateRule(raw: any): Record<string, unknown> | null {
  const type = asString(raw?.type);
  if (!RULE_TYPES.includes(type)) return null;

  if (type === "keyword_match") {
    const match = asString(raw.match);
    if (!match) return null;
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
