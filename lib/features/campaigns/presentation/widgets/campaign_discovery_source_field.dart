import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';

/// Info discovery unifiée (Phase 12) — plus de choix Places OU SIRENE.
///
/// Les campagnes existantes `places` / `sirene` restent valides en base.
class CampaignDiscoverySourceField extends StatelessWidget {
  const CampaignDiscoverySourceField({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recherche de prospects', style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'LocalHunter interroge Google Places et le registre SIRENE, '
          'rapproche les doublons, puis enrichit et score. '
          'BODACC reste un enrichissement manuel (ou différé si la grille le demande).',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
