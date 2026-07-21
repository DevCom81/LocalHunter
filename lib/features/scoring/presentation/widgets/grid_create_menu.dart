import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../subscription/domain/entities/subscription_tier.dart';
import '../../../subscription/presentation/providers/subscription_providers.dart';
import '../providers/scoring_providers.dart';
import 'generate_grid_dialog.dart';
import 'metier_catalog_sheet.dart';

/// Menu de création d'une grille (vierge, duplication, catalogue, IA).
/// Applique le quota freemium avant d'ouvrir le menu.
abstract final class GridCreateMenu {
  static Future<void> show(BuildContext context, WidgetRef ref) async {
    // Attendre le tier réel : une lecture synchrone pendant le chargement
    // afficherait à tort le message freemium à un compte premium.
    final tier = await resolveTier(ref);
    final maxGrids = tier.limits.maxGrids;
    if (maxGrids != null) {
      final gridCount =
          (await ref.read(scoringGridsProvider.future)).length;
      if (gridCount >= maxGrids) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            showCloseIcon: true,
            content: Text(
              'Quota atteint (${maxGrids} grille${maxGrids > 1 ? 's' : ''} '
              'de scoring max). ${PlanLimits.upgradeMessage}',
            ),
            action: SnackBarAction(
              label: 'Abonnement',
              onPressed: () => context.go(RouteNames.subscription),
            ),
          ),
        );
        return;
      }
    }
    if (!context.mounted) return;
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.note_add_outlined),
              title: const Text('Grille vierge'),
              subtitle: const Text('Partir de zéro avec vos propres critères'),
              onTap: () {
                Navigator.pop(ctx);
                context.go(RouteNames.scoringCreate);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const Text('Dupliquer un modèle'),
              subtitle: const Text(
                'Copier une grille existante puis personnaliser',
              ),
              onTap: () {
                Navigator.pop(ctx);
                _pickTemplate(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.work_outline),
              title: const Text('Grille métier pré-remplie'),
              subtitle: const Text(
                'Choisir parmi 20 métiers du catalogue',
              ),
              onTap: () {
                Navigator.pop(ctx);
                MetierCatalogSheet.show(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome_outlined),
              title: const Text('Générer par IA'),
              subtitle: const Text(
                'Décrire votre métier, l\'IA propose une grille',
              ),
              onTap: () {
                Navigator.pop(ctx);
                GenerateGridDialog.show(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  static void _pickTemplate(BuildContext context, WidgetRef ref) {
    final grids = ref.read(scoringGridsProvider).valueOrNull;
    if (grids == null || grids.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: grids
              .map(
                (g) => ListTile(
                  title: Text(g.name),
                  subtitle: Text(
                    g.isTemplate
                        ? 'Modèle · ${g.totalMax} pts'
                        : '${g.totalMax} pts',
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go('${RouteNames.scoringCreate}?duplicate=${g.id}');
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
