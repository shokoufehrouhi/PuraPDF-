import 'package:flutter/foundation.dart';

/// `google_mobile_ads` only ships Android + iOS native implementations.
/// Guard every ad-related call site with this instead of letting macOS/web/
/// desktop builds crash trying to reach a plugin that was never registered.
bool get adsSupported =>
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;
