import '../entities/campaign.dart';
import '../../../../core/constants/offer_types.dart';

class CreateCampaignInput {
  const CreateCampaignInput({
    required this.name,
    required this.sector,
    required this.city,
    required this.radiusKm,
    required this.targetCount,
    required this.offerType,
    this.scoringGridId,
  });

  final String name;
  final String sector;
  final String city;
  final int radiusKm;
  final int targetCount;
  final OfferType offerType;
  final String? scoringGridId;
}

abstract class CampaignRepository {
  Future<List<Campaign>> getAll();
  Future<Campaign?> getById(String id);
  Future<Campaign> create(CreateCampaignInput input);
}
