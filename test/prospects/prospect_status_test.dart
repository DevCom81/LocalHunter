import 'package:flutter_test/flutter_test.dart';
import 'package:localhunter/core/constants/prospect_status.dart';

void main() {
  group('ProspectStatus B2', () {
    test('conserve les 7 statuts historiques', () {
      expect(ProspectStatus.fromDb('new'), ProspectStatus.newProspect);
      expect(ProspectStatus.fromDb('contacted'), ProspectStatus.contacted);
      expect(ProspectStatus.fromDb('interested'), ProspectStatus.interested);
      expect(ProspectStatus.fromDb('proposal'), ProspectStatus.proposal);
      expect(ProspectStatus.fromDb('won'), ProspectStatus.won);
      expect(ProspectStatus.fromDb('lost'), ProspectStatus.lost);
      expect(ProspectStatus.fromDb('excluded'), ProspectStatus.excluded);
    });

    test('parse les nouveaux statuts', () {
      expect(ProspectStatus.fromDb('to_study'), ProspectStatus.toStudy);
      expect(ProspectStatus.fromDb('to_contact'), ProspectStatus.toContact);
      expect(ProspectStatus.fromDb('not_relevant'), ProspectStatus.notRelevant);
      expect(
        ProspectStatus.fromDb('already_equipped'),
        ProspectStatus.alreadyEquipped,
      );
      expect(ProspectStatus.fromDb('too_small'), ProspectStatus.tooSmall);
      expect(ProspectStatus.fromDb('franchise'), ProspectStatus.franchise);
      expect(ProspectStatus.fromDb('out_of_scope'), ProspectStatus.outOfScope);
      expect(ProspectStatus.fromDb('no_reply'), ProspectStatus.noReply);
      expect(ProspectStatus.fromDb('meeting'), ProspectStatus.meeting);
    });

    test('valeur inconnue → new (rétrocompat)', () {
      expect(ProspectStatus.fromDb('unknown_xyz'), ProspectStatus.newProspect);
    });

    test('dimsInList et labels FR', () {
      expect(ProspectStatus.newProspect.dimsInList, isFalse);
      expect(ProspectStatus.toStudy.dimsInList, isFalse);
      expect(ProspectStatus.toContact.dimsInList, isFalse);
      expect(ProspectStatus.contacted.dimsInList, isTrue);
      expect(ProspectStatus.notRelevant.dimsInList, isTrue);
      expect(ProspectStatus.meeting.label, 'Rendez-vous obtenu');
      expect(ProspectStatus.alreadyEquipped.label, 'Déjà équipé');
    });

    test('16 statuts au total', () {
      expect(ProspectStatus.values, hasLength(16));
    });
  });
}
