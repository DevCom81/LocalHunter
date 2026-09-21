import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../prospects/presentation/providers/prospect_providers.dart';
import '../../data/engine/score_explanation_builder.dart';
import '../../domain/entities/score_explanation.dart';
import 'scoring_providers.dart';

/// Explication du score : snapshot persisté (B1) ou recalcul à la volée.
final scoreExplanationProvider =
    FutureProvider.family<ScoreExplanation?, String>((ref, prospectId) async {
  final item = await ref.watch(prospectByIdProvider(prospectId).future);
  if (item == null) return null;

  final persisted = ScoreExplanation.fromPersisted(
    globalScore: item.score.globalScore,
    confidenceScore: item.score.confidenceScore,
    filledFields: item.score.filledFields,
    totalFields: item.score.totalFields,
    missingFields: item.score.missingFields,
    contributions: item.score.explanationContributions,
    warnings: item.score.explanationWarnings,
  );
  if (persisted != null) return persisted;

  final grid = await ref.watch(
    campaignScoringGridProvider(item.prospect.campaignId).future,
  );
  return ScoreExplanationBuilder().build(
    prospect: item.prospect,
    score: item.score,
    grid: grid,
  );
});
