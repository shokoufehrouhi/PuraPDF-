import 'package:flutter_test/flutter_test.dart';
import 'package:purapdf/core/error_message.dart';

void main() {
  group('friendlyErrorMessage', () {
    test('shows an ArgumentError\'s message as-is, no Dart prefix', () {
      final error = ArgumentError('Enter a password.');
      expect(friendlyErrorMessage(error), 'Enter a password.');
    });

    test('falls back to a generic message for anything else', () {
      expect(
        friendlyErrorMessage(Exception('some internal detail')),
        'Something went wrong. Please try again.',
      );
      expect(
        friendlyErrorMessage(StateError('bad state')),
        'Something went wrong. Please try again.',
      );
    });
  });
}
