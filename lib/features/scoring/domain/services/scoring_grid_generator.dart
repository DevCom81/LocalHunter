import '../entities/scoring_grid.dart';

/// Provenance de la grille générée.
enum GridGenerationSource {
  /// Correspondance exacte dans le catalogue métiers local (aucun réseau).
  catalog,

  /// Cache partagé Supabase (aucun appel IA).
  cache,

  /// Génération IA via OpenRouter.
  ai,
}

class GeneratedGridResult {
  const GeneratedGridResult({required this.grid, required this.source});

  final ScoringGrid grid;
  final GridGenerationSource source;
}

/// Port de génération de grille de scoring à partir du métier de
/// l'utilisateur. Implémentation remplaçable (contrainte MVP : IA optionnelle).
abstract class ScoringGridGenerator {
  Future<GeneratedGridResult> generate({
    required String business,
    required String userId,
    String productsServices,
  });
}
