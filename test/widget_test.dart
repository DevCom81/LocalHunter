import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:localhunter/app.dart';

void main() {
  testWidgets('LocalHunter app loads', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: LocalHunterApp()),
    );
    expect(find.text('LocalHunter'), findsWidgets);
  });
}
