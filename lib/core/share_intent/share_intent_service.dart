import 'package:flutter/services.dart';

/// A file handed off from the iOS Share Sheet extension, plus which tool
/// the user picked for it while still in the extension's own UI (see
/// `ios/ShareExtension/ShareViewController.swift`'s tool list - [tool]'s
/// values must match the `id`s there).
class PendingShare {
  final String path;
  final String tool;

  const PendingShare({required this.path, required this.tool});
}

/// Dart half of the Share Extension hand-off. The extension can't safely
/// do any PDF processing itself (see ShareViewController.swift's doc
/// comment on the memory-limit reasoning), so all it does is: copy the
/// shared file into the `group.com.purapdf.purapdf` App Group container,
/// record which tool got tapped in that group's shared UserDefaults, then
/// foreground this app via the `purapdf://share` URL scheme. This service
/// just reads that hand-off back out through a platform channel to the
/// native side (`AppDelegate.swift`'s `registerShareIntentChannel`).
///
/// Android has no equivalent yet - `takePendingShare` returns null there
/// (and everywhere the channel simply isn't implemented), which is exactly
/// the same "nothing pending" result as the normal no-share case, so
/// callers don't need a platform check.
class ShareIntentService {
  ShareIntentService._();
  static const _channel = MethodChannel('purapdf/share_intent');

  /// Consumes and clears the pending share, if any - a second call right
  /// after returns null. Called once at app start and again on every
  /// `AppLifecycleState.resumed` (see `main.dart`'s `_ShareIntentGate`),
  /// since a share can arrive while the app is already backgrounded, not
  /// just at a cold launch.
  static Future<PendingShare?> takePendingShare() async {
    try {
      final Object? result = await _channel.invokeMethod('takePendingShare');
      if (result is! Map) return null;
      final path = result['path'];
      final tool = result['tool'];
      if (path is! String || tool is! String) return null;
      return PendingShare(path: path, tool: tool);
    } on MissingPluginException {
      return null; // Android, or any platform without the channel wired up.
    } on PlatformException {
      return null;
    }
  }
}
