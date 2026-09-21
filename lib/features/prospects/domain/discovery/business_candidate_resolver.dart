import '../entities/prospect.dart';
import 'address_normalizer.dart';
import 'business_name_normalizer.dart';

/// Score de rapprochement Places ↔ SIRENE (indépendant du scoring commercial).
abstract final class MatchScoreThresholds {
  static const autoMerge = 85;
  static const probableMin = 70;

  static const siretExact = 100;
  static const sirenExact = 98;
  static const nameAndAddressClose = 95;
  static const addressExactCpCity = 85;
  static const nameExactSameCity = 75;
  static const nameCloseOnly = 50;
}

/// Fusionne les candidats Places et SIRENE en prospects uniques (Phase 12).
class BusinessCandidateResolver {
  const BusinessCandidateResolver();

  /// [places] et [sirene] peuvent être vides. Scoring commercial = après.
  List<Prospect> resolve({
    required List<Prospect> places,
    required List<Prospect> sirene,
  }) {
    if (places.isEmpty) return List.of(sirene);
    if (sirene.isEmpty) return List.of(places);

    final usedSirene = <int>{};
    final out = <Prospect>[];

    for (final p in places) {
      var bestIdx = -1;
      var bestScore = 0;
      for (var i = 0; i < sirene.length; i++) {
        if (usedSirene.contains(i)) continue;
        final score = scorePair(p, sirene[i]);
        if (score > bestScore) {
          bestScore = score;
          bestIdx = i;
        }
      }
      if (bestIdx >= 0 && bestScore >= MatchScoreThresholds.autoMerge) {
        usedSirene.add(bestIdx);
        out.add(merge(p, sirene[bestIdx], matchScore: bestScore));
      } else {
        out.add(p);
      }
    }

    for (var i = 0; i < sirene.length; i++) {
      if (!usedSirene.contains(i)) out.add(sirene[i]);
    }
    return out;
  }

  /// Score 0–100 entre un candidat Places et un candidat SIRENE.
  int scorePair(Prospect places, Prospect sirene) {
    final siretP = _digits(places.siret);
    final siretS = _digits(sirene.siret);
    if (siretP != null && siretS != null && siretP == siretS) {
      return MatchScoreThresholds.siretExact;
    }

    final sirenP = _digits(places.siren) ??
        (siretP != null && siretP.length >= 9 ? siretP.substring(0, 9) : null);
    final sirenS = _digits(sirene.siren) ??
        (siretS != null && siretS.length >= 9 ? siretS.substring(0, 9) : null);
    if (sirenP != null && sirenS != null && sirenP == sirenS) {
      return MatchScoreThresholds.sirenExact;
    }

    final nameOverlap =
        BusinessNameNormalizer.tokenOverlap(places.name, sirene.name);
    final addrSim =
        AddressNormalizer.addressSimilarity(places.address, sirene.address);
    final sameCity = AddressNormalizer.samePostalAndCity(
      addressA: places.address,
      cityA: places.city,
      addressB: sirene.address,
      cityB: sirene.city,
    );

    if (nameOverlap >= 0.6 && addrSim >= 0.75) {
      return MatchScoreThresholds.nameAndAddressClose;
    }

    if (addrSim >= 0.9 && sameCity) {
      // Adresse seule : refuser fusion auto si multi-occupants sans 2ᵉ signal.
      if (AddressNormalizer.looksMultiOccupant(places.address) ||
          AddressNormalizer.looksMultiOccupant(sirene.address)) {
        if (_hasSecondSignal(places, sirene, nameOverlap)) {
          return MatchScoreThresholds.addressExactCpCity;
        }
        return MatchScoreThresholds.probableMin; // 70 → pas de fusion auto
      }
      // Cas B : enseigne Places ≠ raison sociale SIRENE, même adresse → fusion.
      return MatchScoreThresholds.addressExactCpCity;
    }

    if (nameOverlap >= 0.85 && sameCity) {
      return MatchScoreThresholds.nameExactSameCity;
    }
    if (nameOverlap >= 0.55) {
      return MatchScoreThresholds.nameCloseOnly;
    }
    return 0;
  }

  /// Priorité Places (commercial) / SIRENE (légal & finance).
  Prospect merge(Prospect places, Prospect sirene, {required int matchScore}) {
    return Prospect(
      id: places.id.isNotEmpty ? places.id : sirene.id,
      campaignId: places.campaignId,
      name: places.name.isNotEmpty ? places.name : sirene.name,
      city: _prefer(places.city, sirene.city),
      address: _prefer(places.address, sirene.address),
      managerName: _prefer(sirene.managerName, places.managerName),
      email: _prefer(places.email, sirene.email),
      phone: _prefer(places.phone, sirene.phone),
      website: _prefer(places.website, sirene.website),
      facebookUrl: places.facebookUrl ?? sirene.facebookUrl,
      instagramUrl: places.instagramUrl ?? sirene.instagramUrl,
      googleRating: places.googleRating ?? sirene.googleRating,
      googleReviews: places.googleReviews > 0
          ? places.googleReviews
          : sirene.googleReviews,
      category: _prefer(places.category, sirene.category),
      status: places.status,
      siren: _prefer(sirene.siren, places.siren),
      siret: _prefer(sirene.siret, places.siret),
      nafCode: _prefer(sirene.nafCode, places.nafCode),
      legalForm: _prefer(sirene.legalForm, places.legalForm),
      creationDate: sirene.creationDate ?? places.creationDate,
      employeeCount: sirene.employeeCount ?? places.employeeCount,
      establishmentCount:
          sirene.establishmentCount ?? places.establishmentCount,
      annualRevenue: sirene.annualRevenue ?? places.annualRevenue,
      annualRevenueYear: sirene.annualRevenueYear ?? places.annualRevenueYear,
      netIncome: sirene.netIncome ?? places.netIncome,
      googlePlaceId: places.googlePlaceId ?? sirene.googlePlaceId,
      googleBusinessStatus:
          places.googleBusinessStatus ?? sirene.googleBusinessStatus,
      sireneMatchScore: matchScore,
      enrichmentSource: 'places+sirene',
      customFields: {
        ...sirene.customFields,
        ...places.customFields,
        'discovery_match_score': '$matchScore',
        'name_source': places.name.isNotEmpty ? 'places' : 'sirene',
        'siret_source': (sirene.siret ?? '').isNotEmpty ? 'sirene' : 'places',
      },
    );
  }

  bool _hasSecondSignal(Prospect a, Prospect b, double nameOverlap) {
    if (nameOverlap >= 0.35) return true;
    final phoneA = _digits(a.phone);
    final phoneB = _digits(b.phone);
    if (phoneA != null && phoneB != null && phoneA == phoneB) return true;
    final wa = a.website?.toLowerCase().trim();
    final wb = b.website?.toLowerCase().trim();
    if (wa != null && wb != null && wa.isNotEmpty && wa == wb) return true;
    final nafA = a.nafCode;
    final nafB = b.nafCode;
    if (nafA != null && nafB != null && nafA == nafB) return true;
    return false;
  }

  static String? _digits(String? raw) {
    if (raw == null) return null;
    final d = raw.replaceAll(RegExp(r'\D'), '');
    return d.isEmpty ? null : d;
  }

  static String? _prefer(String? primary, String? fallback) {
    if (primary != null && primary.trim().isNotEmpty) return primary;
    if (fallback != null && fallback.trim().isNotEmpty) return fallback;
    return primary ?? fallback;
  }
}
