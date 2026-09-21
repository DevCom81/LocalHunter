import '../../domain/entities/criterion_rule.dart';
import '../../domain/entities/grid_config.dart';
import '../../domain/entities/scoring_grid.dart';
import 'generated_grid_validator.dart';

/// Convertit le JSON de grille produit par l'Edge Function
/// `generate-scoring-grid` (déjà validé côté serveur) en [ScoringGrid].
///
/// Phase 11 : re-valide chaque critère contre [MeasurableCriteriaCatalog]
/// (ne fait pas confiance au seul prompt LLM).
ScoringGrid parseGeneratedGrid(
  Map<String, dynamic> json, {
  required String userId,
}) {
  final rawCriteria = json['criteria'] as List<dynamic>? ?? [];
  final parsed = rawCriteria
      .whereType<Map<String, dynamic>>()
      .map(_parseCriterion)
      .whereType<ScoringCriterion>()
      .toList();

  final filtered = const GeneratedGridValidator().filterCriteria(parsed);
  final criteria = filtered.kept;

  if (criteria.isEmpty) {
    throw FormatException(
      'Grille générée sans critère mesurable'
      '${filtered.rejectedKeys.isEmpty ? '' : ' (rejetés: ${filtered.rejectedKeys.join(', ')})'}',
    );
  }

  return ScoringGrid(
    id: '',
    userId: userId,
    name: json['name'] as String? ?? 'Grille générée',
    description: json['description'] as String? ?? '',
    isTemplate: false,
    criteria: criteria,
    exclusionConfig: GridExclusionConfig.fromJson(
      json['exclusion_config'] as Map<String, dynamic>?,
    ),
    recommendationConfig: GridRecommendationConfig.fromJson(
      json['recommendation_config'] as Map<String, dynamic>?,
    ),
  );
}

ScoringCriterion? _parseCriterion(Map<String, dynamic> json) {
  final key = json['key'] as String?;
  final label = json['label'] as String?;
  if (key == null || key.isEmpty || label == null || label.isEmpty) {
    return null;
  }
  final kind = switch (json['kind'] as String?) {
    'component' => CriterionKind.component,
    'sub_score' => CriterionKind.subScore,
    _ => null,
  };
  if (kind == null) return null;

  return ScoringCriterion(
    key: key,
    label: label,
    kind: kind,
    maxPoints: (json['max_points'] as num?)?.round() ?? 0,
    rule: CriterionRule.fromJson(json['rule'] as Map<String, dynamic>?),
  );
}
