import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../domain/entities/commercial_profile.dart';
import '../providers/commercial_profile_providers.dart';

/// Édition et validation du profil commercial (B4).
class CommercialProfileScreen extends ConsumerStatefulWidget {
  const CommercialProfileScreen({super.key});

  @override
  ConsumerState<CommercialProfileScreen> createState() =>
      _CommercialProfileScreenState();
}

class _CommercialProfileScreenState
    extends ConsumerState<CommercialProfileScreen> {
  final _activity = TextEditingController();
  final _offer = TextEditingController();
  final _target = TextEditingController();
  final _problem = TextEditingController();
  final _basket = TextEditingController();
  final _area = TextEditingController();
  final _size = TextEditingController();
  final _positive = TextEditingController();
  final _negative = TextEditingController();
  final _exclusion = TextEditingController();
  var _hydratedForUser = '';
  var _saving = false;

  @override
  void dispose() {
    _activity.dispose();
    _offer.dispose();
    _target.dispose();
    _problem.dispose();
    _basket.dispose();
    _area.dispose();
    _size.dispose();
    _positive.dispose();
    _negative.dispose();
    _exclusion.dispose();
    super.dispose();
  }

  void _hydrate(CommercialProfile p) {
    if (_hydratedForUser == p.userId) return;
    _activity.text = p.activity;
    _offer.text = p.offer;
    _target.text = p.targetClientType;
    _problem.text = p.problemSolved;
    _basket.text = p.averageBasket;
    _area.text = p.serviceArea;
    _size.text = p.clientSize;
    _positive.text = p.positiveSignals;
    _negative.text = p.negativeSignals;
    _exclusion.text = p.exclusionCriteria;
    _hydratedForUser = p.userId;
  }

  CommercialProfile _build(CommercialProfile base) => base.copyWith(
        activity: _activity.text.trim(),
        offer: _offer.text.trim(),
        targetClientType: _target.text.trim(),
        problemSolved: _problem.text.trim(),
        averageBasket: _basket.text.trim(),
        serviceArea: _area.text.trim(),
        clientSize: _size.text.trim(),
        positiveSignals: _positive.text.trim(),
        negativeSignals: _negative.text.trim(),
        exclusionCriteria: _exclusion.text.trim(),
      );

  Future<void> _save(CommercialProfile base, {required bool validate}) async {
    setState(() => _saving = true);
    try {
      final saved = await saveCommercialProfile(
        ref,
        _build(base),
        markValidated: validate,
      );
      _hydratedForUser = '';
      _hydrate(saved);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            validate
                ? 'Profil validé — utilisable pour la génération IA'
                : 'Brouillon enregistré',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Enregistrement impossible : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(commercialProfileProvider);
    return AppScaffold(
      title: 'Profil commercial',
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('$e'),
        data: (profile) {
          _hydrate(profile);
          return ListView(
            children: [
              _StatusBanner(profile: profile),
              const SizedBox(height: AppSpacing.md),
              _field(_activity, 'Métier / activité *', hint: 'Ex. : menuisier'),
              _field(_offer, 'Offre promue', hint: 'Ex. : pose de parquet'),
              _field(_target, 'Client cible', hint: 'Ex. : PME, restaurants'),
              _field(_problem, 'Problème résolu', maxLines: 2),
              _field(_basket, 'Panier moyen', hint: 'Ex. : 3 000 €'),
              _field(_area, 'Zone d\'intervention', hint: 'Ex. : Tarn, 50 km'),
              _field(_size, 'Taille de client', hint: 'Ex. : 5–20 salariés'),
              _field(_positive, 'Signaux positifs', maxLines: 2),
              _field(_negative, 'Signaux négatifs', maxLines: 2),
              _field(_exclusion, 'Critères éliminatoires', maxLines: 2),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _saving ? null : () => _save(profile, validate: false),
                      child: const Text('Enregistrer brouillon'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed:
                          _saving ? null : () => _save(profile, validate: true),
                      child: const Text('Valider le profil'),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    String? hint,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.profile});
  final CommercialProfile profile;

  @override
  Widget build(BuildContext context) {
    final ok = profile.isValidated;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      color: ok
          ? AppColors.border
          : AppColors.scoreMedium.withValues(alpha: 0.2),
      child: Text(
        ok
            ? 'Profil validé (v${profile.version}) — injecté dans la génération IA.'
            : 'Brouillon — validez pour l\'utiliser dans la génération de grille.',
      ),
    );
  }
}
