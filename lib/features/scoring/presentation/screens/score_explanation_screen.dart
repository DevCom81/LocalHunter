import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../prospects/presentation/providers/prospect_providers.dart';
import '../providers/score_explanation_providers.dart';
import '../widgets/score_contribution_list.dart';
import '../widgets/score_explanation_header.dart';

/// Écran dédié : score, confiance, contributions et avertissements.
class ScoreExplanationScreen extends ConsumerWidget {
  const ScoreExplanationScreen({super.key, required this.prospectId});

  final String prospectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(prospectByIdProvider(prospectId));
    final explanationAsync = ref.watch(scoreExplanationProvider(prospectId));
    final title = itemAsync.valueOrNull?.prospect.name ?? 'Explication du score';

    return AppScaffold(
      title: 'Explication du score',
      body: explanationAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Erreur : $e'),
        data: (explanation) {
          if (explanation == null) {
            return const Center(child: Text('Prospect introuvable'));
          }
          return ListView(
            children: <Widget>[
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              ScoreExplanationHeader(
                explanation: explanation,
                fitScore: itemAsync.valueOrNull?.score.fitScore,
                opportunityScore:
                    itemAsync.valueOrNull?.score.opportunityScore,
              ),
              const Divider(height: 32),
              ScoreWarningsSection(warnings: explanation.warnings),
              if (explanation.warnings.isNotEmpty) const Divider(height: 32),
              ScoreContributionList(contributions: explanation.contributions),
            ],
          );
        },
      ),
    );
  }
}
