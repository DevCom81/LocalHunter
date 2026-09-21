import 'campaign_target_profile.dart';
import 'discovery_source.dart';

/// Campagne = géographie opérationnelle + volume + grille.
/// L'offre promue reste sur la grille ; le [targetProfile] précise la cible
/// commerciale (Phase 7, optionnel).
class Campaign {
  const Campaign({
    required this.id,
    required this.userId,
    required this.name,
    required this.sector,
    required this.city,
    required this.radiusKm,
    required this.targetCount,
    required this.createdAt,
    this.scoringGridId,
    this.updatedAt,
    this.targetProfile = const CampaignTargetProfile(),
    this.discoverySource = DiscoverySource.combined,
  });

  final String id;
  final String userId;
  final String name;
  final String sector;
  final String city;
  final int radiusKm;
  final int targetCount;
  final String? scoringGridId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final CampaignTargetProfile targetProfile;
  final DiscoverySource discoverySource;

  Campaign copyWith({
    String? name,
    int? radiusKm,
    int? targetCount,
    String? scoringGridId,
    CampaignTargetProfile? targetProfile,
    DiscoverySource? discoverySource,
  }) {
    return Campaign(
      id: id,
      userId: userId,
      name: name ?? this.name,
      sector: sector,
      city: city,
      radiusKm: radiusKm ?? this.radiusKm,
      targetCount: targetCount ?? this.targetCount,
      scoringGridId: scoringGridId ?? this.scoringGridId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      targetProfile: targetProfile ?? this.targetProfile,
      discoverySource: discoverySource ?? this.discoverySource,
    );
  }
}
