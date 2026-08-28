import 'dart:typed_data';

/// A rendered page image plus the source page's size in PDF points (its
/// coordinate space) — the point size lets callers map screen taps and
/// overlay positions back to PDF coordinates without depending on the
/// image's pixel resolution.
class PdfPageImage {
  final Uint8List bytes;
  final double pointsWidth;
  final double pointsHeight;

  const PdfPageImage({
    required this.bytes,
    required this.pointsWidth,
    required this.pointsHeight,
  });
}
