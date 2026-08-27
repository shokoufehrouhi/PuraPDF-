import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../platform/native_interface_style.dart';

/// User's theme preference (defaults to following the system), persisted
/// across app restarts.
class ThemeModeController extends Notifier<ThemeMode> {
  static const String _prefsKey = 'purapdf_theme_mode';

  @override
  ThemeMode build() {
    _loadPersisted();
    return ThemeMode.system;
  }

  Future<void> _loadPersisted() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? saved = prefs.getString(_prefsKey);
    if (saved == null) return;
    state = ThemeMode.values.firstWhere(
      (mode) => mode.name == saved,
      orElse: () => ThemeMode.system,
    );
    // So the native file picker / share sheet / keyboard match a
    // previously-saved override right from app launch, not just after
    // the next toggle.
    unawaited(NativeInterfaceStyle.sync(state));
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, mode.name);
    unawaited(NativeInterfaceStyle.sync(mode));
  }

  /// Cycles system -> light -> dark -> system, for a single tap toggle.
  void cycle() {
    switch (state) {
      case ThemeMode.system:
        setMode(ThemeMode.light);
      case ThemeMode.light:
        setMode(ThemeMode.dark);
      case ThemeMode.dark:
        setMode(ThemeMode.system);
    }
  }
}

final themeModeControllerProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);
