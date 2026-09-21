import 'package:flutter_test/flutter_test.dart';

import 'package:localhunter/features/prospects/data/models/prospect_dto.dart';

void main() {
  test('toInsertJson envoie toujours custom_fields non null', () {
    final json = ProspectDto(
      id: '00000000-0000-0000-0000-000000000001',
      campaignId: '00000000-0000-0000-0000-000000000002',
      name: 'Test',
    ).toInsertJson();

    expect(json.containsKey('custom_fields'), isTrue);
    expect(json['custom_fields'], isA<Map>());
    expect(json['custom_fields'], isNot(null));
    expect(json.values.where((v) => v == null), isEmpty);
  });
}
