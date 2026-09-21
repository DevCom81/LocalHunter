import '../../domain/entities/prospecting_profile.dart';
import '../../domain/services/scoring_grid_generator.dart';
import '../grids/metier_grid_catalog.dart';
import 'supabase_grid_generation_service.dart';

/// Générateur de grille :
/// - avec [prospectingProfile] validé → IA/cache (pas de catalogue) ;
/// - sans profil + catalogue match → catalogue local ;
/// - sinon → Edge (cache métier ou IA).
class DefaultScoringGridGenerator implements ScoringGridGenerator {
  DefaultScoringGridGenerator({SupabaseGridGenerationService? remote})
      : _remote = remote;

  final SupabaseGridGenerationService? _remote;

  @override
  Future<GeneratedGridResult> generate({
    required String business,
    required String userId,
    String productsServices = '',
    Map<String, dynamic>? commercialProfile,
    ProspectingProfile? prospectingProfile,
  }) async {
    final offerLabel = prospectingProfile?.offer.trim().isNotEmpty == true
        ? prospectingProfile!.offer
        : (commercialProfile?['offer'] as String?)?.trim().isNotEmpty == true
            ? commercialProfile!['offer'] as String
            : (productsServices.isNotEmpty ? productsServices : business);

    // Phase 5 : profil validé → toujours la voie personnalisée (pas catalogue).
    if (prospectingProfile == null && commercialProfile == null) {
      final local = MetierGridCatalog.match(business, userId: userId);
      if (local != null) {
        return GeneratedGridResult(
          grid: local.copyWith(
            id: '',
            isTemplate: false,
            offerLabel: offerLabel,
          ),
          source: GridGenerationSource.catalog,
        );
      }
    }

    final remote = _remote;
    if (remote == null) {
      final local = MetierGridCatalog.match(business, userId: userId);
      if (local != null) {
        return GeneratedGridResult(
          grid: local.copyWith(
            id: '',
            isTemplate: false,
            offerLabel: offerLabel,
          ),
          source: GridGenerationSource.catalog,
        );
      }
      throw StateError(
        'Métier inconnu du catalogue. La génération IA nécessite Supabase '
        '(indisponible en mode démo).',
      );
    }

    final result = await remote.generate(
      business: business,
      userId: userId,
      productsServices: productsServices,
      commercialProfile: commercialProfile,
      prospectingProfile: prospectingProfile,
    );
    return GeneratedGridResult(
      grid: result.grid.copyWith(offerLabel: offerLabel),
      source: result.source,
    );
  }
}
