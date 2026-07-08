import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/supabase_client_provider.dart';
import '../../../../core/routing/route_names.dart';
import '../../../prospects/data/demo/demo_data.dart';
import '../../data/grids/metier_grid_catalog.dart';

/// Liste des grilles métiers pré-remplies du catalogue.
/// La sélection ouvre l'éditeur pré-rempli (aucune sauvegarde automatique).
class MetierCatalogSheet extends ConsumerWidget {
  const MetierCatalogSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const MetierCatalogSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserProvider)?.id ?? DemoData.userId;
    final grids = MetierGridCatalog.allGrids(userId: userId);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Grilles métiers pré-remplies',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: grids.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final grid = grids[i];
                  return ListTile(
                    title: Text(grid.name),
                    subtitle: Text(
                      grid.description.isNotEmpty
                          ? grid.description
                          : '${grid.criteria.length} critères',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go(
                        RouteNames.scoringCreate,
                        extra: grid.copyWith(id: '', isTemplate: false),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
