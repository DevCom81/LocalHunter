import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/campaign_target_profile.dart';

/// Champs optionnels « qui recherchez-vous ? » (langage commercial).
class CampaignTargetProfileFields extends StatelessWidget {
  const CampaignTargetProfileFields({
    super.key,
    required this.offerCtrl,
    required this.targetCtrl,
    required this.signalsCtrl,
    required this.exclusionsCtrl,
    required this.geoNoteCtrl,
    this.sizeCtrl,
  });

  final TextEditingController offerCtrl;
  final TextEditingController targetCtrl;
  final TextEditingController signalsCtrl;
  final TextEditingController exclusionsCtrl;
  final TextEditingController geoNoteCtrl;
  final TextEditingController? sizeCtrl;

  /// Construit un profil ; null si tout est vide.
  static CampaignTargetProfile? buildProfile({
    required TextEditingController offerCtrl,
    required TextEditingController targetCtrl,
    required TextEditingController signalsCtrl,
    required TextEditingController exclusionsCtrl,
    required TextEditingController geoNoteCtrl,
    TextEditingController? sizeCtrl,
  }) {
    List<String> lines(String raw) => raw
        .split(RegExp(r'[\n;]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final profile = CampaignTargetProfile(
      offerSummary: offerCtrl.text.trim(),
      targetSummary: targetCtrl.text.trim(),
      signalsSought: lines(signalsCtrl.text),
      exclusions: lines(exclusionsCtrl.text),
      clientSizeHint: sizeCtrl?.text.trim() ?? '',
      geographyNote: geoNoteCtrl.text.trim(),
    );
    return profile.isEmpty ? null : profile;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cible commerciale (optionnel)', style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'La ville et le rayon ci-dessus restent le filtre géographique. '
          'Décrivez ici qui vous intéresse vraiment.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: offerCtrl,
          decoration: const InputDecoration(
            labelText: 'Que proposez-vous ?',
            hintText: 'Ex. : contrats de flotte, maintenance froid…',
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: targetCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Qui recherchez-vous ?',
            hintText: 'Ex. : PME avec techniciens itinérants',
          ),
        ),
        if (sizeCtrl != null) ...[
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: sizeCtrl,
            decoration: const InputDecoration(
              labelText: 'Taille / effectif cible',
              hintText: 'Ex. : 50 à 300 salariés',
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: signalsCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Signaux intéressants (un par ligne)',
            hintText: 'Ex. : multi-sites\ncréation récente',
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: exclusionsCtrl,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'À exclure (un par ligne)',
            hintText: 'Ex. : franchises nationales',
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: geoNoteCtrl,
          decoration: const InputDecoration(
            labelText: 'Précision géo (optionnel)',
            hintText: 'Ex. : Occitanie, Tarn — en plus de la ville',
          ),
        ),
      ],
    );
  }
}
