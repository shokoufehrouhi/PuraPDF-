import 'package:flutter/foundation.dart';

/// `doclens` (native camera + edge detection) only ships Android + iOS
/// native implementations. Guard every scanner call site with this instead
/// of letting macOS/web/desktop builds crash trying to reach a plugin that
/// was never registered.
bool get scannerSupported =>
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;
