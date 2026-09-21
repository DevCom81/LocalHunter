import 'package:flutter_test/flutter_test.dart';
import 'package:localhunter/features/prospects/domain/enrichment/enrichment_contracts.dart';

void main() {
  group('Pipeline P1 — contrats enrichissement', () {
    test('shouldEmitSignal : null refusé, valeur acceptée', () {
      expect(EnrichmentContractRules.shouldEmitSignal(null), isFalse);
      expect(EnrichmentContractRules.shouldEmitSignal(true), isTrue);
      expect(EnrichmentContractRules.shouldEmitSignal(0), isTrue);
      expect(EnrichmentContractRules.shouldEmitSignal(''), isTrue);
    });

    test('provider désactivé → skipped', () {
      const ctx = EnrichmentContext(
        prospectId: 'p1',
        knownData: EnrichmentKnownData(siren: '552081317'),
        options: EnrichmentOptions(enabledProviders: ['sirene']),
      );
      expect(EnrichmentContractRules.isProviderEnabled(ctx, 'bodacc'), isFalse);
      expect(EnrichmentContractRules.isProviderEnabled(ctx, 'sirene'), isTrue);

      final skipped = EnrichmentContractRules.skipped(
        provider: 'bodacc',
        reason: 'provider_disabled',
      );
      expect(skipped.status, ProviderStatus.skipped);
      expect(skipped.error?.type, 'skipped');
      expect(skipped.signals, isEmpty);
    });

    test('exception timeout → failed retryable', () {
      final result = EnrichmentContractRules.failedFromThrow(
        provider: 'pagespeed',
        err: Exception('AbortError: timeout'),
      );
      expect(result.status, ProviderStatus.failed);
      expect(result.error?.type, 'timeout');
      expect(result.error?.retryable, isTrue);
    });

    test('sanitizeErrorMessage retire SIREN / URL / email', () {
      final cleaned = EnrichmentContractRules.sanitizeErrorMessage(
        'fail siren 552081317 at https://evil.example/x for a@b.fr',
      );
      expect(cleaned.contains('552081317'), isFalse);
      expect(cleaned.contains('https://'), isFalse);
      expect(cleaned.contains('a@b.fr'), isFalse);
      expect(cleaned.contains('[redacted]'), isTrue);
      expect(cleaned.contains('[url]'), isTrue);
      expect(cleaned.contains('[email]'), isTrue);
    });

    test('absence de SIREN : pas de signal positif inventé', () {
      // Règle produit : on n'émet un signal que si value != null.
      const noSiren = EnrichmentKnownData();
      final wouldBePositive = noSiren.siren != null; // false
      expect(wouldBePositive, isFalse);
      expect(
        EnrichmentContractRules.shouldEmitSignal(noSiren.siren),
        isFalse,
      );
    });

    test('metadata keys : seules les clés autorisées', () {
      final keys = {'durationMs', 'cacheStatus', 'siren', 'prospect_id'};
      final forbidden = keys.difference(
        EnrichmentContractRules.allowedMetadataKeys,
      );
      expect(forbidden, containsAll(['siren', 'prospect_id']));
    });

    test('statuts ProviderStatus couvrent le contrat Edge', () {
      expect(ProviderStatus.values.map((e) => e.name).toSet(), {
        'success',
        'partial',
        'skipped',
        'failed',
      });
    });

    test('BodaccProvider.canRun : SIREN 9 chiffres requis', () {
      expect(
        EnrichmentContractRules.bodaccCanRun(
          const EnrichmentKnownData(siren: '552081317'),
        ),
        isTrue,
      );
      expect(
        EnrichmentContractRules.bodaccCanRun(
          const EnrichmentKnownData(siren: '123'),
        ),
        isFalse,
      );
      expect(
        EnrichmentContractRules.bodaccCanRun(const EnrichmentKnownData()),
        isFalse,
      );
    });

    test('SireneProvider.canRun : name + city requis', () {
      expect(
        EnrichmentContractRules.sireneCanRun(
          const EnrichmentKnownData(name: 'Chez Paul', city: 'Albi'),
        ),
        isTrue,
      );
      expect(
        EnrichmentContractRules.sireneCanRun(
          const EnrichmentKnownData(name: 'Chez Paul'),
        ),
        isFalse,
      );
      expect(
        EnrichmentContractRules.sireneCanRun(const EnrichmentKnownData()),
        isFalse,
      );
    });

    test('PageSpeedProvider.canRun : URL normalisable requise', () {
      expect(
        EnrichmentContractRules.pagespeedCanRun(
          const EnrichmentKnownData(websiteUrl: 'https://example.com'),
        ),
        isTrue,
      );
      expect(
        EnrichmentContractRules.pagespeedCanRun(
          const EnrichmentKnownData(websiteUrl: 'example.com/path'),
        ),
        isTrue,
      );
      expect(
        EnrichmentContractRules.pagespeedCanRun(const EnrichmentKnownData()),
        isFalse,
      );
    });

    test('PageSpeed skip si websiteReachable == false', () {
      expect(
        EnrichmentContractRules.pagespeedShouldSkipUnreachable(
          const EnrichmentKnownData(
            websiteUrl: 'https://down.example',
            websiteReachable: false,
          ),
        ),
        isTrue,
      );
      expect(
        EnrichmentContractRules.pagespeedShouldSkipUnreachable(
          const EnrichmentKnownData(
            websiteUrl: 'https://ok.example',
            websiteReachable: true,
          ),
        ),
        isFalse,
      );
    });

    test('WebsiteProvider.canRun + métrique failure ssrf/timeout', () {
      expect(
        EnrichmentContractRules.websiteCanRun(
          const EnrichmentKnownData(websiteUrl: 'https://example.com'),
        ),
        isTrue,
      );
      expect(
        EnrichmentContractRules.websiteCountsAsApiFailure('ssrf'),
        isTrue,
      );
      expect(
        EnrichmentContractRules.websiteCountsAsApiFailure('timeout'),
        isTrue,
      );
      expect(
        EnrichmentContractRules.websiteCountsAsApiFailure('http_status'),
        isFalse,
      );
    });

    test('PlacesProvider.canRun : city non vide requis', () {
      expect(
        EnrichmentContractRules.placesCanRun(
          const EnrichmentKnownData(city: 'Albi', sector: 'restaurant'),
        ),
        isTrue,
      );
      expect(
        EnrichmentContractRules.placesCanRun(
          const EnrichmentKnownData(city: '  '),
        ),
        isFalse,
      );
      expect(
        EnrichmentContractRules.placesCanRun(const EnrichmentKnownData()),
        isFalse,
      );
    });

    test('PROVIDER_NAMES miroir Edge (6 sources documentées)', () {
      expect(EnrichmentContractRules.providerNames, [
        'places',
        'sirene',
        'company',
        'bodacc',
        'website',
        'pagespeed',
      ]);
    });

    test('CompanyProvider.canRun : SIREN 9 chiffres requis', () {
      expect(
        EnrichmentContractRules.companyCanRun(
          const EnrichmentKnownData(siren: '552081317'),
        ),
        isTrue,
      );
      expect(
        EnrichmentContractRules.companyCanRun(
          const EnrichmentKnownData(siren: '123'),
        ),
        isFalse,
      );
    });
  });
}
