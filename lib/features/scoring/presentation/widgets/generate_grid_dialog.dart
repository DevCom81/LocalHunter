import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../domain/services/scoring_grid_generator.dart';
import '../providers/grid_generation_providers.dart';

/// Dialogue de génération d'une grille à partir du métier de l'utilisateur.
/// Résolution : catalogue local → cache partagé → IA (OpenRouter).
/// La grille obtenue pré-remplit l'éditeur ; rien n'est enregistré
/// avant validation manuelle.
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

  @override
  void dispose() {
    _businessController.dispose();
    _servicesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Générer une grille'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _businessController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Votre métier *',
                hintText: 'Ex. : assureur, cuisiniste, expert-comptable…',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _servicesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Vos produits et services (optionnel)',
                hintText: 'Ex. : assurance multirisque pro, prévoyance TNS…',
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
          onPressed: _loading ? null : _generate,
          icon: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_awesome, size: 18),
          label: const Text('Générer'),
        ),
      ],
    );
  }

  Future<void> _generate() async {
    final business = _businessController.text.trim();
    if (business.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indiquez votre métier (3 caractères min.)')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await ref.read(gridGenerationProvider.notifier).generate(
            business: business,
            productsServices: _servicesController.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_sourceMessage(result.source))),
      );
      context.go(RouteNames.scoringCreate, extra: result.grid);
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Génération impossible : $e')),
        );
      }
    }
  }

  String _sourceMessage(GridGenerationSource source) {
    return switch (source) {
      GridGenerationSource.catalog =>
        'Grille issue du catalogue métiers — vérifiez puis enregistrez',
      GridGenerationSource.cache =>
        'Grille issue du cache partagé — vérifiez puis enregistrez',
      GridGenerationSource.ai =>
        'Grille générée par IA — vérifiez puis enregistrez',
    };
  }
}
