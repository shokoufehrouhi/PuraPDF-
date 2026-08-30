/// A rectangle on [pageIndex] to permanently redact — unlike
/// [PdfContentEdit]'s text replace (which only *covers* a line, leaving the
/// original glyphs in the content stream underneath), redacting actually
/// removes the text-showing operators for whatever falls inside this area
/// before drawing a bar on top. See `redactPdf`'s doc comment in
/// `PdfRepositoryImpl` for the exact mechanism and its scope limits (whole
/// text lines only, no embedded images).
///
/// [colorR]/[colorG]/[colorB]/[opacity] only affect that cover bar's *look*
/// (plain RGB ints + 0..1 opacity, not `dart:ui`'s Color, to keep the
/// domain layer free of Flutter-specific types - same convention as
/// [WatermarkOptions]) - the underlying text is gone from the content
/// stream regardless of how opaque the bar is, so a lower opacity is a
/// cosmetic choice, not a correctness/privacy risk. Default is solid black,
/// matching how a redaction actually looks everywhere else.
///
/// Rect-shaped (not a line index) so a future freeform-area redaction mode
/// could reuse this same entity — today's UI always fills it in from a
/// whole [PdfTextLine]'s bounds.
class PdfRedactArea {
  final int pageIndex;
  final double left;
  final double top;
  final double width;
  final double height;
  final int colorR;
  final int colorG;
  final int colorB;
  final double opacity;

  const PdfRedactArea({
    required this.pageIndex,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    this.colorR = 0,
    this.colorG = 0,
    this.colorB = 0,
    this.opacity = 1.0,
  });
}
