import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../subscription/domain/entities/subscription_tier.dart';
import '../../../subscription/presentation/providers/subscription_providers.dart';
import '../providers/campaign_providers.dart';
import '../widgets/campaign_card.dart';

class CampaignsListScreen extends ConsumerWidget {
  const CampaignsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaignsAsync = ref.watch(campaignsProvider);

    return AppScaffold(
      title: 'Campagnes',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Attendre le tier réel avant tout message de quota (une lecture
          // pendant le chargement ferait passer un premium pour freemium).
          final tier = await resolveTier(ref);
          final maxCampaigns = tier.limits.maxCampaigns;
          final atLimit = maxCampaigns != null &&
              (campaignsAsync.valueOrNull?.length ?? 0) >= maxCampaigns;
          if (!context.mounted) return;
          if (atLimit) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                showCloseIcon: true,
                content: Text(
                  'Quota atteint (${maxCampaigns} campagne'
                  '${maxCampaigns! > 1 ? 's' : ''} max). '
                  '${PlanLimits.upgradeMessage}',
                ),
                action: SnackBarAction(
                  label: 'Abonnement',
                  onPressed: () => context.go(RouteNames.subscription),
                ),
              ),
            );
            return;
          }
          context.go('${RouteNames.campaigns}/create');
        },
        label: const Text('Nouvelle campagne'),
        icon: const Icon(Icons.add),
      ),
      body: campaignsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (campaigns) => ListView.separated(
          itemCount: campaigns.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (_, index) {
            final campaign = campaigns[index];
            return CampaignCard(
              campaign: campaign,
              onTap: () => context.go('${RouteNames.campaigns}/${campaign.id}'),
            );
          },
        ),
      ),
    );
  }
}
