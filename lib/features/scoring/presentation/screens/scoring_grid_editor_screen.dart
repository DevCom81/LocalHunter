import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/supabase_client_provider.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../prospects/data/demo/demo_data.dart';
import '../../data/grids/default_scoring_grids.dart';
import '../../domain/entities/scoring_grid.dart';
import '../providers/scoring_providers.dart';
import '../widgets/scoring_grid_editor_body.dart';

class ScoringGridEditorScreen extends ConsumerStatefulWidget {
  const ScoringGridEditorScreen({
    super.key,
    this.gridId,
    this.duplicateFromId,
    this.initialGrid,
    this.isNew = false,
  });

  final String? gridId;
  final String? duplicateFromId;

  /// Grille pré-remplie (catalogue métier ou génération IA), non persistée.
  final ScoringGrid? initialGrid;
  final bool isNew;

  @override
  ConsumerState<ScoringGridEditorScreen> createState() =>
      _ScoringGridEditorScreenState();
}

class _ScoringGridEditorScreenState extends ConsumerState<ScoringGridEditorScreen> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    if (widget.isNew) {
      if (widget.initialGrid != null) {
        return _buildEditor(widget.initialGrid!);
      }
      if (widget.duplicateFromId != null) {
        final sourceAsync =
            ref.watch(scoringGridByIdProvider(widget.duplicateFromId!));
        return sourceAsync.when(
          loading: () => const AppScaffold(
            title: 'Nouvelle grille',
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => AppScaffold(title: 'Nouvelle grille', body: Text('$e')),
          data: (source) {
            if (source == null) {
              return const AppScaffold(
                title: 'Nouvelle grille',
                body: Center(child: Text('Modèle introuvable')),
              );
            }
            final userId = ref.watch(currentUserProvider)?.id ?? DemoData.userId;
            return _buildEditor(
              DefaultScoringGrids.duplicateFrom(source, userId: userId),
            );
          },
        );
      }
      final userId = ref.watch(currentUserProvider)?.id ?? DemoData.userId;
      return _buildEditor(DefaultScoringGrids.blank(userId: userId));
    }

    final gridAsync = ref.watch(scoringGridByIdProvider(widget.gridId!));
    return gridAsync.when(
      loading: () => const AppScaffold(
        title: 'Scoring',
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => AppScaffold(title: 'Scoring', body: Text('$e')),
      data: (grid) {
        if (grid == null) {
          return const AppScaffold(
            title: 'Scoring',
            body: Center(child: Text('Grille introuvable')),
          );
        }
        return _buildEditor(grid);
      },
    );
  }

  Widget _buildEditor(ScoringGrid grid) {
    return ScoringGridEditorBody(
      grid: grid,
      saving: _saving,
      onSave: _save,
      onDelete: () => _delete(grid),
      onDuplicate: () =>
          context.go('${RouteNames.scoringCreate}?duplicate=${grid.id}'),
      onOpenSuggestions: widget.isNew || widget.gridId == null
          ? null
          : () => context.push(
                RouteNames.scoringGridSuggestions(widget.gridId!),
              ),
    );
  }

  Future<void> _save(ScoringGrid grid) async {
    setState(() => _saving = true);
    try {
      final saved = await ref.read(scoringGridRepositoryProvider).save(grid);
      ref.invalidate(scoringGridsProvider);
      if (widget.gridId != null) {
        ref.invalidate(scoringGridByIdProvider(widget.gridId!));
      }
      await ref.read(rescoreCampaignsForGridProvider(saved.id).future);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Grille enregistrée — prospects re-scorés')),
        );
        // Retour à la liste des grilles après validation.
        context.go(RouteNames.scoring);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(ScoringGrid grid) async {
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
    if (ok != true || !mounted) return;
    await ref.read(scoringGridRepositoryProvider).delete(grid.id);
    ref.invalidate(scoringGridsProvider);
    if (mounted) context.go(RouteNames.scoring);
  }
}
