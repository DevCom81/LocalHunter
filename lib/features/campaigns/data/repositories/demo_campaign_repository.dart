import 'package:uuid/uuid.dart';

import '../../domain/entities/campaign.dart';
import '../../domain/entities/campaign_target_profile.dart';
import '../../domain/repositories/campaign_repository.dart';
import '../../../prospects/data/demo/demo_data.dart';
import '../../../scoring/data/grids/default_scoring_grids.dart';

class DemoCampaignRepository implements CampaignRepository {
  DemoCampaignRepository() {
    _campaigns = [
      Campaign(
        id: DemoData.campaignId,
        userId: DemoData.userId,
        name: 'Campagne démo — Albi',
        sector: 'restaurant',
        city: 'Albi',
        radiusKm: 15,
        targetCount: 20,
        scoringGridId: DefaultScoringGrids.demoCampaignGridId,
        createdAt: DateTime.now(),
        targetProfile: const CampaignTargetProfile(
          offerSummary: '',
          targetSummary: 'Commerces indépendants à Albi (données fictives)',
        ),
      ),
    ];
  }

  late List<Campaign> _campaigns;
  final _uuid = const Uuid();

  @override
  Future<List<Campaign>> getAll() async => List.unmodifiable(_campaigns);

  @override
  Future<Campaign?> getById(String id) async {
    try {
      return _campaigns.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Campaign> create(CreateCampaignInput input) async {
    final campaign = Campaign(
      id: _uuid.v4(),
      userId: DemoData.userId,
      name: input.name,
      sector: input.sector,
      city: input.city,
      radiusKm: input.radiusKm,
      targetCount: input.targetCount,
      scoringGridId: input.scoringGridId ?? DefaultScoringGrids.defaultId,
      createdAt: DateTime.now(),
      targetProfile: input.targetProfile ?? const CampaignTargetProfile(),
      discoverySource: input.discoverySource,
    );
    _campaigns = [..._campaigns, campaign];
    return campaign;
  }

  @override
  Future<void> delete(String id) async {
    _campaigns = _campaigns.where((c) => c.id != id).toList();
  }
}
