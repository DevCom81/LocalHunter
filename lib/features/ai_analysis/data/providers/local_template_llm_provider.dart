import 'package:uuid/uuid.dart';

import '../../domain/entities/ai_recommendation.dart';
import '../../domain/providers/llm_provider.dart';
import '../../../prospects/domain/entities/prospect.dart';
import '../../../scoring/domain/entities/prospect_score.dart';

class LocalTemplateLLMProvider implements LLMProvider {
  @override
  String get providerName => 'local_template';

  @override
  Future<AiRecommendation> analyzeProspect({
    required Prospect prospect,
    required ProspectScore score,
    String? offerLabel,
  }) async {
    final offer = score.recommendedOffer ?? offerLabel;
    final offerText = offer == null || offer.isEmpty ? 'notre offre' : offer;
    final city = prospect.city ?? 'votre ville';

    return AiRecommendation(
      id: const Uuid().v4(),
      prospectId: prospect.id,
      priority: score.priority,
      bestOffer: offer,
      mainReason:
          '${prospect.name} correspond à la cible : entreprise locale '
          'pertinente pour $offerText.',
      salesAngle:
          'Mettre en avant la valeur concrète de $offerText pour son activité.',
      facebookMessage:
          'Bonjour, nous accompagnons les entreprises de $city. '
          'Seriez-vous ouvert à un échange ?',
      shortEmail:
          'Bonjour,\n\nNous aidons les entreprises locales comme la vôtre '
          'avec $offerText.\n\nDisponible pour 15 min ?\n\nCordialement',
      callOpener:
          'Bonjour, je suis [Prénom] — nous accompagnons les entreprises '
          'de $city sur $offerText.',
      objections: const [
        ObjectionResponse(
          objection: 'Nous avons déjà un prestataire',
          response:
              'Un second avis ne coûte rien : comparons ce que vous avez '
              'et ce que nous proposons.',
        ),
        ObjectionResponse(
          objection: 'Pas le budget',
          response: 'Déploiement par étapes adapté à votre taille.',
        ),
      ],
      llmProvider: providerName,
      generatedAt: DateTime.now(),
    );
  }
}
