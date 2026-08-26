import 'package:flutter/foundation.dart';

/// Ad unit IDs. These are Google's published TEST IDs — safe to ship in
/// debug builds, but MUST be swapped for real IDs (from the AdMob console,
/// after registering this app there) before a production release. See also
/// the AdMob App IDs in android/app/src/main/AndroidManifest.xml and
/// ios/Runner/Info.plist, which need the same swap.
class AdIds {
  AdIds._();

  static String get banner => defaultTargetPlatform == TargetPlatform.android
      ? 'ca-app-pub-3940256099942544/6300978111'
      : 'ca-app-pub-3940256099942544/2934735716';

  static String get interstitial =>
      defaultTargetPlatform == TargetPlatform.android
      ? 'ca-app-pub-3940256099942544/1033173712'
      : 'ca-app-pub-3940256099942544/4411468910';
}
