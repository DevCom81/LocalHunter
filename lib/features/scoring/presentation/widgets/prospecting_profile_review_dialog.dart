import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/prospecting_profile.dart';
import '../../domain/measurable_criteria_catalog.dart';

/// Étape 2 Phase 5 : l'utilisateur valide / ajuste le profil avant la grille.
class ProspectingProfileReviewDialog extends StatefulWidget {
  const ProspectingProfileReviewDialog({super.key, required this.profile});

  final ProspectingProfile profile;

  static Future<ProspectingProfile?> show(
    BuildContext context,
    ProspectingProfile profile,
  ) {
    return showDialog<ProspectingProfile>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProspectingProfileReviewDialog(profile: profile),
    );
  }

  @override
  State<ProspectingProfileReviewDialog> createState() =>
      _ProspectingProfileReviewDialogState();
}

class _ProspectingProfileReviewDialogState
    extends State<ProspectingProfileReviewDialog> {
  late final TextEditingController _offer;
  late final TextEditingController _target;
  late final TextEditingController _signals;
  late final TextEditingController _exclusions;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _offer = TextEditingController(text: p.offer);
    _target = TextEditingController(text: p.targetSummary);
    _signals = TextEditingController(text: p.signals.join('\n'));
    _exclusions = TextEditingController(text: p.exclusions.join('\n'));
  }

  @override
  void dispose() {
    _offer.dispose();
    _target.dispose();
    _signals.dispose();
    _exclusions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Profil de prospection'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'LocalHunter a compris votre cible. Vérifiez avant de '
                'construire la grille technique.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _offer,
                decoration: const InputDecoration(labelText: 'Votre offre'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _target,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Qui recherchez-vous ?',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _signals,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Signaux recherchés (un par ligne)',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _exclusions,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'À exclure (un par ligne)',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Modifier'),
        ),
        FilledButton(
          onPressed: _confirm,
          child: const Text('Utiliser ce profil'),
        ),
      ],
    );
  }

  void _confirm() {
    final offer = _offer.text.trim();
    final target = _target.text.trim();
    final signals = _lines(_signals.text)
        .where((s) => !MeasurableCriteriaCatalog.hasForbiddenClaim(null, s))
        .toList();
    final exclusions = _lines(_exclusions.text)
        .where((s) => !MeasurableCriteriaCatalog.hasForbiddenClaim(null, s))
        .toList();
    if (offer.length < 3 || target.length < 10 || signals.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Complétez offre, cible et au moins 2 signaux mesurables '
            '(pas de budget, croissance, flotte…).',
          ),
        ),
      );
      return;
    }
    Navigator.of(context).pop(
      widget.profile.copyWith(
        offer: offer,
        targetSummary: target,
        signals: signals,
        exclusions: exclusions.isEmpty ? widget.profile.exclusions : exclusions,
      ),
    );
  }

  List<String> _lines(String raw) => raw
      .split(RegExp(r'[\n;]+'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}
