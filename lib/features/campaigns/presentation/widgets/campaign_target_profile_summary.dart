import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/campaign_target_profile.dart';

/// Résumé lecture seule du profil de cible sur la fiche campagne.
class CampaignTargetProfileSummary extends StatelessWidget {
  const CampaignTargetProfileSummary({super.key, required this.profile});

  final CampaignTargetProfile profile;

  @override
  Widget build(BuildContext context) {
    if (profile.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cible commerciale', style: theme.textTheme.titleSmall),
            if (profile.offerSummary.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text('Offre : ${profile.offerSummary}'),
            ],
            if (profile.targetSummary.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(profile.targetSummary),
            ],
            if (profile.signalsSought.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Signaux : ${profile.signalsSought.join(' · ')}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            if (profile.exclusions.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Exclusions : ${profile.exclusions.join(' · ')}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            if (profile.geographyNote.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Zone : ${profile.geographyNote}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
