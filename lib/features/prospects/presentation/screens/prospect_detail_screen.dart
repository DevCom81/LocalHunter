import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/offer_badge.dart';
import '../../../../core/widgets/priority_badge.dart';
import '../../../../core/widgets/score_indicator.dart';
import '../../../scoring/presentation/widgets/fit_opportunity_scores.dart';
import '../../domain/entities/prospect.dart';
import '../providers/bodacc_providers.dart';
import '../providers/prospect_providers.dart';
import '../widgets/bodacc_signals_section.dart';
import '../widgets/prospect_info_section.dart';
import '../widgets/prospect_score_breakdown.dart';
import '../widgets/prospect_signals_section.dart';
import '../widgets/prospect_status_selector.dart';

class ProspectDetailScreen extends ConsumerStatefulWidget {
  const ProspectDetailScreen({super.key, required this.prospectId});

  final String prospectId;

  @override
  ConsumerState<ProspectDetailScreen> createState() =>
      _ProspectDetailScreenState();
}

class _ProspectDetailScreenState extends ConsumerState<ProspectDetailScreen> {
  bool _bodaccBusy = false;

  Future<void> _enrichBodacc(Prospect prospect) async {
    setState(() => _bodaccBusy = true);
    try {
      final n = await runBodaccEnrichment(
        ref,
        campaignId: prospect.campaignId,
        only: [prospect],
        forceRefresh: true,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            n > 0
                ? 'Enrichissement BODACC terminé.'
                : 'BODACC : aucun traitement '
                    '(exclu, déjà à jour, ou identifiant légal insuffisant).',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('BODACC impossible : $e')),
      );
    } finally {
      if (mounted) setState(() => _bodaccBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemAsync = ref.watch(prospectByIdProvider(widget.prospectId));

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
        final canBodacc = p.siren != null &&
            p.siren!.replaceAll(RegExp(r'\D'), '').length == 9 &&
            !p.isExcluded;

        return AppScaffold(
          title: p.name,
          actions: [
            IconButton(
              icon: const Icon(Icons.psychology_outlined),
              onPressed: () =>
                  context.push('/prospects/${widget.prospectId}/ai'),
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
              const SizedBox(height: AppSpacing.md),
              FitOpportunityScores(
                fitScore: s.fitScore,
                opportunityScore: s.opportunityScore,
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () =>
                      context.push('/prospects/${widget.prospectId}/score'),
                  icon: const Icon(Icons.insights_outlined),
                  label: const Text('Explication du score'),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ProspectStatusSelector(prospect: p),
              const SizedBox(height: AppSpacing.lg),
              ProspectInfoSection(prospect: p),
              const Divider(height: 32),
              Text(
                'Faits & signaux',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              ProspectSignalsSection(prospect: p),
              const Divider(height: 32),
              Text(
                'Événements BODACC',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              BodaccSignalsSection(prospect: p),
              if (canBodacc) ...[
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: _bodaccBusy ? null : () => _enrichBodacc(p),
                  icon: _bodaccBusy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.account_balance_outlined),
                  label: Text(
                    p.hasBodaccEnrichment
                        ? 'Actualiser BODACC'
                        : 'Enrichir avec BODACC',
                  ),
                ),
              ],
              if (p.customFields.isNotEmpty) ...[
                const Divider(height: 32),
                Text(
                  'Champs personnalisés',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                ...p.customFields.entries.map(
                  (e) => InfoRow(e.key, e.value),
                ),
              ],
              const Divider(height: 32),
              Text(
                'Composants',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              ...prospectComponentRows(s),
              const Divider(height: 32),
              Text(
                'Sous-scores',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              ...prospectSubScoreRows(s),
            ],
          ),
        );
      },
    );
  }
}
