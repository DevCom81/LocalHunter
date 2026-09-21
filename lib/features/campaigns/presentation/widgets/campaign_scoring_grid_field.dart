import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../scoring/data/grids/default_scoring_grids.dart';
import '../../../scoring/presentation/providers/scoring_providers.dart';

/// Sélecteur de grille à la création de campagne.
class CampaignScoringGridField extends ConsumerWidget {
  const CampaignScoringGridField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gridsAsync = ref.watch(scoringGridsProvider);
    return gridsAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('$e'),
      data: (grids) {
        final ids = grids.map((g) => g.id).toSet();
        final resolved = ids.contains(value)
            ? value
            : DefaultScoringGrids.resolveDefault(grids)?.id;
        if (resolved != null && resolved != value) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onChanged(resolved);
          });
        }
        if (grids.isEmpty) {
          return Text(
            'Aucune grille de scoring. Créez-en une avant la campagne.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
          );
        }
        final selected = ids.contains(value) ? value : resolved;
        return DropdownButtonFormField<String>(
          // Key : remonte le champ quand la sélection résolue change
          // (initialValue seul n’est pas resynchronisé).
          key: ValueKey(selected),
          initialValue: selected,
          decoration: const InputDecoration(
            labelText: 'Grille de scoring',
            helperText:
                'Détermine l\'offre promue et l\'évaluation des prospects',
          ),
          items: grids
              .map(
                (g) => DropdownMenuItem(
                  value: g.id,
                  child: Text(
                    g.offerLabel.isEmpty
                        ? g.name
                        : '${g.name} — ${g.offerLabel}',
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
          validator: (v) =>
              v == null || v.isEmpty ? 'Choisissez une grille' : null,
        );
      },
    );
  }
}
