import '../entities/campaign.dart';
import '../entities/campaign_target_profile.dart';
import '../entities/discovery_source.dart';

class CreateCampaignInput {
  const CreateCampaignInput({
    required this.name,
    required this.sector,
    required this.city,
    required this.radiusKm,
    required this.targetCount,
    this.scoringGridId,
    this.targetProfile,
    this.discoverySource = DiscoverySource.combined,
  });

  final String name;
  final String sector;
  final String city;
  final int radiusKm;
  final int targetCount;
  final String? scoringGridId;
  final CampaignTargetProfile? targetProfile;
  final DiscoverySource discoverySource;
}

abstract class CampaignRepository {
  Future<List<Campaign>> getAll();
  Future<Campaign?> getById(String id);
  Future<Campaign> create(CreateCampaignInput input);

  /// Supprime la campagne et ses données liées (prospects, scores…)
  /// via ON DELETE CASCADE côté base.
  Future<void> delete(String id);
}
