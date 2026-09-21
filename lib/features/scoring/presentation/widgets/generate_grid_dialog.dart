import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../commercial_profile/presentation/providers/commercial_profile_providers.dart';
import '../../domain/entities/prospecting_profile.dart';
import '../../domain/services/scoring_grid_generator.dart';
import '../providers/grid_generation_providers.dart';
import '../providers/pending_target_profile_provider.dart';
import 'prospecting_profile_review_dialog.dart';

/// Génération Phase 5 : métier → profil de prospection → validation → grille.
/// Mode démo / sans remote : catalogue métiers (inchangé).
class GenerateGridDialog extends ConsumerStatefulWidget {
  const GenerateGridDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const GenerateGridDialog(),
    );
  }

  @override
  ConsumerState<GenerateGridDialog> createState() => _GenerateGridDialogState();
}

class _GenerateGridDialogState extends ConsumerState<GenerateGridDialog> {
  final _businessController = TextEditingController();
  final _servicesController = TextEditingController();
  bool _loading = false;
  bool _prefilled = false;

  @override
  void dispose() {
    _businessController.dispose();
    _servicesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(commercialProfileProvider);
    final profile = profileAsync.valueOrNull;
    if (profile != null && !_prefilled) {
      _prefilled = true;
      if (profile.activity.isNotEmpty) {
        _businessController.text = profile.activity;
      }
      if (profile.offer.isNotEmpty) {
        _servicesController.text = profile.offer;
      }
    }

    final hasRemote = ref.watch(gridGenerationRemoteProvider) != null;

    return AlertDialog(
      title: const Text('Nouvelle grille'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              hasRemote
                  ? 'LocalHunter proposera d\'abord un profil de prospection '
                      'à valider, puis construira la grille.'
                  : 'Mode démo : grille issue du catalogue métiers local.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _businessController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Votre métier *',
                hintText: 'Ex. : frigoriste, flottes auto, expert-comptable…',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _servicesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Que leur proposez-vous ?',
                hintText: 'Ex. : contrats de maintenance froid commercial…',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton.icon(
          onPressed: _loading ? null : _start,
          icon: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_awesome, size: 18),
          label: Text(hasRemote ? 'Comprendre ma cible' : 'Générer'),
        ),
      ],
    );
  }

  Future<void> _start() async {
    final business = _businessController.text.trim();
    if (business.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Indiquez votre métier (3 caractères min.)'),
        ),
      );
      return;
    }

    final products = _servicesController.text.trim();
    final remote = ref.read(gridGenerationRemoteProvider);

    setState(() => _loading = true);
    try {
      if (remote == null) {
        await _generateGrid(business, products, prospecting: null);
        return;
      }

      final proposed = await ref
          .read(gridGenerationProvider.notifier)
          .proposeProfile(business: business, productsServices: products);
      if (!mounted) return;
      setState(() => _loading = false);

      final validated = await ProspectingProfileReviewDialog.show(
        context,
        proposed,
      );
      if (validated == null || !mounted) return;

      ref.read(pendingCampaignTargetProfileProvider.notifier).state =
          validated.toCampaignTargetProfile();

      setState(() => _loading = true);
      await _generateGrid(business, products, prospecting: validated);
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible : $e')),
        );
      }
    }
  }

  Future<void> _generateGrid(
    String business,
    String products, {
    required ProspectingProfile? prospecting,
  }) async {
    final commercial = await ref.read(commercialProfileProvider.future);
    final result = await ref.read(gridGenerationProvider.notifier).generate(
          business: business,
          productsServices: products,
          commercialProfile:
              prospecting == null ? commercial.toEdgePayload() : null,
          prospectingProfile: prospecting,
        );
    if (!mounted) return;
    // Capturer router/messenger AVANT pop : après fermeture du dialogue,
    // le context local est disposé et context.go est silencieusement perdu.
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final msg = _sourceMessage(result.source);
    final grid = result.grid;
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(content: Text(msg)));
    router.go(RouteNames.scoringCreate, extra: grid);
  }

  String _sourceMessage(GridGenerationSource source) {
    return switch (source) {
      GridGenerationSource.catalog =>
        'Grille catalogue — vérifiez puis enregistrez',
      GridGenerationSource.cache =>
        'Grille cache — vérifiez puis enregistrez',
      GridGenerationSource.ai =>
        'Grille IA à partir de votre profil — vérifiez puis enregistrez',
    };
  }
}
