import '../../domain/entities/commercial_profile.dart';

class CommercialProfileDto {
  CommercialProfileDto({
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

  factory CommercialProfileDto.fromJson(Map<String, dynamic> json) {
    return CommercialProfileDto(
      userId: json['user_id'] as String,
      activity: json['activity'] as String? ?? '',
      offer: json['offer'] as String? ?? '',
      targetClientType: json['target_client_type'] as String? ?? '',
      problemSolved: json['problem_solved'] as String? ?? '',
      averageBasket: json['average_basket'] as String? ?? '',
      serviceArea: json['service_area'] as String? ?? '',
      clientSize: json['client_size'] as String? ?? '',
      positiveSignals: json['positive_signals'] as String? ?? '',
      negativeSignals: json['negative_signals'] as String? ?? '',
      exclusionCriteria: json['exclusion_criteria'] as String? ?? '',
      version: json['version'] as int? ?? 1,
      validatedAt: json['validated_at'] != null
          ? DateTime.tryParse(json['validated_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

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

  Map<String, dynamic> toUpsertJson({required bool markValidated}) {
    return {
      'user_id': userId,
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
      'validated_at': markValidated
          ? DateTime.now().toUtc().toIso8601String()
          : validatedAt?.toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }
}

CommercialProfile profileFromDto(CommercialProfileDto dto) {
  return CommercialProfile(
    userId: dto.userId,
    activity: dto.activity,
    offer: dto.offer,
    targetClientType: dto.targetClientType,
    problemSolved: dto.problemSolved,
    averageBasket: dto.averageBasket,
    serviceArea: dto.serviceArea,
    clientSize: dto.clientSize,
    positiveSignals: dto.positiveSignals,
    negativeSignals: dto.negativeSignals,
    exclusionCriteria: dto.exclusionCriteria,
    version: dto.version,
    validatedAt: dto.validatedAt,
    updatedAt: dto.updatedAt,
  );
}

CommercialProfileDto profileToDto(CommercialProfile p) {
  return CommercialProfileDto(
    userId: p.userId,
    activity: p.activity,
    offer: p.offer,
    targetClientType: p.targetClientType,
    problemSolved: p.problemSolved,
    averageBasket: p.averageBasket,
    serviceArea: p.serviceArea,
    clientSize: p.clientSize,
    positiveSignals: p.positiveSignals,
    negativeSignals: p.negativeSignals,
    exclusionCriteria: p.exclusionCriteria,
    version: p.version,
    validatedAt: p.validatedAt,
    updatedAt: p.updatedAt,
  );
}
