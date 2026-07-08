import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/offer_badge.dart';
import '../../../../core/widgets/priority_badge.dart';
import '../../../../core/widgets/score_indicator.dart';
import '../../../scoring/domain/entities/prospect_score.dart';
import '../providers/prospect_providers.dart';
import '../widgets/prospect_info_section.dart';

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
              onPressed: () => context.push('/prospects/$prospectId/ai'),
            ),
          ],
          body: ListView(
            children: [
              Row(
                children: [
                  PriorityBadge(priority: s.priority),
                  const SizedBox(width: AppSpacing.sm),
                  if (s.recommendedOffer != null)
                    Flexible(child: OfferBadge(label: s.recommendedOffer!)),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              ScoreIndicator(score: s.globalScore),
              const SizedBox(height: AppSpacing.lg),
              ProspectInfoSection(prospect: p),
              if (p.customFields.isNotEmpty) ...[
                const Divider(height: 32),
                Text('Champs personnalisés',
                    style: Theme.of(context).textTheme.titleMedium),
                ...p.customFields.entries.map(
                  (e) => InfoRow(e.key, e.value),
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

  // Paramètre typé : avec `dynamic`, map(...).toList() produisait un
  // List<dynamic> dont le cast implicite vers List<Widget> échouait à
  // l'exécution (écran d'erreur gris en release).
  List<Widget> _buildComponentRows(ProspectScore s) {
    if (s.componentScores.isNotEmpty) {
      return s.componentScores.entries
          .map<Widget>((e) => InfoRow(e.key, '${e.value} pts'))
          .toList();
    }
    return [
      InfoRow('Accessibilité', '${s.accessibilityScore} pts'),
      InfoRow('Site web', '${s.websiteOpportunity} pts'),
      InfoRow('Logiciel', '${s.softwareOpportunity} pts'),
      InfoRow('Santé commerciale', '${s.commercialHealth} pts'),
    ];
  }

  List<Widget> _buildSubScoreRows(ProspectScore s) {
    if (s.subScores.isNotEmpty) {
      return s.subScores.entries
          .map<Widget>((e) => InfoRow(e.key, '${e.value.toStringAsFixed(1)} ★'))
          .toList();
    }
    return [
      InfoRow('SiteScore', '${s.siteScore.toStringAsFixed(1)} ★'),
      InfoRow('EasyRestScore', '${s.easyRestScore.toStringAsFixed(1)} ★'),
      InfoRow('Risque faux positif',
          '${s.falsePositiveRisk.toStringAsFixed(1)} ★'),
    ];
  }
}
