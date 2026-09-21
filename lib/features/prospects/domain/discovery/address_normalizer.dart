import 'business_name_normalizer.dart';

/// Normalisation d'adresses FR (prudente) — Phase 12.
abstract final class AddressNormalizer {
  static const _streetAliases = <String, String>{
    'av': 'avenue',
    'ave': 'avenue',
    'avenue': 'avenue',
    'bd': 'boulevard',
    'bld': 'boulevard',
    'boulevard': 'boulevard',
    'r': 'rue',
    'rue': 'rue',
    'rte': 'route',
    'route': 'route',
    'ch': 'chemin',
    'chemin': 'chemin',
    'imp': 'impasse',
    'impasse': 'impasse',
    'pl': 'place',
    'place': 'place',
    'all': 'allee',
    'allee': 'allee',
    'allée': 'allee',
    'crs': 'cours',
    'cours': 'cours',
  };

  /// Indices d'adresse multi-occupants (ne pas fusionner sur adresse seule).
  static const multiOccupantHints = <String>[
    'centre commercial',
    'centre-commercial',
    'cc ',
    'immeuble',
    'tour ',
    'pepiniere',
    'pépinière',
    'coworking',
    'co-working',
    'incubateur',
    'zac ',
    'zone artisanale',
    'zone industrielle',
    'parc d activite',
    'parc d\'activite',
    'bureau partage',
    'bureaux partages',
    'cabinet partage',
  ];

  static String normalize(String raw) {
    var s = BusinessNameNormalizer.normalize(raw);
    final tokens = s.split(' ');
    final out = <String>[];
    for (final t in tokens) {
      out.add(_streetAliases[t] ?? t);
    }
    return out.join(' ');
  }

  static String? postalCode(String? address) {
    if (address == null) return null;
    final m = RegExp(r'\b(\d{5})\b').firstMatch(address);
    return m?.group(1);
  }

  static String? streetNumber(String? address) {
    if (address == null) return null;
    final m = RegExp(r'^\s*(\d+\s*[a-zA-Z]?)').firstMatch(address.trim());
    if (m != null) return m.group(1)!.replaceAll(' ', '').toLowerCase();
    final n = RegExp(r'\b(\d+\s*[a-zA-Z]?)\b').firstMatch(address);
    return n?.group(1)?.replaceAll(' ', '').toLowerCase();
  }

  static bool samePostalAndCity({
    required String? addressA,
    required String? cityA,
    required String? addressB,
    required String? cityB,
  }) {
    final cpA = postalCode(addressA);
    final cpB = postalCode(addressB);
    if (cpA == null || cpB == null || cpA != cpB) return false;
    final cA = BusinessNameNormalizer.normalize(cityA ?? '');
    final cB = BusinessNameNormalizer.normalize(cityB ?? '');
    if (cA.isEmpty || cB.isEmpty) return cpA == cpB;
    return cA == cB || cA.contains(cB) || cB.contains(cA);
  }

  /// Adresse « très proche » : même CP, même n° si dispo, overlap tokens voie.
  static double addressSimilarity(String? a, String? b) {
    if (a == null || b == null || a.isEmpty || b.isEmpty) return 0;
    final na = normalize(a);
    final nb = normalize(b);
    if (na == nb) return 1;
    final cpA = postalCode(a);
    final cpB = postalCode(b);
    if (cpA != null && cpB != null && cpA != cpB) return 0;
    final numA = streetNumber(a);
    final numB = streetNumber(b);
    if (numA != null && numB != null && numA != numB) return 0.15;
    return BusinessNameNormalizer.tokenOverlap(na, nb);
  }

  static bool looksMultiOccupant(String? address) {
    if (address == null) return false;
    final n = BusinessNameNormalizer.normalize(address);
    return multiOccupantHints.any(n.contains);
  }
}
