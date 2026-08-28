import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_ids.dart';
import 'ads_support.dart';

/// Loads interstitial ads and shows one before every operation
/// (merge/split/compress/...) — the user explicitly wants an ad shown
/// every single time, not just occasionally.
class InterstitialAdManager {
  InterstitialAdManager();

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

  /// Call right before starting an operation (merge/split/compress/...)
  /// and await it — the operation should only begin once this returns, so
  /// the ad genuinely shows *first*. Waits for the ad to be dismissed
  /// before completing. A no-op on platforms without ads support; if
  /// nothing is loaded yet, kicks off a preload for next time and returns
  /// immediately rather than blocking the operation indefinitely.
  Future<void> showBeforeOperation() async {
    if (!adsSupported) return;

    final InterstitialAd? ad = _ad;
    if (ad == null) {
      preload();
      return;
    }

    _ad = null;
    final Completer<void> done = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        preload();
        if (!done.isCompleted) done.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        preload();
        if (!done.isCompleted) done.complete();
      },
    );
    await ad.show();
    await done.future;
  }
}
