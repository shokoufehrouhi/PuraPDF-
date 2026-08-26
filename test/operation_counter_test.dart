// Functional test for the interstitial ad throttling logic — pure counting,
// no ads SDK involved, so it's fully testable headless.
import 'package:flutter_test/flutter_test.dart';
import 'package:purapdf/core/ads/operation_counter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('does not trigger before reaching the threshold', () async {
    final counter = OperationCounter(threshold: 3, key: 'test_key_a');

    expect(await counter.incrementAndCheck(), isFalse);
    expect(await counter.incrementAndCheck(), isFalse);
  });

  test('triggers on the threshold-th call and then resets', () async {
    final counter = OperationCounter(threshold: 3, key: 'test_key_b');

    expect(await counter.incrementAndCheck(), isFalse); // 1
    expect(await counter.incrementAndCheck(), isFalse); // 2
    expect(await counter.incrementAndCheck(), isTrue); // 3 -> reset

    // Next cycle starts from zero again.
    expect(await counter.incrementAndCheck(), isFalse); // 1
    expect(await counter.incrementAndCheck(), isFalse); // 2
    expect(await counter.incrementAndCheck(), isTrue); // 3 -> reset
  });

  test('persists across separate instances sharing the same key', () async {
    final first = OperationCounter(threshold: 3, key: 'test_key_c');
    expect(await first.incrementAndCheck(), isFalse); // 1

    // A new instance (e.g. after an app restart) with the same key picks
    // up where the persisted count left off.
    final second = OperationCounter(threshold: 3, key: 'test_key_c');
    expect(await second.incrementAndCheck(), isFalse); // 2
    expect(await second.incrementAndCheck(), isTrue); // 3 -> reset
  });

  test('different keys track independently', () async {
    final counterA = OperationCounter(threshold: 2, key: 'test_key_d1');
    final counterB = OperationCounter(threshold: 2, key: 'test_key_d2');

    expect(await counterA.incrementAndCheck(), isFalse); // A: 1
    expect(await counterB.incrementAndCheck(), isFalse); // B: 1
    expect(await counterA.incrementAndCheck(), isTrue); // A: 2 -> reset
    expect(await counterB.incrementAndCheck(), isTrue); // B: 2 -> reset
  });
}
