import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';

class PlanCard extends StatelessWidget {
  const PlanCard({
    super.key,
    required this.title,
    required this.price,
    required this.features,
    required this.isCurrent,
    this.highlighted = false,
    this.action,
  });

  final String title;
  final String price;
  final List<String> features;
  final bool isCurrent;
  final bool highlighted;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      shape: highlighted
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: scheme.primary, width: 2),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                if (isCurrent)
                  Chip(
                    label: const Text('Offre actuelle'),
                    backgroundColor: scheme.primaryContainer,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              price,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  children: [
                    Icon(Icons.check, size: 18, color: scheme.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(f)),
                  ],
                ),
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.md),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
