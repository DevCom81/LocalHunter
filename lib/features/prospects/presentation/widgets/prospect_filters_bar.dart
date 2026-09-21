import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/demo_providers.dart';

/// Chips CRM génériques — pas de filtres site / logiciel / SEO.
class ProspectFiltersBar extends ConsumerWidget {
  const ProspectFiltersBar({super.key, required this.campaignId});

  final String campaignId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(prospectFiltersProvider);

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        FilterChip(
          label: const Text('Priorité haute'),
          selected: filters.highPriorityOnly,
          onSelected: (v) => ref.read(prospectFiltersProvider.notifier).state =
              filters.copyWith(highPriorityOnly: v),
        ),
        FilterChip(
          label: const Text('Score > 70'),
          selected: filters.minScore >= 70,
          onSelected: (v) => ref.read(prospectFiltersProvider.notifier).state =
              filters.copyWith(minScore: v ? 70 : 0),
        ),
        FilterChip(
          label: const Text('Exclure chaînes'),
          selected: filters.excludeFranchises,
          onSelected: (v) => ref.read(prospectFiltersProvider.notifier).state =
              filters.copyWith(excludeFranchises: v),
        ),
        FilterChip(
          label: const Text('Email dispo'),
          selected: filters.emailAvailable,
          onSelected: (v) => ref.read(prospectFiltersProvider.notifier).state =
              filters.copyWith(emailAvailable: v),
        ),
        FilterChip(
          label: const Text('Tél dispo'),
          selected: filters.phoneAvailable,
          onSelected: (v) => ref.read(prospectFiltersProvider.notifier).state =
              filters.copyWith(phoneAvailable: v),
        ),
      ],
    );
  }
}
