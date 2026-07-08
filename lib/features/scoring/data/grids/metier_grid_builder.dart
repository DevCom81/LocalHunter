import '../../domain/entities/criterion_rule.dart';
import '../../domain/entities/grid_config.dart';
import '../../domain/entities/scoring_grid.dart';

/// Spécification compacte d'une grille métier du catalogue.
class MetierGridSpec {
  const MetierGridSpec({
    required this.id,
    required this.name,
    required this.description,
    required this.aliases,
    required this.targetKeyword,
    this.targetPoints = 20,
    this.minRating = 4.0,
    this.minReviews = 15,
    this.exclusionKeywords = const [],
  });

  final String id;
  final String name;
  final String description;

  /// Libellés métier reconnus (formes normalisées : minuscules, sans accents).
  final List<String> aliases;

  /// Mot-clé ciblant la catégorie/le nom des prospects visés.
  final String targetKeyword;
  final int targetPoints;
  final double minRating;
  final int minReviews;
  final List<String> exclusionKeywords;
}

/// Construit une [ScoringGrid] à partir d'une spec métier.
///
/// Structure commune (composants = 100 pts) :
/// téléphone 25 + email 15 + cible métier [targetPoints] +
/// réputation Google [40 - targetPoints + 20] répartie sur note et volume.
ScoringGrid buildMetierGrid(MetierGridSpec spec, {String userId = ''}) {
  final reputationPoints = 60 - spec.targetPoints; // note + volume d'avis
  final ratingPoints = (reputationPoints * 0.6).round();
  final reviewsPoints = reputationPoints - ratingPoints;

  return ScoringGrid(
    id: spec.id,
    userId: userId,
    name: spec.name,
    description: spec.description,
    // Offre par défaut = le métier ; l'utilisateur la précise dans l'éditeur.
    offerLabel: spec.name,
    isTemplate: true,
    exclusionConfig: GridExclusionConfig(
      rules: [
        if (spec.exclusionKeywords.isNotEmpty)
          ExclusionRule(type: 'known_chain', keywords: spec.exclusionKeywords),
        const ExclusionRule(
          type: 'email_pattern',
          patterns: ['@corp.', '@group.', '@global.'],
        ),
      ],
    ),
    criteria: [
      _fieldComponent('contact_direct', 'Décisionnaire joignable (téléphone)',
          'phone', 25),
      _fieldComponent('email_disponible', 'Email de contact disponible',
          'email', 15),
      ScoringCriterion(
        key: 'cible_metier',
        label: 'Correspond à la cible métier',
        kind: CriterionKind.component,
        maxPoints: spec.targetPoints,
        rule: CriterionRule(
          type: CriterionRuleType.keywordMatch,
          match: spec.targetKeyword,
        ),
      ),
      _thresholdComponent('reputation_google', 'Réputation Google',
          'google_rating', spec.minRating, ratingPoints),
      _thresholdComponent('volume_avis', 'Volume d\'avis Google',
          'google_reviews', spec.minReviews.toDouble(), reviewsPoints),
      _fieldSubScore('presence_web', 'Présence site web', 'website'),
      _fieldSubScore('presence_facebook', 'Présence Facebook', 'facebook_url'),
      _fieldSubScore(
          'presence_instagram', 'Présence Instagram', 'instagram_url'),
      _fieldSubScore(
          'responsable_identifie', 'Responsable identifié', 'manager_name'),
    ],
  );
}

ScoringCriterion _fieldComponent(
    String key, String label, String field, int max) {
  return ScoringCriterion(
    key: key,
    label: label,
    kind: CriterionKind.component,
    maxPoints: max,
    rule: CriterionRule(
      type: CriterionRuleType.prospectField,
      field: field,
      presenceOnly: true,
    ),
  );
}

ScoringCriterion _thresholdComponent(
    String key, String label, String field, double threshold, int max) {
  return ScoringCriterion(
    key: key,
    label: label,
    kind: CriterionKind.component,
    maxPoints: max,
    rule: CriterionRule(
      type: CriterionRuleType.threshold,
      field: field,
      threshold: threshold,
    ),
  );
}

ScoringCriterion _fieldSubScore(String key, String label, String field) {
  return ScoringCriterion(
    key: key,
    label: label,
    kind: CriterionKind.subScore,
    maxPoints: 5,
    rule: CriterionRule(
      type: CriterionRuleType.prospectField,
      field: field,
      presenceOnly: true,
    ),
  );
}
