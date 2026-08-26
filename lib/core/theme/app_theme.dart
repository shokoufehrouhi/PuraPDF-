import 'package:flutter/material.dart';

/// Central theme definitions for PuraPDF.
/// Keep all color/typography decisions here so features never hardcode styles.
class AppTheme {
  AppTheme._();

  static const Color _seedColor = Color(0xFF2E6BE6);

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    ),
  );
}
