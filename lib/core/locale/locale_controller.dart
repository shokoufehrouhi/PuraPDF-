import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _prefsKey = 'purapdf_locale';

/// The app's current UI language. `null` means "not chosen yet" — the very
/// first launch, before the user has picked one on the language-picker
/// screen — and is the signal `main.dart`/the app root uses to show that
/// screen instead of the home screen. Every language after that first pick
/// is explicit; there's no "follow system language" fallback since the
/// picker is shown immediately anyway.
class LocaleController extends Notifier<Locale?> {
  @override
  Locale? build() {
    _loadSaved();
    return null;
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final String? saved = prefs.getString(_prefsKey);
    if (saved != null) {
      state = Locale(saved);
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, locale.languageCode);
  }
}

final localeControllerProvider = NotifierProvider<LocaleController, Locale?>(
  LocaleController.new,
);
