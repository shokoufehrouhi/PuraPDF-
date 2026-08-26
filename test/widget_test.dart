// Basic smoke test for the Phase 0 app scaffold.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:purapdf/main.dart';

void main() {
  testWidgets('App launches and shows the Phase 0 placeholder', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: PuraPdfApp()));

    expect(find.text('PuraPDF'), findsOneWidget);
    expect(find.textContaining('Phase 0 scaffold ready'), findsOneWidget);
  });
}
