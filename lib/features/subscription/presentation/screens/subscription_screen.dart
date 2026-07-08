import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../domain/entities/subscription_tier.dart';
import '../providers/subscription_providers.dart';
import '../widgets/plan_card.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tierAsync = ref.watch(subscriptionTierProvider);

    return AppScaffold(
      title: 'Abonnement',
      body: tierAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (tier) => ListView(
          children: [
            Text(
              'Votre offre actuelle : ${tier.label}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            PlanCard(
              title: 'Freemium',
              price: 'Gratuit',
              isCurrent: !tier.isPremium,
              features: const [
                '${FreemiumLimits.maxCampaigns} campagne',
                '${FreemiumLimits.maxGrids} grille de scoring',
                '${FreemiumLimits.maxProspectsPerCampaign} prospects '
                    'par campagne',
                'Scoring et analyse IA inclus',
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            PlanCard(
              title: 'Premium',
              price: premiumMonthlyPriceLabel,
              isCurrent: tier.isPremium,
              highlighted: true,
              features: const [
                'Campagnes illimitées',
                'Grilles de scoring illimitées',
                'Prospects illimités',
                'Génération IA de grilles illimitée',
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Expanded(
                      child: Text(
                        'Le changement d\'abonnement depuis l\'application '
                        'sera bientôt disponible.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
