import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/repository_providers.dart';
import '../../../../core/network/supabase_client_provider.dart';
import '../../../campaigns/presentation/providers/campaign_providers.dart';
import '../../../prospects/data/demo/demo_data.dart';
import '../../data/services/prospect_scoring_service.dart';
import '../../domain/entities/weight_suggestion.dart';
import '../../domain/services/crm_feedback_analyzer.dart';
import 'scoring_providers.dart';

final pendingWeightSuggestionsProvider =
    FutureProvider.family<List<WeightSuggestion>, String>((ref, gridId) async {
  return ref.watch(weightSuggestionRepositoryProvider).listPending(gridId);
});

/// Analyse les campagnes liées à [gridId] et remplace les suggestions pending.
Future<List<WeightSuggestion>> regenerateWeightSuggestions(
  WidgetRef ref,
  String gridId,
) async {
  final userId = ref.read(currentUserProvider)?.id ?? DemoData.userId;
  final grid = await ref.read(scoringGridByIdProvider(gridId).future);
  if (grid == null) {
    throw StateError('Grille introuvable');
  }

  final campaigns = await ref.read(campaignsProvider.future);
  final linked = campaigns.where((c) => c.scoringGridId == gridId);
  final observations = <CrmFeedbackObservation>[];
  final prospectRepo = ref.read(prospectRepositoryProvider);

  for (final campaign in linked) {
    final prospects = await prospectRepo.getByCampaign(campaign.id);
    final cached = await prospectRepo.getScoresByCampaign(campaign.id);
    final scoring = ProspectScoringService(grid: grid);
    for (final prospect in prospects) {
      final score = cached[prospect.id] ?? scoring.computeScore(prospect);
      observations.add(
        CrmFeedbackObservation(
          status: prospect.status,
          componentScores: score.componentScores,
        ),
      );
    }
  }

  final drafts = const CrmFeedbackAnalyzer().analyze(
    userId: userId,
    grid: grid,
    observations: observations,
  );

  final saved = await ref
      .read(weightSuggestionRepositoryProvider)
      .replacePending(gridId, drafts);
  ref.invalidate(pendingWeightSuggestionsProvider(gridId));
  return saved;
}

Future<void> acceptWeightSuggestion(
  WidgetRef ref,
  WeightSuggestion suggestion,
) async {
  final gridRepo = ref.read(scoringGridRepositoryProvider);
  final grid = await gridRepo.getById(suggestion.gridId);
  if (grid == null) throw StateError('Grille introuvable');

  final criteria = grid.criteria.map((c) {
    if (c.key != suggestion.criterionKey) return c;
    return c.copyWith(maxPoints: suggestion.suggestedMaxPoints);
  }).toList();

  final saved = await gridRepo.save(grid.copyWith(criteria: criteria));
  await ref
      .read(weightSuggestionRepositoryProvider)
      .markStatus(suggestion.id, WeightSuggestionStatus.accepted);

  ref.invalidate(scoringGridsProvider);
  ref.invalidate(scoringGridByIdProvider(suggestion.gridId));
  ref.invalidate(pendingWeightSuggestionsProvider(suggestion.gridId));
  await ref.read(rescoreCampaignsForGridProvider(saved.id).future);
}

Future<void> ignoreWeightSuggestion(
  WidgetRef ref,
  WeightSuggestion suggestion,
) async {
  await ref
      .read(weightSuggestionRepositoryProvider)
      .markStatus(suggestion.id, WeightSuggestionStatus.ignored);
  ref.invalidate(pendingWeightSuggestionsProvider(suggestion.gridId));
}
