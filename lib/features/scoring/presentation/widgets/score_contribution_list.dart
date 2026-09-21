import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/score_contribution.dart';

/// Contributions positives et négatives / nulles du score.
class ScoreContributionList extends StatelessWidget {
  const ScoreContributionList({super.key, required this.contributions});

  final List<ScoreContribution> contributions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final positive = contributions
        .where((c) => c.isPositive && c.contribution > 0)
        .toList();
    final negative = contributions
        .where((c) => !c.isPositive || c.value == 0)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pourquoi ce score', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        if (positive.isNotEmpty) ...[
          Text(
            'Points favorables',
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppColors.scoreHigh,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          ...positive.map<Widget>((c) => _ContributionTile(c: c)),
          const SizedBox(height: AppSpacing.md),
        ],
        if (negative.isNotEmpty) ...[
          Text(
            'Points faibles ou absents',
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppColors.scoreLow,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          ...negative.map<Widget>((c) => _ContributionTile(c: c)),
        ],
        if (positive.isEmpty && negative.isEmpty)
          Text(
            'Aucune contribution disponible.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );
  }
}

class _ContributionTile extends StatelessWidget {
  const _ContributionTile({required this.c});

  final ScoreContribution c;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sign = c.contribution > 0 ? '+' : '';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(c.label, style: theme.textTheme.bodyLarge),
              ),
              Text(
                '$sign${c.contribution} · ${c.value}/${c.maxPoints}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: c.isPositive
                      ? AppColors.scoreHigh
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          Text(
            c.explanation,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            'Source : ${c.sourceLabel}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
