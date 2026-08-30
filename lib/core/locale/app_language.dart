import 'package:flutter/material.dart';

/// One supported UI language: its locale, the flag shown in the switcher,
/// and its own name (never translated — "Deutsch" reads the same regardless
/// of which language is currently active, so a user can always find their
/// own language in the list even if they land on the wrong one first).
class AppLanguage {
  final Locale locale;
  final String flag;
  final String nativeName;

  const AppLanguage({
    required this.locale,
    required this.flag,
    required this.nativeName,
  });

  bool get isRtl => locale.languageCode == 'fa' || locale.languageCode == 'ar';
}

const List<AppLanguage> supportedAppLanguages = [
  AppLanguage(locale: Locale('en'), flag: '🇺🇸', nativeName: 'English'),
  AppLanguage(locale: Locale('de'), flag: '🇩🇪', nativeName: 'Deutsch'),
  AppLanguage(locale: Locale('es'), flag: '🇪🇸', nativeName: 'Español'),
  AppLanguage(locale: Locale('tr'), flag: '🇹🇷', nativeName: 'Türkçe'),
  AppLanguage(locale: Locale('fa'), flag: '🇮🇷', nativeName: 'فارسی'),
  AppLanguage(locale: Locale('ar'), flag: '🇸🇦', nativeName: 'العربية'),
];

AppLanguage appLanguageFor(Locale locale) => supportedAppLanguages.firstWhere(
  (l) => l.locale.languageCode == locale.languageCode,
  orElse: () => supportedAppLanguages.first,
);
