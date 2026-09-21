/// Mapping déterministe BODACC → signaux (miroir Edge `signals.ts`).
/// C4.1 : logique pure testable ; l'Edge reste la source d'exécution.
library;

enum BodaccSignalKey {
  creation,
  accountsFiling,
  modification,
  sale,
  radiation,
  liquidation,
  collectiveProceeding,
  managerChange,
  addressChange,
  unclassified,
}

enum BodaccRadiationStatus { none, excluded, review }

class BodaccRawEvent {
  const BodaccRawEvent({
    required this.id,
    this.dateParution,
    this.familleAvis,
    this.familleAvisLib,
    this.typeAvis,
    this.typeAvisLib,
    this.registre = const [],
    this.ville,
    this.url,
    this.hasRadiationField = false,
    this.hasDepotField = false,
    this.jugementText = '',
    this.modificationsText = '',
  });

  final String id;
  final String? dateParution;
  final String? familleAvis;
  final String? familleAvisLib;
  final String? typeAvis;
  final String? typeAvisLib;
  final List<String> registre;
  final String? ville;
  final String? url;
  final bool hasRadiationField;
  final bool hasDepotField;
  final String jugementText;
  final String modificationsText;
}

class BodaccNormalizedEvent {
  const BodaccNormalizedEvent({
    required this.bodaccId,
    required this.signalKey,
    required this.isRectificatif,
    required this.withinLookback,
    this.dateParution,
  });

  final String bodaccId;
  final BodaccSignalKey signalKey;
  final bool isRectificatif;
  final bool withinLookback;
  final String? dateParution;
}

class BodaccSignals {
  const BodaccSignals({
    required this.noResults,
    required this.hasCreation,
    required this.hasAccountsFiling,
    required this.hasModification,
    required this.hasSale,
    required this.hasRadiation,
    required this.hasLiquidation,
    required this.hasCollectiveProceeding,
    required this.hasManagerChange,
    required this.hasAddressChange,
    required this.radiationStatus,
    this.lastEventAt,
  });

  final bool noResults;
  final bool hasCreation;
  final bool hasAccountsFiling;
  final bool hasModification;
  final bool hasSale;
  final bool hasRadiation;
  final bool hasLiquidation;
  final bool hasCollectiveProceeding;
  final bool hasManagerChange;
  final bool hasAddressChange;
  final BodaccRadiationStatus radiationStatus;
  final String? lastEventAt;
}

class BodaccSignalMapper {
  const BodaccSignalMapper({this.lookbackYears = 5});

  final int lookbackYears;

  static String? normalizeSiren(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    return digits.length == 9 ? digits : null;
  }

  static String _fold(String? s) {
    if (s == null) return '';
    return s
        .toLowerCase()
        .replaceAll(RegExp(r'[àáâãäå]'), 'a')
        .replaceAll(RegExp(r'[èéêë]'), 'e')
        .replaceAll(RegExp(r'[ìíîï]'), 'i')
        .replaceAll(RegExp(r'[òóôõö]'), 'o')
        .replaceAll(RegExp(r'[ùúûü]'), 'u')
        .replaceAll('ç', 'c');
  }

  bool recordMatchesSiren(BodaccRawEvent record, String siren) {
    return record.registre.any((v) => normalizeSiren(v) == siren);
  }

  bool isRectificatif(BodaccRawEvent r) {
    final blob = '${_fold(r.typeAvis)} ${_fold(r.typeAvisLib)}';
    return blob.contains('rectif');
  }

  bool withinLookback(DateTime? date, [DateTime? now]) {
    if (date == null) return false;
    final n = now ?? DateTime.now();
    final cutoff = DateTime(n.year - lookbackYears, n.month, n.day);
    return !date.isBefore(cutoff);
  }

