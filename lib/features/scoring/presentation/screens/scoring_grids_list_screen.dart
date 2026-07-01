import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../domain/entities/scoring_grid.dart';
import '../providers/scoring_providers.dart';

class ScoringGridsListScreen extends ConsumerWidget {
  const ScoringGridsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gridsAsync = ref.watch(scoringGridsProvider);

    return AppScaffold(
      title: 'Scoring',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateMenu(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle grille'),
      ),
      body: gridsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (grids) {
          if (grids.isEmpty) {
            return const EmptyState(
              message: 'Aucune grille. Créez-en une pour vos campagnes.',
              icon: Icons.grid_view_outlined,
            );
          }
          return ListView.separated(
            itemCount: grids.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, i) => _GridListTile(grid: grids[i]),
          );
        },
      ),
    );
  }

  void _showCreateMenu(BuildContext context, WidgetRef ref) {
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
          ],
        ),
      ),
    );
  }

  void _pickTemplate(BuildContext context, WidgetRef ref) {
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

class _GridListTile extends ConsumerWidget {
  const _GridListTile({required this.grid});

  final ScoringGrid grid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: Text(grid.name),
      subtitle: Text(
        grid.description.isNotEmpty
            ? grid.description
            : '${grid.criteria.length} critères · ${grid.totalMax} pts composants',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (action) => _handleAction(context, ref, action),
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'edit', child: Text('Modifier')),
          PopupMenuItem(value: 'duplicate', child: Text('Dupliquer')),
          PopupMenuItem(value: 'delete', child: Text('Supprimer')),
        ],
        child: grid.isTemplate
            ? const Chip(label: Text('Modèle'))
            : const Icon(Icons.more_vert),
      ),
      onTap: () => context.go(RouteNames.scoringGridEdit(grid.id)),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    String action,
  ) async {
    switch (action) {
      case 'edit':
        context.go(RouteNames.scoringGridEdit(grid.id));
      case 'duplicate':
        context.go('${RouteNames.scoringCreate}?duplicate=${grid.id}');
      case 'delete':
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Supprimer la grille ?'),
            content: Text('« ${grid.name} » sera définitivement supprimée.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Supprimer'),
              ),
            ],
          ),
        );
        if (ok != true || !context.mounted) return;
        try {
          await ref.read(scoringGridRepositoryProvider).delete(grid.id);
          ref.invalidate(scoringGridsProvider);
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Grille supprimée')));
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('$e')));
          }
        }
    }
  }
}
