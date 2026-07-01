import 'criterion_rule.dart';
import 'grid_config.dart';

enum CriterionKind { component, subScore, exclusion }

class ScoringCriterion {
  const ScoringCriterion({
    required this.key,
    required this.label,
    required this.kind,
    required this.maxPoints,
    this.starMultiplier = 1.0,
    this.isActive = true,
    this.rule = const CriterionRule(type: CriterionRuleType.legacy),
  });

  final String key;
  final String label;
  final CriterionKind kind;
  final int maxPoints;
  final double starMultiplier;
  final bool isActive;
  final CriterionRule rule;

  ScoringCriterion copyWith({
    String? key,
    String? label,
    CriterionKind? kind,
    int? maxPoints,
    double? starMultiplier,
    bool? isActive,
    CriterionRule? rule,
  }) {
    return ScoringCriterion(
      key: key ?? this.key,
      label: label ?? this.label,
      kind: kind ?? this.kind,
      maxPoints: maxPoints ?? this.maxPoints,
      starMultiplier: starMultiplier ?? this.starMultiplier,
      isActive: isActive ?? this.isActive,
      rule: rule ?? this.rule,
    );
  }
}

class ScoringGrid {
  const ScoringGrid({
    required this.id,
    required this.userId,
    required this.name,
    required this.criteria,
    this.description = '',
    this.isTemplate = false,
    this.exclusionConfig = const GridExclusionConfig(),
    this.recommendationConfig = const GridRecommendationConfig(),
  });

  final String id;
  final String userId;
  final String name;
  final String description;
  final List<ScoringCriterion> criteria;
  final bool isTemplate;
  final GridExclusionConfig exclusionConfig;
  final GridRecommendationConfig recommendationConfig;

  int get totalMax => criteria
      .where((c) => c.kind == CriterionKind.component && c.isActive)
      .fold(0, (sum, c) => sum + c.maxPoints);

  ScoringCriterion? byKey(String key) {
    try {
      return criteria.firstWhere((c) => c.key == key);
    } catch (_) {
      return null;
    }
  }

  ScoringGrid copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    List<ScoringCriterion>? criteria,
    bool? isTemplate,
    GridExclusionConfig? exclusionConfig,
    GridRecommendationConfig? recommendationConfig,
  }) {
    return ScoringGrid(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      criteria: criteria ?? this.criteria,
      isTemplate: isTemplate ?? this.isTemplate,
      exclusionConfig: exclusionConfig ?? this.exclusionConfig,
      recommendationConfig: recommendationConfig ?? this.recommendationConfig,
    );
  }
}

String kindLabel(CriterionKind kind) {
  return switch (kind) {
    CriterionKind.component => 'Composant (/100)',
    CriterionKind.subScore => 'Sous-score (étoiles)',
    CriterionKind.exclusion => 'Exclusion',
  };
}
