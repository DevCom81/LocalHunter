/// Gravité d'un avertissement lié à la confiance des données.
enum ScoreWarningSeverity { info, warning, critical }

/// Incohérence ou lacune détectée entre sources / champs.
class ScoreWarning {
  const ScoreWarning({
    required this.type,
    required this.message,
    this.severity = ScoreWarningSeverity.warning,
  });

  factory ScoreWarning.fromJson(Map<String, dynamic> json) {
    final raw = json['severity'] as String? ?? 'warning';
    final severity = ScoreWarningSeverity.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => ScoreWarningSeverity.warning,
    );
    return ScoreWarning(
      type: json['type'] as String,
      message: json['message'] as String,
      severity: severity,
    );
  }

  final String type;
  final String message;
  final ScoreWarningSeverity severity;

  Map<String, dynamic> toJson() => {
        'type': type,
        'message': message,
        'severity': severity.name,
      };
}

/// Indice de confiance indépendant du score métier (0–100).
class ScoreConfidence {
  const ScoreConfidence({
    required this.score,
    required this.filledFields,
    required this.totalFields,
    this.missingFields = const [],
    this.missingFieldLabels = const [],
    this.warnings = const [],
  });

  final int score;
  final int filledFields;
  final int totalFields;
  final List<String> missingFields;
  final List<String> missingFieldLabels;
  final List<ScoreWarning> warnings;

  double get completenessRatio =>
      totalFields == 0 ? 0 : filledFields / totalFields;
}
