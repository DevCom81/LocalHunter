import '../entities/ai_recommendation.dart';
import '../../../prospects/domain/entities/prospect.dart';
import '../../../scoring/domain/entities/prospect_score.dart';
import '../../../../core/constants/offer_types.dart';

abstract class LLMProvider {
  String get providerName;

  Future<AiRecommendation> analyzeProspect({
    required Prospect prospect,
    required ProspectScore score,
    required OfferType campaignOffer,
  });
}
