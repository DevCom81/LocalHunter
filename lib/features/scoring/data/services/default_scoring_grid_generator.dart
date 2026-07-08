import '../../domain/services/scoring_grid_generator.dart';
import '../grids/metier_grid_catalog.dart';
import 'supabase_grid_generation_service.dart';

/// Générateur de grille en 3 niveaux :
/// 1. catalogue métiers local (zéro réseau) ;
/// 2. cache partagé Supabase (via l'Edge Function, zéro appel IA) ;
/// 3. génération OpenRouter (via la même Edge Function).
///
/// En mode démo ([remote] absent), seul le catalogue est disponible.
class DefaultScoringGridGenerator implements ScoringGridGenerator {
  DefaultScoringGridGenerator({SupabaseGridGenerationService? remote})
      : _remote = remote;

  final SupabaseGridGenerationService? _remote;

  @override
  Future<GeneratedGridResult> generate({
    required String business,
    required String userId,
    String productsServices = '',
  }) async {
    // L'offre promue vient de la saisie utilisateur (produits/services,
    // sinon métier), quelle que soit la source de la grille.
    final offerLabel =
        productsServices.isNotEmpty ? productsServices : business;

    final local = MetierGridCatalog.match(business, userId: userId);
    if (local != null) {
      // Grille catalogue : dupliquée sans id ni statut modèle pour que
      // l'utilisateur l'édite et l'enregistre comme grille personnelle.
      return GeneratedGridResult(
        grid: local.copyWith(
          id: '',
          isTemplate: false,
          offerLabel: offerLabel,
        ),
        source: GridGenerationSource.catalog,
      );
    }

    final remote = _remote;
    if (remote == null) {
      throw StateError(
        'Métier inconnu du catalogue. La génération IA nécessite Supabase '
        '(indisponible en mode démo).',
      );
    }
    final result = await remote.generate(
      business: business,
      userId: userId,
      productsServices: productsServices,
    );
    return GeneratedGridResult(
      grid: result.grid.copyWith(offerLabel: offerLabel),
      source: result.source,
    );
  }
}
