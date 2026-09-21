/// Libellés français déterministes pour l'explicabilité du score (Phase 3).
class ScoreExplanationLabels {
  ScoreExplanationLabels._();

  static const fieldLabels = <String, String>{
    'address': 'Adresse',
    'phone': 'Téléphone',
    'website': 'Site web',
    'siret': 'SIRET',
    'manager_name': 'Dirigeant',
    'annual_revenue': 'Chiffre d\'affaires',
    'pagespeed_score': 'Score PageSpeed',
    'creation_date': 'Date de création',
  };

  static const sourceLabels = <String, String>{
    'legacy': 'Scorer intégré',
    'prospect_field': 'Champ prospect',
    'boolean': 'Condition',
    'threshold': 'Seuil numérique',
    'keyword_match': 'Mot-clé',
    'pagespeed': 'PageSpeed / site web',
  };

  /// Textes FR pour les clés d'explication connues ; sinon fallback générique.
  static String explanation({
    required String explanationKey,
    required String criterionLabel,
    required num value,
    required int maxPoints,
  }) {
    final known = _known[explanationKey];
    if (known != null) return known;

    if (explanationKey.endsWith('_zero')) {
      return '$criterionLabel : aucun point (0 / $maxPoints).';
    }
    if (explanationKey.endsWith('_max')) {
      return '$criterionLabel : score maximal ($value / $maxPoints).';
    }
    return '$criterionLabel : $value / $maxPoints pts.';
  }

  static String source(String sourceKey) =>
      sourceLabels[sourceKey] ?? sourceKey;

  static String field(String fieldKey) =>
      fieldLabels[fieldKey] ?? fieldKey;

  static const _known = <String, String>{
    'accessibility_zero':
        'Décisionnaire difficile à joindre (pas de téléphone, e-mail ou nom).',
    'accessibility_partial':
        'Coordonnées partiellement renseignées : accessibilité moyenne.',
    'accessibility_max':
        'Décisionnaire accessible (téléphone, e-mail et dirigeant).',
    'website_opportunity_zero':
        'Site web déjà solide : faible opportunité de refonte.',
    'website_opportunity_partial':
        'Opportunité site significative (absent, lent ou perfectible).',
    'website_opportunity_max':
        'Opportunité site maximale.',
    'software_opportunity_zero':
        'Catégorie peu adaptée à une offre logiciel métier.',
    'software_opportunity_partial':
        'Catégorie identifiée : opportunité logiciel modérée.',
    'software_opportunity_max':
        'Catégorie à fort potentiel logiciel (ex. restauration).',
    'commercial_health_zero':
        'Signaux commerciaux absents ou très faibles.',
    'commercial_health_partial':
        'Santé commerciale correcte (avis / présence sociale).',
    'commercial_health_max':
        'Bonne santé commerciale (note et volume d\'avis élevés).',
  };
}
