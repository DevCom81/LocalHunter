/// Contribution d'un critère au score global (calculée à la volée / persistée).
class ScoreContribution {
  const ScoreContribution({
    required this.criterionKey,
    required this.label,
    required this.value,
    required this.maxPoints,
    required this.contribution,
    required this.source,
    required this.sourceLabel,
    required this.explanationKey,
    required this.explanation,
    this.isPositive = true,
  });

  factory ScoreContribution.fromJson(Map<String, dynamic> json) {
    return ScoreContribution(
      criterionKey: json['criterion_key'] as String,
      label: json['label'] as String,
      value: json['value'] as num,
      maxPoints: json['max_points'] as int,
      contribution: json['contribution'] as int,
      source: json['source'] as String,
      sourceLabel: json['source_label'] as String? ?? json['source'] as String,
      explanationKey: json['explanation_key'] as String,
      explanation: json['explanation'] as String? ?? '',
      isPositive: json['is_positive'] as bool? ?? true,
    );
  }

  final String criterionKey;
  final String label;
  final num value;
  final int maxPoints;
  final int contribution;
  final String source;
  final String sourceLabel;
  final String explanationKey;
  final String explanation;
  final bool isPositive;

  Map<String, dynamic> toJson() => {
        'criterion_key': criterionKey,
        'label': label,
        'value': value,
        'max_points': maxPoints,
        'contribution': contribution,
        'source': source,
        'source_label': sourceLabel,
        'explanation_key': explanationKey,
        'explanation': explanation,
        'is_positive': isPositive,
      };
}
