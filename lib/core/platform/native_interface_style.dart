import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tells the native side (iOS/macOS) to override its interface style so
/// system-presented UI — the file picker, share sheet, keyboard, etc. —
/// matches the app's own theme override instead of only ever following
/// the device's actual system Dark/Light Mode setting.
///
/// A no-op on platforms with no registered handler (Android/web): there,
/// native pickers just keep following the system setting as before.
class NativeInterfaceStyle {
  NativeInterfaceStyle._();

  static const MethodChannel _channel = MethodChannel('purapdf/native_theme');

  static Future<void> sync(ThemeMode mode) async {
    if (defaultTargetPlatform != TargetPlatform.iOS &&
        defaultTargetPlatform != TargetPlatform.macOS) {
      return;
    }
    final String style = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    try {
      await _channel.invokeMethod<void>('setInterfaceStyle', style);
    } on MissingPluginException {
      // Native handler not registered (e.g. a test harness) — harmless,
      // the in-app theme still works fine on its own.
    } on PlatformException {
      // Defensive: never let a native-theme hiccup break in-app theming.
    }
  }
}
