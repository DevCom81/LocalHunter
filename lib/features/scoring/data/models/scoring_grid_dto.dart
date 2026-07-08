import '../../domain/entities/criterion_rule.dart';
import '../../domain/entities/grid_config.dart';
import '../../domain/entities/scoring_grid.dart';

class ScoringGridDto {
  ScoringGridDto({
    required this.id,
    required this.userId,
    required this.name,
    required this.isTemplate,
    this.description = '',
    this.offerLabel = '',
    this.criteria = const [],
    this.exclusionConfig = const {},
    this.recommendationConfig = const {},
  });

  factory ScoringGridDto.fromJson(Map<String, dynamic> json) {
    final rawCriteria = json['scoring_criteria'] as List<dynamic>? ?? [];
    final criteria = rawCriteria
        .map((c) => ScoringCriterionDto.fromJson(c as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return ScoringGridDto(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      offerLabel: json['offer_label'] as String? ?? '',
      isTemplate: json['is_template'] as bool? ?? false,
      criteria: criteria,
      exclusionConfig:
          json['exclusion_config'] as Map<String, dynamic>? ?? const {},
      recommendationConfig:
          json['recommendation_config'] as Map<String, dynamic>? ?? const {},
    );
  }

  final String id;
  final String userId;
  final String name;
  final String description;
  final String offerLabel;
  final bool isTemplate;
  final List<ScoringCriterionDto> criteria;
  final Map<String, dynamic> exclusionConfig;
  final Map<String, dynamic> recommendationConfig;
}

class ScoringCriterionDto {
  ScoringCriterionDto({
    required this.key,
    required this.label,
    required this.kind,
    required this.maxPoints,
    required this.starMultiplier,
    required this.sortOrder,
    required this.isActive,
    this.ruleConfig = const {},
  });

  factory ScoringCriterionDto.fromJson(Map<String, dynamic> json) {
    return ScoringCriterionDto(
      key: json['criterion_key'] as String,
      label: json['label'] as String,
      kind: json['kind'] as String,
      maxPoints: json['max_points'] as int? ?? 0,
      starMultiplier: (json['star_multiplier'] as num?)?.toDouble() ?? 1.0,
      sortOrder: json['sort_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      ruleConfig: json['rule_config'] as Map<String, dynamic>? ?? const {},
    );
  }

  final String key;
  final String label;
  final String kind;
  final int maxPoints;
  final double starMultiplier;
  final int sortOrder;
  final bool isActive;
  final Map<String, dynamic> ruleConfig;

  Map<String, dynamic> toUpsertJson(String gridId) {
    return {
      'grid_id': gridId,
      'criterion_key': key,
      'kind': kind,
      'label': label,
      'max_points': maxPoints,
      'star_multiplier': starMultiplier,
      'sort_order': sortOrder,
      'is_active': isActive,
      'rule_config': ruleConfig,
    };
  }
}

CriterionKind _kindFromDb(String kind) {
  return switch (kind) {
    'sub_score' => CriterionKind.subScore,
    'exclusion' => CriterionKind.exclusion,
    _ => CriterionKind.component,
  };
}

String criterionKindToDb(CriterionKind kind) {
  return switch (kind) {
    CriterionKind.subScore => 'sub_score',
    CriterionKind.exclusion => 'exclusion',
    CriterionKind.component => 'component',
  };
}

ScoringGrid scoringGridFromDto(ScoringGridDto dto) {
  return ScoringGrid(
    id: dto.id,
    userId: dto.userId,
    name: dto.name,
    description: dto.description,
    offerLabel: dto.offerLabel,
    isTemplate: dto.isTemplate,
    exclusionConfig: GridExclusionConfig.fromJson(dto.exclusionConfig),
    recommendationConfig: GridRecommendationConfig.fromJson(dto.recommendationConfig),
    criteria: dto.criteria
        .map(
          (c) => ScoringCriterion(
            key: c.key,
            label: c.label,
            kind: _kindFromDb(c.kind),
            maxPoints: c.maxPoints,
            starMultiplier: c.starMultiplier,
            isActive: c.isActive,
            rule: CriterionRule.fromJson(c.ruleConfig),
          ),
        )
        .toList(),
  );
}

List<Map<String, dynamic>> criteriaToUpsert(ScoringGrid grid) {
  return grid.criteria.asMap().entries.map((e) {
    final c = e.value;
    return ScoringCriterionDto(
      key: c.key,
      label: c.label,
      kind: criterionKindToDb(c.kind),
      maxPoints: c.maxPoints,
      starMultiplier: c.starMultiplier,
      sortOrder: e.key,
      isActive: c.isActive,
      ruleConfig: c.rule.toJson(),
    ).toUpsertJson(grid.id);
  }).toList();
}
