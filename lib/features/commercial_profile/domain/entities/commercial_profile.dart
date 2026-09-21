/// Profil commercial structuré — visible, éditable, validé avant usage IA.
class CommercialProfile {
  const CommercialProfile({
    required this.userId,
    this.activity = '',
    this.offer = '',
    this.targetClientType = '',
    this.problemSolved = '',
    this.averageBasket = '',
    this.serviceArea = '',
    this.clientSize = '',
    this.positiveSignals = '',
    this.negativeSignals = '',
    this.exclusionCriteria = '',
    this.version = 1,
    this.validatedAt,
    this.updatedAt,
  });

  final String userId;
  final String activity;
  final String offer;
  final String targetClientType;
  final String problemSolved;
  final String averageBasket;
  final String serviceArea;
  final String clientSize;
  final String positiveSignals;
  final String negativeSignals;
  final String exclusionCriteria;
  final int version;
  final DateTime? validatedAt;
  final DateTime? updatedAt;

  bool get isValidated => validatedAt != null;

  bool get isEmpty =>
      activity.trim().isEmpty &&
      offer.trim().isEmpty &&
      targetClientType.trim().isEmpty;

  CommercialProfile copyWith({
    String? activity,
    String? offer,
    String? targetClientType,
    String? problemSolved,
    String? averageBasket,
    String? serviceArea,
    String? clientSize,
    String? positiveSignals,
    String? negativeSignals,
    String? exclusionCriteria,
    int? version,
    DateTime? validatedAt,
    bool clearValidatedAt = false,
    DateTime? updatedAt,
  }) {
    return CommercialProfile(
      userId: userId,
      activity: activity ?? this.activity,
      offer: offer ?? this.offer,
      targetClientType: targetClientType ?? this.targetClientType,
      problemSolved: problemSolved ?? this.problemSolved,
      averageBasket: averageBasket ?? this.averageBasket,
      serviceArea: serviceArea ?? this.serviceArea,
      clientSize: clientSize ?? this.clientSize,
      positiveSignals: positiveSignals ?? this.positiveSignals,
      negativeSignals: negativeSignals ?? this.negativeSignals,
      exclusionCriteria: exclusionCriteria ?? this.exclusionCriteria,
      version: version ?? this.version,
      validatedAt:
          clearValidatedAt ? null : (validatedAt ?? this.validatedAt),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Payload optionnel pour l'Edge Function (uniquement si validé).
  Map<String, dynamic>? toEdgePayload() {
    if (!isValidated) return null;
    return {
      'activity': activity,
      'offer': offer,
      'target_client_type': targetClientType,
      'problem_solved': problemSolved,
      'average_basket': averageBasket,
      'service_area': serviceArea,
      'client_size': clientSize,
      'positive_signals': positiveSignals,
      'negative_signals': negativeSignals,
      'exclusion_criteria': exclusionCriteria,
      'version': version,
    };
  }
}
