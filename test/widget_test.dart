// Basic smoke test for the app shell.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:purapdf/main.dart';

void main() {
  testWidgets('App launches and shows the feature hub', (
    WidgetTester tester,
  ) async {
    // Pre-seed a saved language choice - otherwise LocaleController's state
    // starts null (see its doc comment) and the app shows the first-launch
    // language picker instead of the home screen this test actually checks.
    SharedPreferences.setMockInitialValues({'purapdf_locale': 'en'});

    await tester.pumpWidget(const ProviderScope(child: PuraPdfApp()));
    // LocaleController loads the saved locale asynchronously (SharedPreferences
    // is itself async), so the first pumpWidget still sees the null/picker
    // state - one more pump lets that Future resolve and rebuild.
    await tester.pump();

    // The header renders "PuraPDF" + "+" as separate spans of one
    // Text.rich, so this needs findRichText to match the combined text.
    expect(find.text('PuraPDF+', findRichText: true), findsWidgets);
    expect(find.text('Merge PDFs'), findsOneWidget);
    expect(find.text('Split PDF'), findsOneWidget);
    expect(find.text('Compress PDF'), findsOneWidget);
  });
}
