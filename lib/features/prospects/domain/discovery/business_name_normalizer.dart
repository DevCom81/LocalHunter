/// Normalisation prudente des noms d'entreprises (FR) — Phase 12.
abstract final class BusinessNameNormalizer {
  static const _legalForms = <String>{
    'sarl',
    'sas',
    'sasu',
    'eurl',
    'sci',
    'sa',
    'snc',
    'scs',
    'sca',
    'selarl',
    'selas',
    'selafa',
    'scop',
    'gie',
    'earl',
    'ei',
    'eirl',
    'auto entrepreneur',
    'auto-entrepreneur',
    'micro entreprise',
    'micro-entreprise',
  };

  /// Minuscules, sans accents, ponctuation → espaces, formes juridiques retirées.
  static String normalize(String raw) {
    var s = raw.toLowerCase().trim();
    s = _stripAccents(s);
    s = s.replaceAll(RegExp(r"[^\w\s]"), ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    final tokens = s.split(' ').where((t) => t.isNotEmpty).toList();
    final filtered = tokens.where((t) => !_legalForms.contains(t)).toList();
    return filtered.isEmpty ? s : filtered.join(' ');
  }

  /// Similarité simple 0–1 (Jaccard sur tokens) — pas de fuzzy agressif.
  static double tokenOverlap(String a, String b) {
    final ta = normalize(a).split(' ').where((t) => t.length > 1).toSet();
    final tb = normalize(b).split(' ').where((t) => t.length > 1).toSet();
    if (ta.isEmpty || tb.isEmpty) return 0;
    final inter = ta.intersection(tb).length;
    final union = ta.union(tb).length;
    return inter / union;
  }

  static String _stripAccents(String s) {
    const map = {
      'à': 'a',
      'â': 'a',
      'ä': 'a',
      'á': 'a',
      'ã': 'a',
      'ç': 'c',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'î': 'i',
      'ï': 'i',
      'í': 'i',
      'ô': 'o',
      'ö': 'o',
      'ó': 'o',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ú': 'u',
      'ÿ': 'y',
      'ñ': 'n',
    };
    final buf = StringBuffer();
    for (final r in s.runes) {
      final ch = String.fromCharCode(r);
      buf.write(map[ch] ?? ch);
    }
    return buf.toString();
  }
}
