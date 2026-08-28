import 'package:flutter/foundation.dart';

/// Real AdMob ad unit IDs (account ca-app-pub-6967597025156397), set
/// 2026-08-28. The AdMob App IDs (a different ID, one per platform) live in
/// android/app/src/main/AndroidManifest.xml and ios/Runner/Info.plist.
///
/// IMPORTANT — do not tap/interact with ads shown while testing on a real
/// device now that these are live IDs: AdMob policy treats clicks on your
/// own real ads as invalid traffic and can suspend the account. Register
/// this device as a test device instead — see AdsService.init's
/// RequestConfiguration comment for how.
class AdIds {
  AdIds._();

  static String get banner => defaultTargetPlatform == TargetPlatform.android
      ? 'ca-app-pub-6967597025156397/2783679619'
      : 'ca-app-pub-6967597025156397/5381922798';

  static String get interstitial =>
      defaultTargetPlatform == TargetPlatform.android
      ? 'ca-app-pub-6967597025156397/2275201708'
      : 'ca-app-pub-6967597025156397/9540659657';

  static String get appOpen => defaultTargetPlatform == TargetPlatform.android
      ? 'ca-app-pub-6967597025156397/8728929411'
      : 'ca-app-pub-6967597025156397/4068841124';
}
