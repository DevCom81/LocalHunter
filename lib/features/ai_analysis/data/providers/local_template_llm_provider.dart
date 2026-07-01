import 'package:uuid/uuid.dart';

import '../../domain/entities/ai_recommendation.dart';
import '../../domain/providers/llm_provider.dart';
import '../../../prospects/domain/entities/prospect.dart';
import '../../../scoring/domain/entities/prospect_score.dart';
import '../../../../core/constants/offer_types.dart';

class LocalTemplateLLMProvider implements LLMProvider {
  @override
  String get providerName => 'local_template';

  @override
  Future<AiRecommendation> analyzeProspect({
    required Prospect prospect,
    required ProspectScore score,
    required OfferType campaignOffer,
  }) async {
    final offer = score.recommendedOffer ?? campaignOffer;
    final isEasyRest = offer == OfferType.easyRest;

    return AiRecommendation(
      id: const Uuid().v4(),
      prospectId: prospect.id,
      priority: score.priority,
      bestOffer: offer,
      mainReason: isEasyRest
          ? '${prospect.name} est un établissement local sans outil intégré.'
          : 'Site web perfectible — opportunité de modernisation.',
      salesAngle: isEasyRest
          ? 'Centraliser salle, cuisine et caisse avec EasyRest.'
          : 'Améliorer visibilité locale et conversion.',
      facebookMessage:
          'Bonjour, nous accompagnons les établissements d\'Albi. '
          'Seriez-vous ouvert à un échange ?',
      shortEmail:
          'Bonjour,\n\nNous aidons les établissements locaux à '
          '${isEasyRest ? 'optimiser leur gestion' : 'moderniser leur site'}.\n\n'
          'Disponible pour 15 min ?\n\nCordialement',
      callOpener:
          'Bonjour, je suis [Prénom] — nous aidons les restaurateurs '
          'd\'Albi à digitaliser leur activité.',
      objections: const [
        ObjectionResponse(
          objection: 'Nous avons déjà un système',
          response: 'EasyRest se déploie module par module.',
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
