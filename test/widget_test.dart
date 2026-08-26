// Basic smoke test for the app shell.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:purapdf/main.dart';

void main() {
  testWidgets('App launches and shows the feature hub', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: PuraPdfApp()));

    expect(find.text('PuraPDF+'), findsWidgets);
    expect(find.text('Merge PDF'), findsOneWidget);
  });
}
