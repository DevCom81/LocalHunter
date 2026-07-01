enum CriterionRuleType {
  prospectField,
  boolean,
  threshold,
  keywordMatch,
  legacy,
}

class CriterionRule {
  const CriterionRule({
    required this.type,
    this.field,
    this.match,
    this.threshold,
    this.scorerKey,
    this.presenceOnly = true,
  });

  final CriterionRuleType type;
  final String? field;
  final String? match;
  final double? threshold;
  final String? scorerKey;
  final bool presenceOnly;

  factory CriterionRule.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return const CriterionRule(type: CriterionRuleType.legacy);
    }
    final typeStr = json['type'] as String? ?? 'legacy';
    final type = switch (typeStr) {
      'prospect_field' => CriterionRuleType.prospectField,
      'boolean' => CriterionRuleType.boolean,
      'threshold' => CriterionRuleType.threshold,
      'keyword_match' => CriterionRuleType.keywordMatch,
      _ => CriterionRuleType.legacy,
    };
    return CriterionRule(
      type: type,
      field: json['field'] as String?,
      match: json['match'] as String?,
      threshold: (json['threshold'] as num?)?.toDouble(),
      scorerKey: json['scorer_key'] as String?,
      presenceOnly: json['presence_only'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    final typeStr = switch (type) {
      CriterionRuleType.prospectField => 'prospect_field',
      CriterionRuleType.boolean => 'boolean',
      CriterionRuleType.threshold => 'threshold',
      CriterionRuleType.keywordMatch => 'keyword_match',
      CriterionRuleType.legacy => 'legacy',
    };
    return {
      'type': typeStr,
      if (field != null) 'field': field,
      if (match != null) 'match': match,
      if (threshold != null) 'threshold': threshold,
      if (scorerKey != null) 'scorer_key': scorerKey,
      if (type == CriterionRuleType.prospectField) 'presence_only': presenceOnly,
    };
  }

  CriterionRule copyWith({
    CriterionRuleType? type,
    String? field,
    String? match,
    double? threshold,
    String? scorerKey,
    bool? presenceOnly,
  }) {
    return CriterionRule(
      type: type ?? this.type,
      field: field ?? this.field,
      match: match ?? this.match,
      threshold: threshold ?? this.threshold,
      scorerKey: scorerKey ?? this.scorerKey,
      presenceOnly: presenceOnly ?? this.presenceOnly,
    );
  }
}

String criterionRuleTypeLabel(CriterionRuleType type) {
  return switch (type) {
    CriterionRuleType.prospectField => 'Champ prospect',
    CriterionRuleType.boolean => 'Condition booléenne',
    CriterionRuleType.threshold => 'Seuil numérique',
    CriterionRuleType.keywordMatch => 'Mot-clé (nom/catégorie)',
    CriterionRuleType.legacy => 'Scorer intégré',
  };
}
