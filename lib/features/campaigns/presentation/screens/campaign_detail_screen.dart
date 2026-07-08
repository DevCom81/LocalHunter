import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/offer_badge.dart';
import '../providers/campaign_providers.dart';
import '../widgets/delete_campaign_button.dart';
import '../../../prospects/presentation/providers/prospect_providers.dart';
import '../../../prospects/presentation/widgets/search_places_button.dart';
import '../../../scoring/presentation/providers/scoring_providers.dart';

class CampaignDetailScreen extends ConsumerWidget {
  const CampaignDetailScreen({super.key, required this.campaignId});

  final String campaignId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaignAsync = ref.watch(campaignByIdProvider(campaignId));
    final prospectsAsync = ref.watch(prospectsWithScoresProvider(campaignId));
    final gridAsync = ref.watch(campaignScoringGridProvider(campaignId));

    return campaignAsync.when(
      loading: () => const AppScaffold(
        title: 'Campagne',
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => AppScaffold(title: 'Campagne', body: Text('$e')),
      data: (campaign) {
        if (campaign == null) {
          return const AppScaffold(
            title: 'Campagne',
            body: Center(child: Text('Campagne introuvable')),
          );
        }
        final count = prospectsAsync.valueOrNull?.length ?? 0;
        return AppScaffold(
          title: campaign.name,
          actions: [
            DeleteCampaignButton(campaign: campaign, prospectCount: count),
          ],
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // L'offre promue est portée par la grille de scoring liée.
              OfferBadge(label: gridAsync.valueOrNull?.offerLabel ?? ''),
              const SizedBox(height: AppSpacing.md),
              Text('${campaign.sector} · ${campaign.city} · ${campaign.radiusKm} km'),
              const SizedBox(height: AppSpacing.lg),
              Text('$count prospects', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  SearchPlacesButton(campaignId: campaignId),
                  ActionChip(
                    avatar: const Icon(Icons.grid_view, size: 18),
                    label: const Text('Scoring'),
                    onPressed: gridAsync.valueOrNull == null
                        ? null
                        : () => context.go(
                              RouteNames.scoringGridEdit(gridAsync.requireValue.id),
                            ),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.people_outline, size: 18),
                    label: const Text('CRM'),
                    onPressed: () => context.go(
                      '${RouteNames.campaigns}/$campaignId/prospects',
                    ),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.upload_file, size: 18),
                    label: const Text('Import CSV'),
                    onPressed: () => context.go(
                      '${RouteNames.campaigns}/$campaignId/import',
                    ),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.download, size: 18),
                    label: const Text('Export'),
                    onPressed: () => context.go(
                      '${RouteNames.campaigns}/$campaignId/export',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
