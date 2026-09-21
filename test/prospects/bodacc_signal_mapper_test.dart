import 'package:flutter_test/flutter_test.dart';
import 'package:localhunter/features/prospects/domain/services/bodacc_signal_mapper.dart';

void main() {
  const mapper = BodaccSignalMapper();
  final now = DateTime(2026, 8, 5);

  BodaccRawEvent event({
    required String id,
    String? date,
    String? famille,
    String? familleLib,
    String? typeLib,
    List<String> registre = const ['552081317'],
    bool radiation = false,
    bool depot = false,
    String mods = '',
    String jugement = '',
  }) {
    return BodaccRawEvent(
      id: id,
      dateParution: date,
      familleAvis: famille,
      familleAvisLib: familleLib,
      typeAvisLib: typeLib,
      registre: registre,
      hasRadiationField: radiation,
      hasDepotField: depot,
      modificationsText: mods,
      jugementText: jugement,
    );
  }

  group('C4.1 — BodaccSignalMapper', () {
    test('normalizeSiren retire les espaces', () {
      expect(BodaccSignalMapper.normalizeSiren('552 081 317'), '552081317');
      expect(BodaccSignalMapper.normalizeSiren('123'), isNull);
    });

    test('ignore les annonces d\'un autre SIREN', () {
      final signals = mapper.derive(
        records: [
          event(id: 'A', date: '2025-01-01', registre: ['111111111'], famille: 'creation'),
        ],
        siren: '552081317',
        now: now,
      );
      expect(signals.noResults, isTrue);
      expect(signals.hasCreation, isFalse);
    });

    test('modification administration → manager_change', () {
      final signals = mapper.derive(
        records: [
          event(
            id: 'B202600732596',
            date: '2026-04-16',
            famille: 'modification',
            familleLib: 'Modifications diverses',
            typeLib: 'Avis initial',
            mods: 'modification survenue sur l\'administration',
          ),
        ],
        siren: '552081317',
        now: now,
      );
      expect(signals.noResults, isFalse);
      expect(signals.hasManagerChange, isTrue);
      expect(signals.hasModification, isFalse);
    });

    test('événements hors lookback 5 ans n\'activent pas les flags', () {
      final signals = mapper.derive(
        records: [
          event(
            id: 'OLD',
            date: '2018-01-01',
            famille: 'creation',
            familleLib: 'Créations',
          ),
        ],
        siren: '552081317',
        now: now,
      );
      expect(signals.noResults, isFalse);
      expect(signals.hasCreation, isFalse);
      expect(signals.lastEventAt, '2018-01-01');
    });

    test('absence de résultats → noResults, aucun flag positif', () {
      final signals = mapper.derive(
        records: const [],
        siren: '552081317',
        now: now,
      );
      expect(signals.noResults, isTrue);
      expect(signals.hasSale, isFalse);
      expect(signals.hasCollectiveProceeding, isFalse);
      expect(signals.radiationStatus, BodaccRadiationStatus.none);
    });

    test('radiation + SIRENE inactif → excluded', () {
      final signals = mapper.derive(
        records: [
          event(
            id: 'RAD',
            date: '2025-06-01',
            famille: 'radiation',
            familleLib: 'Radiations',
            radiation: true,
          ),
        ],
        siren: '552081317',
        sireneActive: false,
        now: now,
      );
      expect(signals.hasRadiation, isTrue);
      expect(signals.radiationStatus, BodaccRadiationStatus.excluded);
    });

    test('radiation sans concordance SIRENE → review', () {
      final signals = mapper.derive(
        records: [
          event(
            id: 'RAD',
            date: '2025-06-01',
            famille: 'radiation',
            familleLib: 'Radiations',
            radiation: true,
          ),
        ],
        siren: '552081317',
        sireneActive: true,
        now: now,
      );
      expect(signals.radiationStatus, BodaccRadiationStatus.review);
    });

    test('avis rectificatif radiation → pas excluded', () {
      final signals = mapper.derive(
        records: [
          event(
            id: 'RAD-R',
            date: '2025-06-01',
            famille: 'radiation',
            typeLib: 'Avis rectificatif',
            radiation: true,
          ),
        ],
        siren: '552081317',
        sireneActive: false,
        now: now,
      );
      expect(signals.radiationStatus, BodaccRadiationStatus.none);
    });

    test('procédure collective mappée', () {
      expect(
        mapper.mapSignalKey(
          event(
            id: 'PC',
            famille: 'collective',
            familleLib: 'Procédures collectives',
            jugement: 'jugement de redressement judiciaire',
          ),
        ),
        BodaccSignalKey.collectiveProceeding,
      );
    });
  });
}
