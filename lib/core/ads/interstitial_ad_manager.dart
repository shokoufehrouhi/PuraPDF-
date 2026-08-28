import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_ids.dart';
import 'ads_support.dart';

/// Loads interstitial ads and shows one before an operation — always on
/// the very first operation of the app session, then every [operationsPerAd]
/// operations after that (so it isn't shown on literally every single tap,
/// which the user found too aggressive after trying it).
class InterstitialAdManager {
  InterstitialAdManager({this.operationsPerAd = 3});

  final int operationsPerAd;
  int _operationCount = 0;

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
  /// and await it — the operation should only begin once this returns.
  /// Shows on the first call of the session, then every [operationsPerAd]th
  /// call after that. A no-op on platforms without ads support; if nothing
  /// is loaded when it's this call's turn to show, kicks off a preload for
  /// next time and returns immediately rather than blocking the operation.
  Future<void> showBeforeOperation() async {
    if (!adsSupported) return;

    _operationCount++;
    final bool shouldShow =
        _operationCount == 1 || _operationCount % operationsPerAd == 0;
    if (!shouldShow) return;

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
