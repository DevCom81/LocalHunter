import 'package:flutter_test/flutter_test.dart';
import 'package:localhunter/core/constants/priority_level.dart';
import 'package:localhunter/core/constants/prospect_status.dart';
import 'package:localhunter/features/prospects/domain/entities/prospect.dart';
import 'package:localhunter/features/prospects/domain/entities/prospect_with_score.dart';
import 'package:localhunter/features/prospects/domain/services/bodacc_selection.dart';
import 'package:localhunter/features/scoring/domain/entities/prospect_score.dart';

ProspectScore _score(int global) => ProspectScore(
      id: 's-$global',
      prospectId: 'p',
      globalScore: global,
      accessibilityScore: 0,
      websiteOpportunity: 0,
      softwareOpportunity: 0,
      commercialHealth: 0,
      siteScore: 0,
      softwareScore: 0,
      easyRestScore: 0,
      accessibilityStars: 0,
      digitalMaturity: 0,
      falsePositiveRisk: 0,
      priority: PriorityLevel.medium,
    );

Prospect _p({
  required String id,
  String? siren,
  String? siret,
  bool excluded = false,
  bool ambiguous = false,
  int? matchScore = 80,
  DateTime? bodaccFetchedAt,
}) {
  return Prospect(
    id: id,
    campaignId: 'c1',
    name: id,
    status: ProspectStatus.newProspect,
    siren: siren,
    siret: siret,
    isExcluded: excluded,
    sireneMatchAmbiguous: ambiguous,
    sireneMatchScore: matchScore,
    bodaccFetchedAt: bodaccFetchedAt,
  );
}

void main() {
  const selection = BodaccSelection();

  group('C4.2 — BodaccSelection', () {
    test('exclut sans SIREN, exclus, ambigus sans SIRET, match faible, cache', () {
      final now = DateTime(2026, 8, 5);
      expect(
        selection.isEligible(_p(id: 'a', siren: null), now: now),
        isFalse,
      );
      expect(
        selection.isEligible(
          _p(id: 'b', siren: '552081317', excluded: true),
          now: now,
        ),
        isFalse,
      );
      expect(
        selection.isEligible(
          _p(id: 'c', siren: '552081317', ambiguous: true),
          now: now,
        ),
        isFalse,
      );
      expect(
        selection.isEligible(
          _p(id: 'd', siren: '552081317', matchScore: 50),
          now: now,
        ),
        isFalse,
      );
      expect(
        selection.isEligible(
          _p(
            id: 'e',
            siren: '552081317',
            bodaccFetchedAt: now.subtract(const Duration(days: 2)),
          ),
          now: now,
        ),
        isFalse,
      );
      expect(
        selection.isEligible(
          _p(id: 'f', siren: '552081317'),
          now: now,
        ),
        isTrue,
      );
    });

    test('SIRET / SIREN ferme → BODACC malgré match faible ou ambigu', () {
      expect(
        selection.isEligible(
          _p(
            id: 'g',
            siren: '552081317',
            siret: '55208131700015',
            matchScore: 40,
            ambiguous: true,
          ),
        ),
        isTrue,
      );
      expect(
        selection.isEligible(
          _p(
            id: 'h',
            siren: null,
            siret: '55208131700015',
            matchScore: null,
          ),
        ),
        isTrue,
      );
      expect(
        BodaccSelection.resolveSiren(
          _p(id: 'i', siret: '55208131700015'),
        ),
        '552081317',
      );
    });

    test('ignoreCache autorise un refresh manuel', () {
      final now = DateTime(2026, 8, 5);
      expect(
        selection.isEligible(
          _p(
            id: 'e',
            siren: '552081317',
            bodaccFetchedAt: now.subtract(const Duration(days: 2)),
          ),
          ignoreCache: true,
          now: now,
        ),
        isTrue,
      );
    });

    test('selectTop trie par score et plafonne à 20', () {
      final fixed = [
        for (var i = 0; i < 25; i++)
          ProspectWithScore(
            prospect: _p(
              id: 'p$i',
              siren: (100000000 + i).toString(),
            ),
            score: _score(i),
          ),
      ];
      final top = selection.selectTop(fixed);
      expect(top.length, 20);
      expect(top.first.score.globalScore, 24);
      expect(top.last.score.globalScore, 5);
    });
  });
}
