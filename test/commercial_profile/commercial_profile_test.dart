import 'package:flutter_test/flutter_test.dart';
import 'package:localhunter/features/commercial_profile/data/repositories/demo_commercial_profile_repository.dart';
import 'package:localhunter/features/commercial_profile/domain/entities/commercial_profile.dart';

void main() {
  group('CommercialProfile B4', () {
    test('toEdgePayload null si non validé', () {
      const p = CommercialProfile(userId: 'u1', activity: 'Menuisier');
      expect(p.toEdgePayload(), isNull);
      expect(p.isValidated, isFalse);
    });

    test('toEdgePayload présent uniquement après validation', () async {
      final repo = DemoCommercialProfileRepository();
      final saved = await repo.save(
        const CommercialProfile(
          userId: 'u1',
          activity: 'Menuisier',
          offer: 'Pose de parquet',
          targetClientType: 'Restaurants',
        ),
        markValidated: true,
      );
      expect(saved.isValidated, isTrue);
      final payload = saved.toEdgePayload();
      expect(payload, isNotNull);
      expect(payload!['activity'], 'Menuisier');
      expect(payload['offer'], 'Pose de parquet');
      expect(payload['target_client_type'], 'Restaurants');
    });

    test('brouillon retire la validation', () async {
      final repo = DemoCommercialProfileRepository();
      await repo.save(
        const CommercialProfile(userId: 'u1', activity: 'Menuisier'),
        markValidated: true,
      );
      final draft = await repo.save(
        const CommercialProfile(userId: 'u1', activity: 'Menuisier', offer: 'x'),
        markValidated: false,
      );
      expect(draft.isValidated, isFalse);
      expect(draft.toEdgePayload(), isNull);
    });
  });
}
