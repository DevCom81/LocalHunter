import '../../domain/entities/prospect.dart';
import '../../domain/entities/prospect_with_score.dart';

/// Sélection BODACC (C4.2) — top N éligibles après score initial.
class BodaccSelection {
  const BodaccSelection({
    this.maxProspects = 20,
    this.minSireneMatchScore = 70,
    this.cacheTtl = const Duration(days: 30),
  });

  final int maxProspects;
  final int minSireneMatchScore;
  final Duration cacheTtl;

  /// SIREN 9 chiffres : champ dédié, sinon préfixe du SIRET.
  static String? resolveSiren(Prospect prospect) {
    final siren = prospect.siren?.replaceAll(RegExp(r'\D'), '');
    if (siren != null && siren.length == 9) return siren;
    final siret = prospect.siret?.replaceAll(RegExp(r'\D'), '');
    if (siret != null && siret.length >= 9) return siret.substring(0, 9);
    return null;
  }

  /// SIRET 14 chiffres = identifiant d’établissement ferme (bypass match flou).
  static bool hasFirmLegalId(Prospect prospect) {
    final siret = prospect.siret?.replaceAll(RegExp(r'\D'), '');
    return siret != null && siret.length == 14;
  }

  /// Éligibilité auto (manuel peut forcer via [ignoreCache]).
  bool isEligible(
    Prospect prospect, {
    bool ignoreCache = false,
    DateTime? now,
  }) {
    if (resolveSiren(prospect) == null) return false;
    if (prospect.isExcluded) return false;

    final firmId = hasFirmLegalId(prospect);
    // Score de rapprochement flou : ne bloque pas si SIREN/SIRET déjà connus
    // (ex. discovery composite / enrichissement qui baisse le match score).
    if (!firmId) {
      if (prospect.sireneMatchAmbiguous) return false;
      final match = prospect.sireneMatchScore;
      if (match != null && match < minSireneMatchScore) return false;
    }

    if (!ignoreCache && _cacheStillValid(prospect, now ?? DateTime.now())) {
      return false;
    }
    return true;
  }

  bool _cacheStillValid(Prospect p, DateTime now) {
    final fetched = p.bodaccFetchedAt;
    if (fetched == null) return false;
    return now.difference(fetched) < cacheTtl;
  }

  /// Top [maxProspects] par score global décroissant.
  List<ProspectWithScore> selectTop(
    List<ProspectWithScore> items, {
    bool ignoreCache = false,
    DateTime? now,
  }) {
    final eligible = items
        .where((i) => isEligible(i.prospect, ignoreCache: ignoreCache, now: now))
        .toList()
      ..sort((a, b) => b.score.globalScore.compareTo(a.score.globalScore));
    return eligible.take(maxProspects).toList();
  }
}
