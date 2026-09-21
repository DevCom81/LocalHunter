enum WeightSuggestionStatus { pending, accepted, ignored }

/// Proposition d'ajustement de [maxPoints] — jamais appliquée sans Accept.
class WeightSuggestion {
  const WeightSuggestion({
    required this.id,
    required this.userId,
    required this.gridId,
    required this.criterionKey,
    required this.criterionLabel,
    required this.currentMaxPoints,
    required this.suggestedMaxPoints,
    required this.rationale,
    this.evidence = const {},
    this.status = WeightSuggestionStatus.pending,
    this.createdAt,
    this.resolvedAt,
  });

  final String id;
  final String userId;
  final String gridId;
  final String criterionKey;
  final String criterionLabel;
  final int currentMaxPoints;
  final int suggestedMaxPoints;
  final String rationale;
  final Map<String, dynamic> evidence;
  final WeightSuggestionStatus status;
  final DateTime? createdAt;
  final DateTime? resolvedAt;

  int get delta => suggestedMaxPoints - currentMaxPoints;

  bool get isPending => status == WeightSuggestionStatus.pending;

  WeightSuggestion copyWith({
    WeightSuggestionStatus? status,
    DateTime? resolvedAt,
  }) {
    return WeightSuggestion(
      id: id,
      userId: userId,
      gridId: gridId,
      criterionKey: criterionKey,
      criterionLabel: criterionLabel,
      currentMaxPoints: currentMaxPoints,
      suggestedMaxPoints: suggestedMaxPoints,
      rationale: rationale,
      evidence: evidence,
      status: status ?? this.status,
      createdAt: createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  static WeightSuggestionStatus statusFromDb(String value) {
    return WeightSuggestionStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => WeightSuggestionStatus.pending,
    );
  }
}
