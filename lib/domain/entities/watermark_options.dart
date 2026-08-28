/// Settings for stamping a text watermark diagonally across every page of
/// a PDF. Color is plain RGB ints (not `dart:ui`'s Color) to keep the
/// domain layer free of Flutter-specific types.
class WatermarkOptions {
  final String text;
  final double opacity; // 0..1
  final double fontSize;
  final int colorR;
  final int colorG;
  final int colorB;

  const WatermarkOptions({
    required this.text,
    required this.opacity,
    required this.fontSize,
    required this.colorR,
    required this.colorG,
    required this.colorB,
  });
}
