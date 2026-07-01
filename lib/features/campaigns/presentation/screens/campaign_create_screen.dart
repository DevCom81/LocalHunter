import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/offer_types.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../scoring/data/grids/default_scoring_grids.dart';
import '../../../scoring/presentation/providers/scoring_providers.dart';
import '../../domain/repositories/campaign_repository.dart';
import '../providers/campaign_providers.dart';

class CampaignCreateScreen extends ConsumerStatefulWidget {
  const CampaignCreateScreen({super.key});

  @override
  ConsumerState<CampaignCreateScreen> createState() =>
      _CampaignCreateScreenState();
}

class _CampaignCreateScreenState extends ConsumerState<CampaignCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _sectorCtrl = TextEditingController(text: 'restauration');
  final _cityCtrl = TextEditingController();
  final _radiusCtrl = TextEditingController(text: '15');
  final _targetCtrl = TextEditingController(text: '20');
  OfferType _offerType = OfferType.easyRest;
  String? _scoringGridId;
  bool _saving = false;
  bool _gridManuallySet = false;

  @override
  void initState() {
    super.initState();
    _scoringGridId = DefaultScoringGrids.easyRestId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _sectorCtrl.dispose();
    _cityCtrl.dispose();
    _radiusCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final campaign = await ref
          .read(campaignsProvider.notifier)
          .create(
            CreateCampaignInput(
              name: _nameCtrl.text.trim(),
              sector: _sectorCtrl.text.trim(),
              city: _cityCtrl.text.trim(),
              radiusKm: int.parse(_radiusCtrl.text),
              targetCount: int.parse(_targetCtrl.text),
              offerType: _offerType,
              scoringGridId: _scoringGridId,
            ),
          );
      if (mounted) context.go('${RouteNames.campaigns}/${campaign.id}');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gridsAsync = ref.watch(scoringGridsProvider);
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
            TextFormField(
              controller: _sectorCtrl,
              decoration: const InputDecoration(labelText: 'Secteur'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _cityCtrl,
              decoration: const InputDecoration(labelText: 'Ville'),
              validator: (v) => v == null || v.isEmpty ? 'Ville requise' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _radiusCtrl,
              decoration: const InputDecoration(labelText: 'Rayon (km)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _targetCtrl,
              decoration: const InputDecoration(
                labelText: 'Nb prospects cible',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<OfferType>(
              initialValue: _offerType,
              decoration: const InputDecoration(labelText: 'Type d\'offre'),
              items: OfferType.values
                  .map((o) => DropdownMenuItem(value: o, child: Text(o.label)))
                  .toList(),
              onChanged: (v) => setState(() {
                _offerType = v ?? _offerType;
                if (!_gridManuallySet) {
                  _scoringGridId = _offerType == OfferType.easyRest
                      ? DefaultScoringGrids.easyRestId
                      : DefaultScoringGrids.defaultId;
                }
              }),
            ),
            const SizedBox(height: AppSpacing.md),
            gridsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('$e'),
              data: (grids) {
                final ids = grids.map((g) => g.id).toSet();
                final resolved = ids.contains(_scoringGridId)
                    ? _scoringGridId
                    : DefaultScoringGrids.forOfferType(grids, _offerType)?.id;
                if (resolved != null && resolved != _scoringGridId) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _scoringGridId = resolved);
                  });
                }
                return DropdownButtonFormField<String>(
                  initialValue: ids.contains(_scoringGridId)
                      ? _scoringGridId
                      : resolved,
                  decoration: const InputDecoration(
                    labelText: 'Modèle de scoring',
                    helperText:
                        'Une copie exclusive sera créée pour la campagne',
                  ),
                  items: grids
                      .map(
                        (g) =>
                            DropdownMenuItem(value: g.id, child: Text(g.name)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() {
                    _scoringGridId = v;
                    _gridManuallySet = true;
                  }),
                );
              },
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
