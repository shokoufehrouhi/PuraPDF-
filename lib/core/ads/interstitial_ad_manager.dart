import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_ids.dart';
import 'ads_support.dart';
import 'operation_counter.dart';

/// Loads interstitial ads and shows one every [operationsPerAd] completed
/// operations (merge/split/compress/...) — never on every single action,
/// per the roadmap note: don't annoy free users on every use.
///
/// The operation counter (see [OperationCounter]) persists across app
/// restarts instead of resetting every launch.
class InterstitialAdManager {
  InterstitialAdManager({int operationsPerAd = 3})
    : _counter = OperationCounter(threshold: operationsPerAd);

  final OperationCounter _counter;

  InterstitialAd? _ad;
  bool _isLoading = false;

  void preload() {
    if (!adsSupported || _ad != null || _isLoading) return;
    _isLoading = true;
    InterstitialAd.load(
      adUnitId: AdIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _isLoading = false;
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
        },
      ),
    );
  }

  /// Call after a completed operation (successful merge/split/...). Shows
  /// the preloaded interstitial once every [operationsPerAd] calls; a no-op
  /// on platforms without ads support, or if nothing is loaded yet (the
  /// next preload attempt just tries again for the following round).
  Future<void> recordOperationAndMaybeShow() async {
    if (!adsSupported) return;

    final bool shouldShow = await _counter.incrementAndCheck();
    if (!shouldShow) return;

    final InterstitialAd? ad = _ad;
    if (ad == null) {
      preload();
      return;
    }

    _ad = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        preload();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        preload();
      },
    );
    await ad.show();
  }
}
