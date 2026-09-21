import '../../domain/entities/campaign.dart';
import '../../domain/entities/campaign_target_profile.dart';
import '../../domain/entities/discovery_source.dart';

class CampaignDto {
  CampaignDto({
    required this.id,
    required this.userId,
    required this.name,
    required this.sector,
    required this.city,
    required this.radiusKm,
    required this.targetCount,
    required this.createdAt,
    this.updatedAt,
    this.scoringGridId,
    this.targetProfile,
    this.discoverySource = 'combined',
  });

  factory CampaignDto.fromJson(Map<String, dynamic> json) {
    final rawProfile = json['target_profile'];
    return CampaignDto(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      sector: json['sector'] as String,
      city: json['city'] as String,
      radiusKm: json['radius_km'] as int,
      targetCount: json['target_count'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      scoringGridId: json['scoring_grid_id'] as String?,
      targetProfile: rawProfile is Map<String, dynamic>
          ? CampaignTargetProfile.fromJson(rawProfile)
          : null,
      discoverySource: json['discovery_source'] as String? ?? 'combined',
    );
  }

  final String id;
  final String userId;
  final String name;
  final String sector;
  final String city;
  final int radiusKm;
  final int targetCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? scoringGridId;
  final CampaignTargetProfile? targetProfile;
  final String discoverySource;
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
    scoringGridId: dto.scoringGridId,
    createdAt: dto.createdAt,
    updatedAt: dto.updatedAt,
    targetProfile: dto.targetProfile ?? const CampaignTargetProfile(),
    discoverySource: DiscoverySource.fromDb(dto.discoverySource),
  );
}
