import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ads_support.dart';
import 'app_open_ad_manager.dart';
import 'consent_service.dart';
import 'interstitial_ad_manager.dart';

/// App-wide ads entry point: call [init] once at startup (kicks off the
/// app-open ad's preload too — see [appOpen]), then use [interstitial]
/// right before each operation and `BannerAdWidget` in layouts.
class AdsService {
  AdsService._();
  static final AdsService instance = AdsService._();

  final InterstitialAdManager interstitial = InterstitialAdManager();
  final AppOpenAdManager appOpen = AppOpenAdManager();
  bool _initialized = false;

  Future<void> init() async {
    if (!adsSupported || _initialized) return;
    _initialized = true;

    // Order matters here, per Google's own guidance: gather GDPR/UK consent
    // first (EEA/UK/Switzerland only — a no-op everywhere else), then the
    // iOS tracking prompt, and only then initialize the Mobile Ads SDK.
    final bool canRequestAds = await ConsentService.instance.gatherConsent();

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        await AppTrackingTransparency.requestTrackingAuthorization();
      }
    }

    if (!canRequestAds) {
      // User's region requires consent and it wasn't obtained (or the
      // consent-info update itself failed with nothing cached from a prior
      // session) — skip ad init entirely rather than request ads without
      // a resolved consent state. Ads are non-essential to the app's core
      // PDF features, so this just means no ads this session.
      return;
    }

    await MobileAds.instance.initialize();
    // Ad unit IDs are real (see AdIds) — tapping/interacting with ads shown
    // on your own device now counts as invalid traffic under AdMob policy
    // and risks account suspension. To keep getting clearly-labeled TEST
    // ads on a specific device while developing, add its test device ID
    // below: run the app once, check the Xcode/logcat console for a line
    // like "... to get test ads on this device" quoting the ID, then add
    // it here.
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(testDeviceIds: const []),
    );
    interstitial.preload();
    appOpen.preload();
  }
}
