import 'package:flutter_test/flutter_test.dart';

import 'package:localhunter/features/prospects/domain/discovery/business_candidate_resolver.dart';
import 'package:localhunter/features/prospects/domain/entities/prospect.dart';

Prospect _p({
  required String id,
  required String name,
  String? address,
  String? city,
  String? phone,
  String? website,
  String? siret,
  String? siren,
  String? naf,
  double? rating,
  int reviews = 0,
}) {
  return Prospect(
    id: id,
    campaignId: 'c',
    name: name,
    address: address,
    city: city,
    phone: phone,
    website: website,
    siret: siret,
    siren: siren,
    nafCode: naf,
    googleRating: rating,
    googleReviews: reviews,
  );
}

void main() {
  const resolver = BusinessCandidateResolver();

  group('Phase 12 — rapprochement A–E', () {
    test('A même nom + même adresse → fusion auto', () {
      final places = _p(
        id: 'pl',
        name: 'Boulangerie Dupont',
        address: '12 rue des Carmes 81000 Albi',
        city: 'Albi',
        rating: 4.5,
        reviews: 20,
      );
      final sirene = _p(
        id: 'si',
        name: 'BOULANGERIE DUPONT',
        address: '12 RUE DES CARMES 81000 ALBI',
        city: 'Albi',
        siret: '12345678900012',
        siren: '123456789',
      );
      final score = resolver.scorePair(places, sirene);
      expect(score, greaterThanOrEqualTo(MatchScoreThresholds.autoMerge));
      final merged = resolver.resolve(places: [places], sirene: [sirene]);
      expect(merged.length, 1);
      expect(merged.first.name, 'Boulangerie Dupont');
      expect(merged.first.siret, '12345678900012');
      expect(merged.first.googleRating, 4.5);
    });

    test('B enseigne ≠ raison sociale + même adresse → fusion', () {
      final places = _p(
        id: 'pl',
        name: 'Le Bistrot de Jean',
        address: '12 rue des Carmes 81000 Albi',
        city: 'Albi',
        phone: '0563540000',
        rating: 4.2,
      );
      final sirene = _p(
        id: 'si',
        name: 'DUPONT RESTAURATION SARL',
        address: '12 RUE DES CARMES 81000 ALBI',
        city: 'Albi',
        siret: '98765432100011',
        naf: '5610A',
      );
      final score = resolver.scorePair(places, sirene);
      expect(score, MatchScoreThresholds.addressExactCpCity);
      final merged = resolver.resolve(places: [places], sirene: [sirene]);
      expect(merged.length, 1);
      expect(merged.first.name, 'Le Bistrot de Jean');
      expect(merged.first.siret, '98765432100011');
      expect(merged.first.nafCode, '5610A');
      expect(merged.first.enrichmentSource, 'places+sirene');
    });

    test('C même adresse multi-occupants + noms différents → pas de fusion', () {
      final places = _p(
        id: 'pl',
        name: 'Cabinet Alpha',
        address: 'Tour Espace 5 avenue du Coworking 81000 Albi',
        city: 'Albi',
      );
      final sirene = _p(
        id: 'si',
        name: 'BETA CONSEIL SAS',
        address: 'TOUR ESPACE 5 AVENUE DU COWORKING 81000 ALBI',
        city: 'Albi',
        siret: '11122233300044',
      );
      final score = resolver.scorePair(places, sirene);
      expect(score, lessThan(MatchScoreThresholds.autoMerge));
      final merged = resolver.resolve(places: [places], sirene: [sirene]);
      expect(merged.length, 2);
    });

    test('D noms proches adresses différentes → pas de fusion', () {
      final places = _p(
        id: 'pl',
        name: 'Garage Martin',
        address: '10 rue de la République 81000 Albi',
        city: 'Albi',
      );
      final sirene = _p(
        id: 'si',
        name: 'GARAGE MARTIN AUTO',
        address: '88 avenue Gambetta 81000 Albi',
        city: 'Albi',
        siret: '55566677700088',
      );
      final score = resolver.scorePair(places, sirene);
      expect(score, lessThan(MatchScoreThresholds.autoMerge));
      final merged = resolver.resolve(places: [places], sirene: [sirene]);
      expect(merged.length, 2);
    });

    test('E SIRET exact → fusion certaine', () {
      final places = _p(
        id: 'pl',
        name: 'Chez Paul',
        address: '1 place du Marché 31000 Toulouse',
        city: 'Toulouse',
        siret: '12345678900012',
      );
      final sirene = _p(
        id: 'si',
        name: 'PAUL TRAITEUR SASU',
        address: 'Autre adresse 31000 Toulouse',
        city: 'Toulouse',
        siret: '123 456 789 00012',
      );
      expect(resolver.scorePair(places, sirene), MatchScoreThresholds.siretExact);
      final merged = resolver.resolve(places: [places], sirene: [sirene]);
      expect(merged.length, 1);
    });
  });
}