  BodaccSignalKey mapSignalKey(BodaccRawEvent r) {
    final famille = _fold(r.familleAvis);
    final familleLib = _fold(r.familleAvisLib);
    final typeLib = _fold(r.typeAvisLib);
    final combo = '$famille $familleLib $typeLib';
    final mods = _fold(r.modificationsText);
    final jugement = _fold(r.jugementText);

    if (r.hasRadiationField || combo.contains('radiation')) {
      return BodaccSignalKey.radiation;
    }
    if (combo.contains('liquid') || jugement.contains('liquid')) {
      return BodaccSignalKey.liquidation;
    }
    if (combo.contains('collective') ||
        combo.contains('procedure collective') ||
        combo.contains('redressement') ||
        combo.contains('sauvegarde') ||
        jugement.contains('redressement') ||
        jugement.contains('sauvegarde') ||
        jugement.contains('liquidation judiciaire')) {
      return BodaccSignalKey.collectiveProceeding;
    }
    if (combo.contains('vente') ||
        combo.contains('cession') ||
        combo.contains('transfert')) {
      return BodaccSignalKey.sale;
    }
    if (r.hasDepotField ||
        combo.contains('depot') ||
        combo.contains('comptes')) {
      return BodaccSignalKey.accountsFiling;
    }
    if (combo.contains('creation') || combo.contains('immatriculation')) {
      return BodaccSignalKey.creation;
    }
    if (mods.contains('administration') ||
        mods.contains('dirigeant') ||
        mods.contains('gerant') ||
        mods.contains('president')) {
      return BodaccSignalKey.managerChange;
    }
    if (mods.contains('adresse') ||
        mods.contains('siege') ||
        combo.contains('transfert de siege')) {
      return BodaccSignalKey.addressChange;
    }
    if (combo.contains('modification') || famille == 'modification') {
      return BodaccSignalKey.modification;
    }
    return BodaccSignalKey.unclassified;
  }

  BodaccRadiationStatus decideRadiationStatus({
    required List<BodaccNormalizedEvent> events,
    required bool? sireneActive,
  }) {
    final radiation = events.where(
      (e) =>
          e.signalKey == BodaccSignalKey.radiation &&
          e.withinLookback &&
          !e.isRectificatif,
    );
    if (radiation.isEmpty) return BodaccRadiationStatus.none;
    if (sireneActive == false) return BodaccRadiationStatus.excluded;
    return BodaccRadiationStatus.review;
  }

  BodaccSignals derive({
    required List<BodaccRawEvent> records,
    required String siren,
    bool? sireneActive,
    DateTime? now,
  }) {
    final n = now ?? DateTime.now();
    final normalized = normalizeSiren(siren);
    if (normalized == null) {
      return _empty(noResults: true);
    }

    final events = <BodaccNormalizedEvent>[];
    for (final r in records) {
      if (!recordMatchesSiren(r, normalized)) continue;
      final date = r.dateParution != null
          ? DateTime.tryParse(r.dateParution!)
          : null;
      events.add(
        BodaccNormalizedEvent(
          bodaccId: r.id,
          signalKey: mapSignalKey(r),
          isRectificatif: isRectificatif(r),
          withinLookback: withinLookback(date, n),
          dateParution: r.dateParution?.substring(0, 10),
        ),
      );
    }

    if (events.isEmpty) return _empty(noResults: true);

    final inWindow = events.where((e) => e.withinLookback).toList();
    final keys = inWindow.map((e) => e.signalKey).toSet();
    final dates = events
        .map((e) => e.dateParution)
        .whereType<String>()
        .toList()
      ..sort();

    return BodaccSignals(
      noResults: false,
      hasCreation: keys.contains(BodaccSignalKey.creation),
      hasAccountsFiling: keys.contains(BodaccSignalKey.accountsFiling),
      hasModification: keys.contains(BodaccSignalKey.modification),
      hasSale: keys.contains(BodaccSignalKey.sale),
      hasRadiation: keys.contains(BodaccSignalKey.radiation),
      hasLiquidation: keys.contains(BodaccSignalKey.liquidation),
      hasCollectiveProceeding:
          keys.contains(BodaccSignalKey.collectiveProceeding),
      hasManagerChange: keys.contains(BodaccSignalKey.managerChange),
      hasAddressChange: keys.contains(BodaccSignalKey.addressChange),
      lastEventAt: dates.isEmpty ? null : dates.last,
      radiationStatus: decideRadiationStatus(
        events: events,
        sireneActive: sireneActive,
      ),
    );
  }

  BodaccSignals _empty({required bool noResults}) {
    return BodaccSignals(
      noResults: noResults,
      hasCreation: false,
      hasAccountsFiling: false,
      hasModification: false,
      hasSale: false,
      hasRadiation: false,
      hasLiquidation: false,
      hasCollectiveProceeding: false,
      hasManagerChange: false,
      hasAddressChange: false,
      radiationStatus: BodaccRadiationStatus.none,
    );
  }
}
