import 'package:flutter/material.dart';

/// Per-feature accent colors — shared by the home screen's tool cards, the
/// Recents rows (which derive an operation's color from the same palette),
/// and each feature screen's own header/buttons, so a tool reads as the
/// same "app icon" everywhere it shows up.
///
/// Each feature has a light/lighter pastel pair (soft card gradients) plus
/// a separate saturated [Icon] color so icons read clearly against a white
/// badge instead of blending into the pale card behind them.
class FeatureColors {
  FeatureColors._();

  static const Color merge = Color(0xFFC7E3FC);
  static const Color mergeDark = Color(0xFFACD3FA);
  static const Color mergeIcon = Color(0xFF3B82F6);

  static const Color split = Color(0xFFE4D7F5);
  static const Color splitDark = Color(0xFFD3BEEC);
  static const Color splitIcon = Color(0xFF8B5CF6);

  static const Color compress = Color(0xFFFFE3C4);
  static const Color compressDark = Color(0xFFFFD1A0);
  static const Color compressIcon = Color(0xFFF97316);

  static const Color imagePdf = Color(0xFFCDEDD0);
  static const Color imagePdfDark = Color(0xFFB8E4BC);
  static const Color imagePdfIcon = Color(0xFF22C55E);

  static const Color scanner = Color(0xFFC9F1E9);
  static const Color scannerDark = Color(0xFFABE8DD);
  static const Color scannerIcon = Color(0xFF14B8A6);
}
