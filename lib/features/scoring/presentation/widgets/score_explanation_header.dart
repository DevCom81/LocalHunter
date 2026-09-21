import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/score_indicator.dart';
import '../../domain/entities/score_confidence.dart';
import '../../domain/entities/score_explanation.dart';
import 'fit_opportunity_scores.dart';

/// En-tête : score métier + confiance + complétude des données.
class ScoreExplanationHeader extends StatelessWidget {
  const ScoreExplanationHeader({
    super.key,
    required this.explanation,
    this.fitScore,
    this.opportunityScore,
  });

  final ScoreExplanation explanation;
  final int? fitScore;
  final int? opportunityScore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = explanation.confidence;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Score métier', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        ScoreIndicator(score: explanation.globalScore),
        const SizedBox(height: AppSpacing.md),
        FitOpportunityScores(
          fitScore: fitScore,
          opportunityScore: opportunityScore,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Confiance des données', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        ScoreIndicator(score: c.score),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Données renseignées : ${c.filledFields}/${c.totalFields}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        if (c.missingFieldLabels.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Manquants : ${c.missingFieldLabels.join(', ')}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xs),
        Text(
          'La confiance est indépendante du score métier.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Les contributions ci-dessous expliquent le score — ce ne sont pas '
          'des preuves que le prospect a besoin de votre offre. '
          'Les faits et signaux sont listés sur la fiche prospect.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Liste d'avertissements (SIRENE, finances, etc.).
class ScoreWarningsSection extends StatelessWidget {
  const ScoreWarningsSection({super.key, required this.warnings});

  final List<ScoreWarning> warnings;

  @override
  Widget build(BuildContext context) {
    if (warnings.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Avertissements', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        ...warnings.map<Widget>((w) {
          final color = switch (w.severity) {
            ScoreWarningSeverity.critical => AppColors.scoreLow,
            ScoreWarningSeverity.warning => AppColors.scoreMedium,
            ScoreWarningSeverity.info => AppColors.textSecondary,
          };
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, size: 20, color: color),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(w.message, style: TextStyle(color: color)),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
