import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../domain/entities/subscription_tier.dart';
import '../providers/play_billing_providers.dart';
import '../providers/subscription_providers.dart';
import '../widgets/plan_card.dart';

/// Listing Play Store — achat in-app uniquement dans l'app Android.
const _playStoreListingUrl =
    'https://play.google.com/store/apps/details?id=com.localhunter.localhunter';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tierAsync = ref.watch(subscriptionTierProvider);
    final billing = ref.watch(playBillingControllerProvider);

    return AppScaffold(
      title: 'Abonnement',
      body: tierAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (currentTier) => ListView(
          children: [
            Text(
              'Votre offre actuelle : ${currentTier.label}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (billing.error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                billing.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            for (final plan in SubscriptionTier.values) ...[
              PlanCard(
                title: plan.label,
                price: _priceLabel(plan, billing),
                isCurrent: plan == currentTier,
                highlighted: plan == SubscriptionTier.premiumPlus,
                features: _featuresFor(plan),
                action: _planAction(
                  context,
                  ref,
                  plan: plan,
                  currentTier: currentTier,
                  billing: billing,
                ),
              ),
              if (plan != SubscriptionTier.pro)
                const SizedBox(height: AppSpacing.md),
            ],
            const SizedBox(height: AppSpacing.lg),
            if (billing.isAndroid && billing.available) ...[
              OutlinedButton.icon(
                onPressed: billing.processing
                    ? null
                    : () => ref
                        .read(playBillingControllerProvider.notifier)
                        .restorePurchases(),
                icon: const Icon(Icons.restore),
                label: const Text('Restaurer mes achats'),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  billing.isAndroid
                      ? 'Les abonnements sont gérés par Google Play. '
                          'Renouvellement automatique, résiliation depuis '
                          'Play Store → Paiements et abonnements.'
                      : 'Les abonnements s’achètent dans l’app Android '
                          '(Google Play), avec le même compte LocalHunter. '
                          'Après l’achat, rechargez cette page pour voir '
                          'votre nouvelle offre.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _priceLabel(SubscriptionTier plan, PlayBillingState billing) {
    final productId = plan.playProductId;
    final storePrice = productId == null ? null : billing.products[productId]?.price;
    return storePrice ?? plan.priceLabel;
  }

  Widget? _planAction(
    BuildContext context,
    WidgetRef ref, {
    required SubscriptionTier plan,
    required SubscriptionTier currentTier,
    required PlayBillingState billing,
  }) {
    if (!plan.isPaid) return null;
    if (plan == currentTier) return null;

    if (billing.isAndroid && billing.available) {
      final loading = billing.loading || billing.processing;
      final label = plan.rank > currentTier.rank
          ? 'Passer à ${plan.label}'
          : 'Changer pour ${plan.label}';

      return SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: loading
              ? null
              : () =>
                  ref.read(playBillingControllerProvider.notifier).purchase(plan),
          child: loading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(label),
        ),
      );
    }

    // Web / hors Android : redirection Play Store (pas de Play Billing in-browser).
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () => _openPlayStore(context),
        icon: const Icon(Icons.android),
        label: Text('S’abonner à ${plan.label} sur Android'),
      ),
    );
  }

  Future<void> _openPlayStore(BuildContext context) async {
    final uri = Uri.parse(_playStoreListingUrl);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d’ouvrir le Play Store.'),
        ),
      );
    }
  }

  List<String> _featuresFor(SubscriptionTier tier) {
    final limits = tier.limits;
    String campaigns = limits.maxCampaigns == null
        ? 'Campagnes illimitées'
        : '${limits.maxCampaigns} campagne${limits.maxCampaigns! > 1 ? 's' : ''}';
    String grids = limits.maxGrids == null
        ? 'Grilles de scoring illimitées'
        : '${limits.maxGrids} grille${limits.maxGrids! > 1 ? 's' : ''} de scoring';
    String prospects = limits.maxProspectsPerCampaign == null
        ? 'Prospects illimités par campagne'
        : '${limits.maxProspectsPerCampaign} prospects par campagne';
    String ai = limits.maxAiGenerationsPerMonth == null
        ? (tier == SubscriptionTier.freemium
            ? 'Scoring et analyse IA inclus'
            : 'Génération IA de grilles illimitée')
        : '${limits.maxAiGenerationsPerMonth} génération${limits.maxAiGenerationsPerMonth! > 1 ? 's' : ''} '
            'IA de grilles / mois';

    return [campaigns, grids, ai, prospects];
  }
}
