import 'package:uuid/uuid.dart';

import '../../../../core/constants/offer_types.dart';
import '../../domain/entities/campaign.dart';
import '../../domain/repositories/campaign_repository.dart';
import '../../../prospects/data/demo/demo_data.dart';
import '../../../scoring/data/grids/default_scoring_grids.dart';

class DemoCampaignRepository implements CampaignRepository {
  DemoCampaignRepository() {
    _campaigns = [
      Campaign(
        id: DemoData.campaignId,
        userId: DemoData.userId,
        name: 'Restaurants Albi — EasyRest',
        sector: 'restauration',
        city: 'Albi',
        radiusKm: 15,
        targetCount: 20,
        offerType: OfferType.easyRest,
        scoringGridId: DefaultScoringGrids.demoCampaignGridId,
        createdAt: DateTime.now(),
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
      offerType: input.offerType,
      scoringGridId: input.scoringGridId ?? DefaultScoringGrids.defaultId,
      createdAt: DateTime.now(),
    );
    _campaigns = [..._campaigns, campaign];
    return campaign;
  }
}
