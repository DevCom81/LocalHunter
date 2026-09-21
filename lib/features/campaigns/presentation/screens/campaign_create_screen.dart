import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../domain/entities/discovery_source.dart';
import '../../domain/repositories/campaign_repository.dart';
import '../../../scoring/presentation/providers/pending_target_profile_provider.dart';
import '../providers/campaign_providers.dart';
import '../widgets/campaign_discovery_source_field.dart';
import '../widgets/campaign_scoring_grid_field.dart';
import '../widgets/campaign_target_profile_fields.dart';

class CampaignCreateScreen extends ConsumerStatefulWidget {
  const CampaignCreateScreen({super.key});

  @override
  ConsumerState<CampaignCreateScreen> createState() =>
      _CampaignCreateScreenState();
}

class _CampaignCreateScreenState extends ConsumerState<CampaignCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _sectorCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _radiusCtrl = TextEditingController(text: '15');
  final _targetCtrl = TextEditingController(text: '20');
  final _offerCtrl = TextEditingController();
  final _targetSummaryCtrl = TextEditingController();
  final _sizeCtrl = TextEditingController();
  final _signalsCtrl = TextEditingController();
  final _exclusionsCtrl = TextEditingController();
  final _geoNoteCtrl = TextEditingController();
  String? _scoringGridId;
  bool _saving = false;
  bool _profilePrefillDone = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _sectorCtrl.dispose();
    _cityCtrl.dispose();
    _radiusCtrl.dispose();
    _targetCtrl.dispose();
    _offerCtrl.dispose();
    _targetSummaryCtrl.dispose();
    _sizeCtrl.dispose();
    _signalsCtrl.dispose();
    _exclusionsCtrl.dispose();
    _geoNoteCtrl.dispose();
    super.dispose();
  }

  void _prefillFromPendingProfile() {
    if (_profilePrefillDone) return;
    final pending = ref.read(pendingCampaignTargetProfileProvider);
    if (pending == null || pending.isEmpty) {
      _profilePrefillDone = true;
      return;
    }
    _offerCtrl.text = pending.offerSummary;
    _targetSummaryCtrl.text = pending.targetSummary;
    _sizeCtrl.text = pending.clientSizeHint;
    _signalsCtrl.text = pending.signalsSought.join('\n');
    _exclusionsCtrl.text = pending.exclusions.join('\n');
    _geoNoteCtrl.text = pending.geographyNote;
    _profilePrefillDone = true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final radius = int.tryParse(_radiusCtrl.text.trim());
    final target = int.tryParse(_targetCtrl.text.trim());
    if (radius == null || radius <= 0 || target == null || target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rayon et nb prospects doivent être des entiers > 0'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final campaign = await ref.read(campaignsProvider.notifier).create(
            CreateCampaignInput(
              name: _nameCtrl.text.trim(),
              sector: _sectorCtrl.text.trim().isEmpty
                  ? 'entreprises'
                  : _sectorCtrl.text.trim(),
              city: _cityCtrl.text.trim(),
              radiusKm: radius,
              targetCount: target,
              scoringGridId: _scoringGridId,
              discoverySource: DiscoverySource.combined,
              targetProfile: CampaignTargetProfileFields.buildProfile(
                offerCtrl: _offerCtrl,
                targetCtrl: _targetSummaryCtrl,
                signalsCtrl: _signalsCtrl,
                exclusionsCtrl: _exclusionsCtrl,
                geoNoteCtrl: _geoNoteCtrl,
                sizeCtrl: _sizeCtrl,
              ),
            ),
          );
      ref.read(pendingCampaignTargetProfileProvider.notifier).state = null;
      if (mounted) context.go('${RouteNames.campaigns}/${campaign.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Création impossible : $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _prefillFromPendingProfile();
    return AppScaffold(
      title: 'Nouvelle campagne',
      body: Form(
        key: _formKey,
        child: ListView(
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nom de la campagne',
              ),
              validator: (v) => v == null || v.isEmpty ? 'Nom requis' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            const CampaignDiscoverySourceField(),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Zone de recherche',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _cityCtrl,
              decoration: const InputDecoration(labelText: 'Ville'),
              validator: (v) => v == null || v.isEmpty ? 'Ville requise' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _radiusCtrl,
              decoration: const InputDecoration(
                labelText: 'Rayon (km)',
                helperText:
                    'Appliqué à Google Places ; SIRENE filtre par commune / CP',
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse(v?.trim() ?? '');
                if (n == null || n <= 0) return 'Entier > 0 requis';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _sectorCtrl,
              decoration: const InputDecoration(
                labelText: 'Mot-clé de recherche',
                hintText: 'Ex. : restaurant, garage, pharmacie, entrepôt…',
                helperText:
                    'Utilisé pour Places et SIRENE — pas la définition de votre offre',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _targetCtrl,
              decoration: const InputDecoration(
                labelText: 'Nb prospects cible',
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse(v?.trim() ?? '');
                if (n == null || n <= 0) return 'Entier > 0 requis';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            CampaignTargetProfileFields(
              offerCtrl: _offerCtrl,
              targetCtrl: _targetSummaryCtrl,
              signalsCtrl: _signalsCtrl,
              exclusionsCtrl: _exclusionsCtrl,
              geoNoteCtrl: _geoNoteCtrl,
              sizeCtrl: _sizeCtrl,
            ),
            const SizedBox(height: AppSpacing.lg),
            CampaignScoringGridField(
              value: _scoringGridId,
              onChanged: (v) => setState(() => _scoringGridId = v),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Créer la campagne'),
            ),
          ],
        ),
      ),
    );
  }
}
