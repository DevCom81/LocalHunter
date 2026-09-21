import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/prospect_with_score.dart';
import '../../../../core/widgets/offer_badge.dart';
import '../../../../core/widgets/priority_badge.dart';
import '../../../../core/widgets/score_indicator.dart';
import '../providers/prospect_providers.dart';

class ProspectCard extends ConsumerWidget {
  const ProspectCard({super.key, required this.item, required this.onTap});

  final ProspectWithScore item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = item.prospect;
    final s = item.score;
    final dimmed = p.status.dimsInList;
    final contacted = p.status.marksContactedCheckbox;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          // Grisé une fois sorti du pipeline « à traiter », toujours cliquable.
          child: Opacity(
            opacity: dimmed ? 0.45 : 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: contacted,
                      visualDensity: VisualDensity.compact,
                      onChanged: (v) => setProspectContacted(
                        ref,
                        p,
                        contacted: v ?? false,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        p.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    PriorityBadge(priority: s.priority),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  p.status.label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('${p.city ?? '-'} · ${p.category ?? '-'}'),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    ScoreIndicator(score: s.globalScore, compact: true),
                    const SizedBox(width: AppSpacing.md),
                    if (s.recommendedOffer != null)
                      Flexible(child: OfferBadge(label: s.recommendedOffer!)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
