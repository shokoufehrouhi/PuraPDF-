import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_ids.dart';
import 'ads_support.dart';

/// Loads and shows one app-open ad per app launch — the user wants a short
/// ad right when the app opens, on top of (not instead of) the interstitial
/// shown before operations (see [InterstitialAdManager]).
class AppOpenAdManager {
  AppOpenAd? _ad;
  Completer<void>? _loadCompleter;

  /// Starts loading the ad for this launch. Call once, at startup —
  /// doesn't block anything itself.
  void preload() {
    if (!adsSupported) return;
    final Completer<void> completer = Completer<void>();
    _loadCompleter = completer;
    AppOpenAd.load(
      adUnitId: AdIds.appOpen,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          if (!completer.isCompleted) completer.complete();
        },
        onAdFailedToLoad: (error) {
          if (!completer.isCompleted) completer.complete();
        },
      ),
    );
  }

  /// Waits briefly for the ad kicked off by [preload] and shows it if it
  /// arrived in time; never blocks app usage past [timeout] waiting on a
  /// network load. Call once, right after the first frame.
  ///
  /// Called `unawaited` from `main.dart`, so an escaped exception here
  /// wouldn't block anything either way — but it would still surface as a
  /// noisy unhandled-Zone-error at startup for something the user never
  /// even needs, so it's swallowed the same way [InterstitialAdManager]
  /// swallows its own.
  Future<void> showIfReady({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    if (!adsSupported) return;
    try {
      await _showIfReady(timeout);
    } catch (_) {
      // Deliberately swallowed - see doc comment above.
    }
  }

  Future<void> _showIfReady(Duration timeout) async {
    final Completer<void>? completer = _loadCompleter;
    if (completer == null) return; // preload() was never called
    await Future.any([completer.future, Future<void>.delayed(timeout)]);

    final AppOpenAd? ad = _ad;
    if (ad == null) return;
    _ad = null;

    final Completer<void> done = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!done.isCompleted) done.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        if (!done.isCompleted) done.complete();
      },
    );
    await ad.show();
    await done.future;
  }
}
