import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/score_indicator.dart';
import '../../../campaigns/presentation/providers/campaign_providers.dart';
import '../providers/prospect_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaignsAsync = ref.watch(campaignsProvider);

    return AppScaffold(
      title: 'Dashboard',
      body: campaignsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Erreur : $e'),
        data: (campaigns) {
          if (campaigns.isEmpty) {
            return const Center(child: Text('Aucune campagne — créez-en une.'));
          }
          final campaign = campaigns.first;
          final prospectsAsync =
              ref.watch(prospectsWithScoresProvider(campaign.id));

          return prospectsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Erreur : $e'),
            data: (prospects) {
              final active =
                  prospects.where((p) => !p.prospect.isExcluded).length;
              final highPriority =
                  prospects.where((p) => p.score.globalScore >= 70).length;
              final avgScore = prospects.isEmpty
                  ? 0
                  : (prospects
                          .map((p) => p.score.globalScore)
                          .fold(0, (a, b) => a + b) /
                      prospects.length)
                      .round();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: [
                      _KpiCard(label: 'Campagnes', value: '${campaigns.length}'),
                      _KpiCard(label: 'Prospects actifs', value: '$active'),
                      _KpiCard(label: 'Priorité haute', value: '$highPriority'),
                      _KpiCard(label: 'Score moyen', value: '$avgScore'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Campagne active',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Card(
                    child: ListTile(
                      title: Text(campaign.name),
                      subtitle: Text('${campaign.city} · ${campaign.sector}'),
                      trailing: ScoreIndicator(score: avgScore, compact: true),
                      onTap: () =>
                          context.go('${RouteNames.campaigns}/${campaign.id}'),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
      ),
    );
  }
}
