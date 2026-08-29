import 'package:flutter_test/flutter_test.dart';
import 'package:purapdf/core/error_message.dart';

void main() {
  group('friendlyErrorMessage', () {
    test('passes an ArgumentError\'s message through as-is (a l10n key)', () {
      final error = ArgumentError('errorEnterPassword');
      expect(friendlyErrorMessage(error), 'errorEnterPassword');
    });

    test('falls back to the generic key for anything else', () {
      expect(friendlyErrorMessage(Exception('some internal detail')), 'errorGeneric');
      expect(friendlyErrorMessage(StateError('bad state')), 'errorGeneric');
    });
  });
}
