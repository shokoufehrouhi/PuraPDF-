import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ads_support.dart';
import 'interstitial_ad_manager.dart';

/// App-wide ads entry point: call [init] once at startup, then use
/// [interstitial] right before each operation and `BannerAdWidget` in
/// layouts.
class AdsService {
  AdsService._();
  static final AdsService instance = AdsService._();

  final InterstitialAdManager interstitial = InterstitialAdManager();
  bool _initialized = false;

  Future<void> init() async {
    if (!adsSupported || _initialized) return;
    _initialized = true;
    await MobileAds.instance.initialize();
    interstitial.preload();
  }
}
