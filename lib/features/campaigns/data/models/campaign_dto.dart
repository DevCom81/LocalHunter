import '../../../../core/constants/offer_types.dart';
import '../../domain/entities/campaign.dart';

class CampaignDto {
  CampaignDto({
    required this.id,
    required this.userId,
    required this.name,
    required this.sector,
    required this.city,
    required this.radiusKm,
    required this.targetCount,
    required this.offerType,
    required this.createdAt,
    this.updatedAt,
    this.scoringGridId,
  });

  factory CampaignDto.fromJson(Map<String, dynamic> json) {
    return CampaignDto(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      sector: json['sector'] as String,
      city: json['city'] as String,
      radiusKm: json['radius_km'] as int,
      targetCount: json['target_count'] as int,
      offerType: json['offer_type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      scoringGridId: json['scoring_grid_id'] as String?,
    );
  }

  final String id;
  final String userId;
  final String name;
  final String sector;
  final String city;
  final int radiusKm;
  final int targetCount;
  final String offerType;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? scoringGridId;

  Map<String, dynamic> toInsertJson(String userId) {
    return {
      'user_id': userId,
      'name': name,
      'sector': sector,
      'city': city,
      'radius_km': radiusKm,
      'target_count': targetCount,
      'offer_type': offerType,
    };
  }
}

Campaign campaignFromDto(CampaignDto dto) {
  return Campaign(
    id: dto.id,
    userId: dto.userId,
    name: dto.name,
    sector: dto.sector,
    city: dto.city,
    radiusKm: dto.radiusKm,
    targetCount: dto.targetCount,
    offerType: OfferType.fromDb(dto.offerType),
    scoringGridId: dto.scoringGridId,
    createdAt: dto.createdAt,
    updatedAt: dto.updatedAt,
  );
}
