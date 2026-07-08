import '../entities/ai_recommendation.dart';
import '../../../prospects/domain/entities/prospect.dart';
import '../../../scoring/domain/entities/prospect_score.dart';

abstract class LLMProvider {
  String get providerName;

  Future<AiRecommendation> analyzeProspect({
    required Prospect prospect,
    required ProspectScore score,

    /// Offre promue par la grille de la campagne (texte libre).
    String? offerLabel,
  });
}
