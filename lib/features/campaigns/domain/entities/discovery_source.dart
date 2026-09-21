/// Source de découverte campagne (Phase 9 + 12).
///
/// BODACC n'est pas une source : enrichissement manuel / différé.
enum DiscoverySource {
  /// Places + SIRENE, rapprochement avant scoring (défaut Phase 12).
  combined('combined'),
  places('places'),
  sirene('sirene');

  const DiscoverySource(this.dbValue);
  final String dbValue;

  static DiscoverySource fromDb(String? raw) {
    switch (raw) {
      case 'sirene':
        return DiscoverySource.sirene;
      case 'places':
        return DiscoverySource.places;
      case 'combined':
      default:
        // Défaut combined pour null / valeurs inconnues sur nouvelles lectures
        // si la colonne a le DEFAULT combined ; anciennes lignes 'places' restent.
        if (raw == null || raw.isEmpty) return DiscoverySource.combined;
        return DiscoverySource.combined;
    }
  }

  String get label {
    switch (this) {
      case DiscoverySource.combined:
        return 'Places + SIRENE';
      case DiscoverySource.places:
        return 'Google Places';
      case DiscoverySource.sirene:
        return 'SIRENE (registre)';
    }
  }
}
