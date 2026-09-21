import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/prospect.dart';
import '../../domain/signals/prospect_signal.dart';
import '../../domain/signals/prospect_signal_builder.dart';

/// Affiche les faits / signaux dérivés (pas d'hypothèses présentées comme faits).
class ProspectSignalsSection extends StatelessWidget {
  const ProspectSignalsSection({super.key, required this.prospect});

  final Prospect prospect;

  @override
  Widget build(BuildContext context) {
    final signals = const ProspectSignalBuilder().build(prospect);
    final theme = Theme.of(context);

    if (signals.isEmpty) {
      return Text(
        'Aucun signal disponible pour l\'instant '
        '(enrichissez le prospect ou lancez une recherche).',
        style: theme.textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
        ),
      );
    }

    final facts = signals.where((s) => s.kind == SignalKind.fact).toList();
    final derived = signals.where((s) => s.kind == SignalKind.signal).toList();
    final inferences =
        signals.where((s) => s.kind == SignalKind.inference).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fait = donnée source. Signal = interprétation commerciale. '
          'Hypothèse = déduction non prouvée (jamais affichée comme vérité).',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
        if (facts.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text('Faits', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          ...facts.map(_SignalTile.new),
        ],
        if (derived.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text('Signaux', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          ...derived.map(_SignalTile.new),
        ],
        if (inferences.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text('Hypothèses', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          ...inferences.map(_SignalTile.new),
        ],
      ],
    );
  }
}

class _SignalTile extends StatelessWidget {
  const _SignalTile(this.signal);

  final ProspectSignal signal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              signal.kindLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${signal.label} : ${signal.displayValue}',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Text(
            signal.source,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
