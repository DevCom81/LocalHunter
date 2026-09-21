import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/prospect.dart';
import 'prospect_info_section.dart';

/// Résumé des signaux BODACC (checklist, pas de dump brut).
class BodaccSignalsSection extends StatelessWidget {
  const BodaccSignalsSection({super.key, required this.prospect});

  final Prospect prospect;

  @override
  Widget build(BuildContext context) {
    final p = prospect;
    if (!p.hasBodaccEnrichment) {
      return const Text(
        'Pas encore enrichi via BODACC.',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
      );
    }

    if (p.bodaccNoResults == true) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aucune annonce BODACC pour ce SIREN '
            '(absence ≠ signal positif).',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          if (p.bodaccFetchedAt != null)
            InfoRow('Dernière récupération', _fmtDate(p.bodaccFetchedAt!)),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SignalRow('Dépôt de comptes', p.bodaccHasAccountsFiling),
        _SignalRow('Création', p.bodaccHasCreation),
        _SignalRow('Changement de dirigeant', p.bodaccHasManagerChange),
        _SignalRow('Changement d\'adresse', p.bodaccHasAddressChange),
        _SignalRow('Vente / cession', p.bodaccHasSale),
        _SignalRow('Modification', p.bodaccHasModification),
        _SignalRow('Procédure collective', p.bodaccHasCollectiveProceeding),
        _SignalRow('Liquidation', p.bodaccHasLiquidation),
        _SignalRow('Radiation', p.bodaccHasRadiation),
        if (p.bodaccLastEventAt != null)
          InfoRow('Dernier événement', _fmtDate(p.bodaccLastEventAt!)),
        if (p.bodaccRadiationStatus != null &&
            p.bodaccRadiationStatus != 'none')
          InfoRow(
            'Radiation',
            p.bodaccRadiationStatus == 'excluded'
                ? 'Concordante SIRENE (à traiter)'
                : 'À vérifier (incohérence possible)',
          ),
        if (p.bodaccFetchedAt != null)
          InfoRow('Dernière récupération', _fmtDate(p.bodaccFetchedAt!)),
      ],
    );
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _SignalRow extends StatelessWidget {
  const _SignalRow(this.label, this.value);

  final String label;
  final bool? value;

  @override
  Widget build(BuildContext context) {
    final known = value != null;
    final positive = value == true;
    // Procédure / radiation : afficher ✗ si absent (réassurance), ✓ si présent.
    final isAlert = label.startsWith('Procédure') || label == 'Radiation';
    final IconData icon;
    final Color color;
    if (!known) {
      icon = Icons.remove;
      color = AppColors.textSecondary;
    } else if (isAlert) {
      icon = positive ? Icons.warning_amber_rounded : Icons.check_circle_outline;
      color = positive ? AppColors.highPriority : AppColors.textSecondary;
    } else {
      icon = positive ? Icons.check_circle_outline : Icons.cancel_outlined;
      color = positive ? AppColors.primary : AppColors.textSecondary;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}
