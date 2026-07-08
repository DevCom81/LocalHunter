class ExclusionRule {
  const ExclusionRule({
    required this.type,
    this.keywords = const [],
    this.patterns = const [],
    this.categoryKeyword,
    this.nameKeywords = const [],
    this.criterionKey,
    this.minStars,
  });

  final String type;
  final List<String> keywords;
  final List<String> patterns;
  final String? categoryKeyword;
  final List<String> nameKeywords;
  final String? criterionKey;
  final double? minStars;

  factory ExclusionRule.fromJson(Map<String, dynamic> json) {
    return ExclusionRule(
      type: json['type'] as String,
      keywords: (json['keywords'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      patterns: (json['patterns'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      categoryKeyword: json['category_keyword'] as String?,
      nameKeywords: (json['name_keywords'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      criterionKey: json['criterion_key'] as String?,
      minStars: (json['min_stars'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        if (keywords.isNotEmpty) 'keywords': keywords,
        if (patterns.isNotEmpty) 'patterns': patterns,
        if (categoryKeyword != null) 'category_keyword': categoryKeyword,
        if (nameKeywords.isNotEmpty) 'name_keywords': nameKeywords,
        if (criterionKey != null) 'criterion_key': criterionKey,
        if (minStars != null) 'min_stars': minStars,
      };

  ExclusionRule copyWith({
    String? type,
    List<String>? keywords,
    List<String>? patterns,
    String? categoryKeyword,
    List<String>? nameKeywords,
    String? criterionKey,
    double? minStars,
  }) {
    return ExclusionRule(
      type: type ?? this.type,
      keywords: keywords ?? this.keywords,
      patterns: patterns ?? this.patterns,
      categoryKeyword: categoryKeyword ?? this.categoryKeyword,
      nameKeywords: nameKeywords ?? this.nameKeywords,
      criterionKey: criterionKey ?? this.criterionKey,
      minStars: minStars ?? this.minStars,
    );
  }
}

class GridExclusionConfig {
  const GridExclusionConfig({this.rules = const []});

  final List<ExclusionRule> rules;

  factory GridExclusionConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const GridExclusionConfig();
    final raw = json['rules'] as List<dynamic>? ?? [];
    return GridExclusionConfig(
      rules: raw
          .map((r) => ExclusionRule.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'rules': rules.map((r) => r.toJson()).toList(),
      };

  GridExclusionConfig copyWith({List<ExclusionRule>? rules}) {
    return GridExclusionConfig(rules: rules ?? this.rules);
  }
}

/// Règle « prospect pertinent pour l'offre » : si le sous-score atteint le
/// seuil (et que la catégorie correspond, le cas échéant), l'offre de la
/// grille ([ScoringGrid.offerLabel]) est recommandée pour ce prospect.
class RecommendationRule {
  const RecommendationRule({
    required this.criterionKey,
    required this.minStars,
    this.categoryKeyword,
  });

  final String criterionKey;
  final double minStars;
  final String? categoryKeyword;

  factory RecommendationRule.fromJson(Map<String, dynamic> json) {
    return RecommendationRule(
      criterionKey: json['criterion_key'] as String,
      minStars: (json['min_stars'] as num).toDouble(),
      categoryKeyword: json['category_keyword'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'criterion_key': criterionKey,
        'min_stars': minStars,
        if (categoryKeyword != null) 'category_keyword': categoryKeyword,
      };

  RecommendationRule copyWith({
    String? criterionKey,
    double? minStars,
    String? categoryKeyword,
  }) {
    return RecommendationRule(
      criterionKey: criterionKey ?? this.criterionKey,
      minStars: minStars ?? this.minStars,
      categoryKeyword: categoryKeyword ?? this.categoryKeyword,
    );
  }
}

class GridRecommendationConfig {
  const GridRecommendationConfig({this.rules = const []});

  final List<RecommendationRule> rules;

  factory GridRecommendationConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const GridRecommendationConfig();
    final raw = json['rules'] as List<dynamic>? ?? [];
    return GridRecommendationConfig(
      rules: raw
          .map((r) => RecommendationRule.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'rules': rules.map((r) => r.toJson()).toList(),
      };

  GridRecommendationConfig copyWith({List<RecommendationRule>? rules}) {
    return GridRecommendationConfig(rules: rules ?? this.rules);
  }
}
