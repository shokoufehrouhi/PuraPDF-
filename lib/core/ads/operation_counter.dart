import 'package:shared_preferences/shared_preferences.dart';

/// Tracks how many completed operations (merge/split/...) have happened
/// since the last interstitial ad, persisted so it survives app restarts.
///
/// Kept as pure counting logic, separate from [InterstitialAdManager], so
/// it's testable without touching the ads SDK.
class OperationCounter {
  OperationCounter({
    this.threshold = 3,
    this.key = 'purapdf_ad_operation_counter',
  });

  final int threshold;
  final String key;

  /// Increments the counter and returns true — resetting it back to 0 —
  /// once it reaches [threshold]; otherwise persists the new count and
  /// returns false.
  Future<bool> incrementAndCheck() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int count = (prefs.getInt(key) ?? 0) + 1;
    if (count >= threshold) {
      await prefs.setInt(key, 0);
      return true;
    }
    await prefs.setInt(key, count);
    return false;
  }
}
