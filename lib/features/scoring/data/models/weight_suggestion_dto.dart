import '../../domain/entities/weight_suggestion.dart';

class WeightSuggestionDto {
  const WeightSuggestionDto({
    required this.id,
    required this.userId,
    required this.gridId,
    required this.criterionKey,
    required this.criterionLabel,
    required this.currentMaxPoints,
    required this.suggestedMaxPoints,
    required this.rationale,
    required this.evidence,
    required this.status,
    this.createdAt,
    this.resolvedAt,
  });

  factory WeightSuggestionDto.fromJson(Map<String, dynamic> json) {
    final evidenceRaw = json['evidence'];
    return WeightSuggestionDto(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      gridId: json['grid_id'] as String,
      criterionKey: json['criterion_key'] as String,
      criterionLabel: json['criterion_label'] as String? ?? '',
      currentMaxPoints: json['current_max_points'] as int,
      suggestedMaxPoints: json['suggested_max_points'] as int,
      rationale: json['rationale'] as String? ?? '',
      evidence: evidenceRaw is Map
          ? Map<String, dynamic>.from(evidenceRaw)
          : const {},
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.tryParse(json['resolved_at'] as String)
          : null,
    );
  }

  final String id;
  final String userId;
  final String gridId;
  final String criterionKey;
  final String criterionLabel;
  final int currentMaxPoints;
  final int suggestedMaxPoints;
  final String rationale;
  final Map<String, dynamic> evidence;
  final String status;
  final DateTime? createdAt;
  final DateTime? resolvedAt;

  Map<String, dynamic> toInsertJson() => {
        'user_id': userId,
        'grid_id': gridId,
        'criterion_key': criterionKey,
        'criterion_label': criterionLabel,
        'current_max_points': currentMaxPoints,
        'suggested_max_points': suggestedMaxPoints,
        'rationale': rationale,
        'evidence': evidence,
        'status': 'pending',
      };
}

WeightSuggestion suggestionFromDto(WeightSuggestionDto dto) {
  return WeightSuggestion(
    id: dto.id,
    userId: dto.userId,
    gridId: dto.gridId,
    criterionKey: dto.criterionKey,
    criterionLabel: dto.criterionLabel,
    currentMaxPoints: dto.currentMaxPoints,
    suggestedMaxPoints: dto.suggestedMaxPoints,
    rationale: dto.rationale,
    evidence: dto.evidence,
    status: WeightSuggestion.statusFromDb(dto.status),
    createdAt: dto.createdAt,
    resolvedAt: dto.resolvedAt,
  );
}

WeightSuggestionDto suggestionToDto(WeightSuggestion s) {
  return WeightSuggestionDto(
    id: s.id,
    userId: s.userId,
    gridId: s.gridId,
    criterionKey: s.criterionKey,
    criterionLabel: s.criterionLabel,
    currentMaxPoints: s.currentMaxPoints,
    suggestedMaxPoints: s.suggestedMaxPoints,
    rationale: s.rationale,
    evidence: s.evidence,
    status: s.status.name,
    createdAt: s.createdAt,
    resolvedAt: s.resolvedAt,
  );
}
