// Basic smoke test for the app shell.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:purapdf/main.dart';

void main() {
  testWidgets('App launches and shows the feature hub', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: PuraPdfApp()));

    // The header renders "PuraPDF" + "+" as separate spans of one
    // Text.rich, so this needs findRichText to match the combined text.
    expect(find.text('PuraPDF+', findRichText: true), findsWidgets);
    expect(find.text('Merge PDFs'), findsOneWidget);
    expect(find.text('Split PDF'), findsOneWidget);
    expect(find.text('Compress PDF'), findsOneWidget);
  });
}
