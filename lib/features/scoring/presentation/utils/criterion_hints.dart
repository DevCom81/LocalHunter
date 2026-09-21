const criterionHints = <String, String>{
  'accessibility':
      'Poids du composant « décisionnaire accessible » (max 30 pts bruts).',
  'website_opportunity':
      'Poids de l\'opportunité site web (qualité, refonte, absence de site).',
  'software_opportunity':
      'Poids de l\'opportunité logiciel métier (ERP, caisse, gestion).',
  'commercial_health':
      'Poids de la santé commerciale (avis, activité, signaux faibles).',
  'site_score':
      'Sous-score Site (étoiles 0–5) — multiplicateur appliqué aux étoiles brutes.',
  'software_score':
      'Sous-score Software — multiplicateur sur les étoiles logiciel.',
  'easy_rest_score':
      'Sous-score restauration / CHR (legacy) — bars, restos, snacks.',
  'accessibility_stars':
      'Sous-score accessibilité du décisionnaire (étoiles).',
  'digital_maturity':
      'Maturité digitale élevée → exclusion automatique si ≥ 4 étoiles.',
  'false_positive_risk':
      'Risque de faux positif (franchise, chaîne, site performant).',
};

String hintForCriterion(String key) =>
    criterionHints[key] ?? 'Critère de scoring configurable.';
