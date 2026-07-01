import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/offer_badge.dart';
import '../../../../core/widgets/priority_badge.dart';
import '../../../../core/widgets/score_indicator.dart';
import '../providers/prospect_providers.dart';

class ProspectDetailScreen extends ConsumerWidget {
  const ProspectDetailScreen({super.key, required this.prospectId});

  final String prospectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(prospectByIdProvider(prospectId));

    return itemAsync.when(
      loading: () => const AppScaffold(
        title: 'Prospect',
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => AppScaffold(title: 'Prospect', body: Text('$e')),
      data: (item) {
        if (item == null) {
          return const AppScaffold(
            title: 'Prospect',
            body: Center(child: Text('Prospect introuvable')),
          );
        }
        final p = item.prospect;
        final s = item.score;

        return AppScaffold(
          title: p.name,
          actions: [
            IconButton(
              icon: const Icon(Icons.psychology_outlined),
              onPressed: () => context.go('/prospects/$prospectId/ai'),
            ),
          ],
          body: ListView(
            children: [
              Row(
                children: [
                  PriorityBadge(priority: s.priority),
                  const SizedBox(width: AppSpacing.sm),
                  if (s.recommendedOffer != null)
                    OfferBadge(offer: s.recommendedOffer!),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              ScoreIndicator(score: s.globalScore),
              const SizedBox(height: AppSpacing.lg),
              _InfoRow('Ville', p.city),
              _InfoRow('Adresse', p.address),
              _InfoRow('Responsable', p.managerName),
              _InfoRow('Email', p.email),
              _InfoRow('Téléphone', p.phone),
              _InfoRow('Site web', p.website),
              _InfoRow('Catégorie', p.category),
              _InfoRow('Note Google', p.googleRating?.toString()),
              _InfoRow('Avis', '${p.googleReviews}'),
              _InfoRow('Statut', p.status.label),
              if (p.isExcluded) _InfoRow('Exclusion', p.exclusionReason),
              if (p.customFields.isNotEmpty) ...[
                const Divider(height: 32),
                Text('Champs personnalisés',
                    style: Theme.of(context).textTheme.titleMedium),
                ...p.customFields.entries.map(
                  (e) => _InfoRow(e.key, e.value),
                ),
              ],
              const Divider(height: 32),
              Text('Composants', style: Theme.of(context).textTheme.titleMedium),
              ..._buildComponentRows(s),
              const Divider(height: 32),
              Text('Sous-scores', style: Theme.of(context).textTheme.titleMedium),
              ..._buildSubScoreRows(s),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildComponentRows(dynamic s) {
    if (s.componentScores.isNotEmpty) {
      return s.componentScores.entries
          .map((e) => _InfoRow(e.key, '${e.value} pts'))
          .toList();
    }
    return [
      _InfoRow('Accessibilité', '${s.accessibilityScore} pts'),
      _InfoRow('Site web', '${s.websiteOpportunity} pts'),
      _InfoRow('Logiciel', '${s.softwareOpportunity} pts'),
      _InfoRow('Santé commerciale', '${s.commercialHealth} pts'),
    ];
  }

  List<Widget> _buildSubScoreRows(dynamic s) {
    if (s.subScores.isNotEmpty) {
      return s.subScores.entries
          .map((e) => _InfoRow(e.key, '${e.value.toStringAsFixed(1)} ★'))
          .toList();
    }
    return [
      _InfoRow('SiteScore', '${s.siteScore.toStringAsFixed(1)} ★'),
      _InfoRow('EasyRestScore', '${s.easyRestScore.toStringAsFixed(1)} ★'),
      _InfoRow('Risque faux positif',
          '${s.falsePositiveRisk.toStringAsFixed(1)} ★'),
    ];
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value ?? '-')),
        ],
      ),
    );
  }
}
