import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/prospect_with_score.dart';
import '../../../../core/widgets/offer_badge.dart';
import '../../../../core/widgets/priority_badge.dart';
import '../../../../core/widgets/score_indicator.dart';

class ProspectCard extends StatelessWidget {
  const ProspectCard({super.key, required this.item, required this.onTap});

  final ProspectWithScore item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = item.prospect;
    final s = item.score;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      p.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  PriorityBadge(priority: s.priority),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('${p.city ?? '-'} · ${p.category ?? '-'}'),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  ScoreIndicator(score: s.globalScore, compact: true),
                  const SizedBox(width: AppSpacing.md),
                  if (s.recommendedOffer != null)
                    OfferBadge(offer: s.recommendedOffer!),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
