import 'package:flutter/material.dart';

/// Per-feature accent colors — shared by the home screen's tool cards, the
/// Recents rows (which derive an operation's color from the same palette),
/// and each feature screen's own header/buttons, so a tool reads as the
/// same "app icon" everywhere it shows up.
///
/// Each feature has a light/lighter pastel pair (soft card gradients) plus
/// a separate saturated [Icon] color so icons read clearly against a white
/// badge instead of blending into the pale card behind them.
///
/// Every hue below was sampled directly from the 2026-09-08 reference icon
/// sheet (user-supplied mockup) and the pastel pair derived from that same
/// sample - so a card's row background is always the same hue family as
/// its own icon, matching the reference instead of an independently
/// chosen palette.
class FeatureColors {
  FeatureColors._();

  static const Color merge = Color(0xFFDFDBF5);
  static const Color mergeDark = Color(0xFFCDC7F0);
  static const Color mergeIcon = Color(0xFF4C36C9);

  static const Color split = Color(0xFFF5D9E5);
  static const Color splitDark = Color(0xFFF0C4D7);
  static const Color splitIcon = Color(0xFFC92E70);

  static const Color compress = Color(0xFFFEE2DB);
  static const Color compressDark = Color(0xFFFDD2C6);
  static const Color compressIcon = Color(0xFFF86035);

  static const Color imagePdf = Color(0xFFD9F0DF);
  static const Color imagePdfDark = Color(0xFFC4E8CD);
  static const Color imagePdfIcon = Color(0xFF2DAE4B);

  static const Color scanner = Color(0xFFD3ECEC);
  static const Color scannerDark = Color(0xFFBAE2E1);
  static const Color scannerIcon = Color(0xFF0A9694);

  static const Color pageEdit = Color(0xFFFEE8F2);
  static const Color pageEditDark = Color(0xFFFDDCEA);
  static const Color pageEditIcon = Color(0xFFF982B5);

  static const Color contentEdit = Color(0xFFE7E2FC);
  static const Color contentEditDark = Color(0xFFD9D2FB);
  static const Color contentEditIcon = Color(0xFF775FEF);

  static const Color encrypt = Color(0xFFF7DBDC);
  static const Color encryptDark = Color(0xFFF2C7C8);
  static const Color encryptIcon = Color(0xFFD1363A);

  static const Color watermark = Color(0xFFD5E9F0);
  static const Color watermarkDark = Color(0xFFBDDDE8);
  static const Color watermarkIcon = Color(0xFF1486AD);

  static const Color signature = Color(0xFFD9DFF1);
  static const Color signatureDark = Color(0xFFC4CDE9);
  static const Color signatureIcon = Color(0xFF2E4CB1);

  static const Color pdfWord = Color(0xFFD9E6FE);
  static const Color pdfWordDark = Color(0xFFC4D8FE);
  static const Color pdfWordIcon = Color(0xFF2E75FC);

  static const Color redact = Color(0xFFF6D9E2);
  static const Color redactDark = Color(0xFFF2C4D2);
  static const Color redactIcon = Color(0xFFCF2E60);

  static const Color fillSign = Color(0xFFD5F0E0);
  static const Color fillSignDark = Color(0xFFBEE8CF);
  static const Color fillSignIcon = Color(0xFF18AC52);
}
