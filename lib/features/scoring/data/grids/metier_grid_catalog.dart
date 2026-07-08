import '../../domain/entities/scoring_grid.dart';
import 'default_scoring_grids.dart';
import 'metier_grid_builder.dart';
import 'metier_specs_commerce.dart';
import 'metier_specs_services.dart';

/// Catalogue statique de grilles métiers pré-remplies.
/// Consulté avant tout appel réseau : si le métier saisi correspond à un
/// alias connu, la grille est instanciée localement (zéro requête IA).
class MetierGridCatalog {
  /// Alias du métier "développeur web / agence web", couvert par la grille
  /// historique LocalHunter Default plutôt que par une spec du catalogue.
  static const _webDevAliases = [
    'developpeur web',
    'developpeur',
    'agence web',
    'createur de sites',
    'webdesigner',
    'freelance web',
  ];

  static List<MetierGridSpec> get allSpecs => [
        ...metierSpecsServices,
        ...metierSpecsCommerce,
      ];

  /// Toutes les grilles du catalogue, instanciées pour [userId].
  /// Inclut la grille "développeur web" (LocalHunter Default).
  static List<ScoringGrid> allGrids({String userId = ''}) => [
        DefaultScoringGrids.localHunterDefault(userId: userId),
        ...allSpecs.map((s) => buildMetierGrid(s, userId: userId)),
      ];

  /// Cherche une grille correspondant au métier saisi (correspondance sur
  /// les alias normalisés). Retourne null si aucun métier ne correspond.
  static ScoringGrid? match(String business, {String userId = ''}) {
    final normalized = normalizeBusiness(business);
    if (normalized.isEmpty) return null;

    if (_matchesAny(normalized, _webDevAliases)) {
      return DefaultScoringGrids.localHunterDefault(userId: userId);
    }
    for (final spec in allSpecs) {
      if (_matchesAny(normalized, spec.aliases)) {
        return buildMetierGrid(spec, userId: userId);
      }
    }
    return null;
  }

  static bool _matchesAny(String normalized, List<String> aliases) {
    return aliases.any(
      (alias) => normalized == alias || normalized.contains(alias),
    );
  }
}

/// Normalisation identique à celle de l'Edge Function :
/// minuscules, sans accents, espaces réduits.
String normalizeBusiness(String raw) {
  var s = raw.toLowerCase().trim();
  const accents = {
    'à': 'a', 'â': 'a', 'ä': 'a',
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
    'î': 'i', 'ï': 'i',
    'ô': 'o', 'ö': 'o',
    'ù': 'u', 'û': 'u', 'ü': 'u',
    'ç': 'c',
    '’': '\'',
  };
  accents.forEach((from, to) => s = s.replaceAll(from, to));
  return s.replaceAll(RegExp(r'\s+'), ' ');
}
