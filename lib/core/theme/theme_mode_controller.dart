import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../platform/native_interface_style.dart';

/// User's theme preference — just [ThemeMode.light]/[ThemeMode.dark], no
/// "System" option: the user picks one explicitly and the app stays on it
/// until they toggle again, persisted across restarts. On first launch
/// (nothing saved yet) it starts from the device's current system
/// brightness as a one-time sensible default, not as ongoing following.
class ThemeModeController extends Notifier<ThemeMode> {
  static const String _prefsKey = 'purapdf_theme_mode';

  @override
  ThemeMode build() {
    final ThemeMode initial =
        PlatformDispatcher.instance.platformBrightness == Brightness.dark
        ? ThemeMode.dark
        : ThemeMode.light;
    _loadPersisted(initial);
    return initial;
  }

  Future<void> _loadPersisted(ThemeMode fallback) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? saved = prefs.getString(_prefsKey);
    state = saved == 'dark'
        ? ThemeMode.dark
        : saved == 'light'
        ? ThemeMode.light
        : fallback;
    // So the native file picker / share sheet / keyboard match a
    // previously-saved choice right from app launch, not just after the
    // next toggle.
    unawaited(NativeInterfaceStyle.sync(state));
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, mode.name);
    unawaited(NativeInterfaceStyle.sync(mode));
  }

  /// Toggles light <-> dark, for a single tap.
  void cycle() {
    setMode(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }
}

final themeModeControllerProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);
