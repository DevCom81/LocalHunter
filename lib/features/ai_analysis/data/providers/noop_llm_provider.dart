import 'package:uuid/uuid.dart';

import '../../domain/entities/ai_recommendation.dart';
import '../../domain/providers/llm_provider.dart';
import '../../../prospects/domain/entities/prospect.dart';
import '../../../scoring/domain/entities/prospect_score.dart';

class NoopLLMProvider implements LLMProvider {
  @override
  String get providerName => 'noop';

  @override
  Future<AiRecommendation> analyzeProspect({
    required Prospect prospect,
    required ProspectScore score,
    String? offerLabel,
  }) async {
    return AiRecommendation(
      id: const Uuid().v4(),
      prospectId: prospect.id,
      llmProvider: providerName,
      generatedAt: DateTime.now(),
    );
  }
}
