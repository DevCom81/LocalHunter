import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/score_indicator.dart';

/// Affiche FIT / OPPORTUNITY sous le score global (Phase 8).
class FitOpportunityScores extends StatelessWidget {
  const FitOpportunityScores({
    super.key,
    required this.fitScore,
    required this.opportunityScore,
  });

  final int? fitScore;
  final int? opportunityScore;

  @override
  Widget build(BuildContext context) {
    if (fitScore == null && opportunityScore == null) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Correspondance = bon profil. Opportunité = bon moment à contacter.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (fitScore != null) ...[
          Text('Correspondance avec votre cible', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          ScoreIndicator(score: fitScore!),
          const SizedBox(height: AppSpacing.md),
        ],
        if (opportunityScore != null) ...[
          Text('Opportunité actuelle', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          ScoreIndicator(score: opportunityScore!),
        ],
      ],
    );
  }
}
