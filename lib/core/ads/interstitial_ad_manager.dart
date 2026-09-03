import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_ids.dart';
import 'ads_support.dart';

/// Loads interstitial ads and shows one before an operation — always on
/// the very first operation of the app session, then every [operationsPerAd]
/// operations after that (so it isn't shown on literally every single tap,
/// which the user found too aggressive after trying it). That every-Nth
/// slot uses a rewarded-interstitial creative instead of a plain one (see
/// [AdIds.rewardedInterstitial]) — same trigger point, longer/higher-value
/// ad for the more-engaged user.
class InterstitialAdManager {
  InterstitialAdManager({this.operationsPerAd = 3});

  final int operationsPerAd;
  int _operationCount = 0;

  InterstitialAd? _ad;
  bool _isLoading = false;

  RewardedInterstitialAd? _rewardedAd;
  bool _isLoadingRewarded = false;

  /// Preloads both the plain interstitial and the every-Nth rewarded
  /// interstitial, so whichever slot comes up next has an ad ready.
  void preload() {
    _preloadPlain();
    _preloadRewarded();
  }

  void _preloadPlain() {
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

  void _preloadRewarded() {
    if (!adsSupported || _rewardedAd != null || _isLoadingRewarded) return;
    _isLoadingRewarded = true;
    RewardedInterstitialAd.load(
      adUnitId: AdIds.rewardedInterstitial,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoadingRewarded = false;
        },
        onAdFailedToLoad: (error) {
          _isLoadingRewarded = false;
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
  ///
  /// Every call site awaits this *before* its own try/catch (so the ad
  /// appears before the operation's loading state kicks in) — which means
  /// this must never let an exception escape. Ads are never essential to a
  /// PDF operation, so any failure here (a plugin channel error, an ad SDK
  /// hiccup not already caught by [FullScreenContentCallback]) is swallowed
  /// rather than silently killing the operation the user actually asked for.
  Future<void> showBeforeOperation() async {
    if (!adsSupported) return;
    try {
      await _showBeforeOperation();
    } catch (_) {
      // Deliberately swallowed - see doc comment above.
    }
  }

  Future<void> _showBeforeOperation() async {
    _operationCount++;
    final bool isRewardedSlot = _operationCount % operationsPerAd == 0;
    final bool shouldShow = _operationCount == 1 || isRewardedSlot;
    if (!shouldShow) return;

    if (isRewardedSlot) {
      await _showRewarded();
      return;
    }

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

  Future<void> _showRewarded() async {
    final RewardedInterstitialAd? ad = _rewardedAd;
    if (ad == null) {
      _preloadRewarded();
      return;
    }

    _rewardedAd = null;
    final Completer<void> done = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _preloadRewarded();
        if (!done.isCompleted) done.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _preloadRewarded();
        if (!done.isCompleted) done.complete();
      },
    );
    // No in-app reward is granted here — this slot just uses the
    // rewarded-interstitial ad *format* for its longer/higher-value
    // creative; onUserEarnedReward is intentionally a no-op.
    await ad.show(onUserEarnedReward: (ad, reward) {});
    await done.future;
  }
}
