/// Source de vérité des critères réellement mesurables (Phase 11).
///
/// L'IA ne peut proposer que ces champs / règles. Les grilles utilisateur
/// déjà en base restent scorées telles quelles (y compris legacy).
abstract final class MeasurableCriteriaCatalog {
  /// Champs alimentés par Places, SIRENE, company, website, PageSpeed, BODACC, social.
  static const measurableFields = <String>{
    'name',
    'city',
    'address',
    'manager_name',
    'email',
    'phone',
    'website',
    'website_exists',
    'facebook_url',
    'instagram_url',
    'linkedin_url',
    'tiktok_url',
    'youtube_url',
    'x_url',
    'facebook_detected',
    'instagram_detected',
    'linkedin_detected',
    'tiktok_detected',
    'youtube_detected',
    'x_detected',
    'social_presence_detected',
    'social_network_count',
    'google_rating',
    'google_reviews',
    'google_business_status',
    'category',
    'siren',
    'siret',
    'naf_code',
    'activity_code',
    'legal_form',
    'pagespeed_score',
    'company_age_years',
    'company_created_recently',
    'annual_revenue',
    'revenue',
    'annual_revenue_year',
    'net_income',
    'employee_count',
    'establishment_count',
    'bodacc_has_creation',
    'bodacc_has_accounts_filing',
    'bodacc_has_modification',
    'bodacc_has_sale',
    'bodacc_has_radiation',
    'bodacc_has_liquidation',
    'bodacc_has_collective_proceeding',
    'bodacc_has_manager_change',
    'bodacc_has_address_change',
  };

  /// Exemples volontairement exclus (non mesurables aujourd'hui).
  static const intentionallyForbiddenExamples = <String>[
    'croissance_entreprise',
    'possede_flotte',
    'cherche_fournisseur',
    'forte_activite_commerciale',
    'intention_achat',
    'budget_marketing',
  ];

  /// Motifs dans clé / libellé IA = claim non mesurable (même si field whitelist).
  static final forbiddenClaimPatterns = <RegExp>[
    RegExp(r'budget', caseSensitive: false),
    RegExp(r'croissance', caseSensitive: false),
    RegExp(r'\bcroit\b', caseSensitive: false),
    RegExp(r'en\s+croissance', caseSensitive: false),
    RegExp(r'intention', caseSensitive: false),
    RegExp(r'cherche\s+(un\s+)?fournisseur', caseSensitive: false),
    RegExp(r'flotte', caseSensitive: false),
    RegExp(r'besoin\s+(actuel|immediat|urgent)', caseSensitive: false),
    RegExp(r'forte\s+activite', caseSensitive: false),
    RegExp(r'potentiel\s+d.?achat', caseSensitive: false),
    RegExp(r'solvable', caseSensitive: false),
    RegExp(r'capacit[eé]\s+(financi|d.?achat|budg)', caseSensitive: false),
    RegExp(r'marketing\s+d[eé]di', caseSensitive: false),
  ];

  static bool isFieldMeasurable(String? field) {
    if (field == null || field.isEmpty) return false;
    final key = switch (field) {
      'revenue' => 'annual_revenue',
      'activity_code' => 'naf_code',
      _ => field,
    };
    return measurableFields.contains(key) || measurableFields.contains(field);
  }

  /// Rejette les libellés / clés qui affirment un fait non récupérable.
  static bool hasForbiddenClaim(String? key, String? label) {
    final hay = '${key ?? ''} ${label ?? ''}';
    if (hay.trim().isEmpty) return false;
    return forbiddenClaimPatterns.any((re) => re.hasMatch(hay));
  }
}
