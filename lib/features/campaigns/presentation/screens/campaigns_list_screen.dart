import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_scaffold.dart';
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
        onPressed: () => context.go('${RouteNames.campaigns}/create'),
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
