/// A rectangle on [pageIndex] to permanently redact — unlike
/// [PdfContentEdit]'s text replace (which only *covers* a line, leaving the
/// original glyphs in the content stream underneath), redacting actually
/// removes the text-showing operators for whatever falls inside this area
/// before drawing an opaque bar on top. See `redactPdf`'s doc comment in
/// `PdfRepositoryImpl` for the exact mechanism and its scope limits (whole
/// text lines only, no embedded images).
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

  const PdfRedactArea({
    required this.pageIndex,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });
}
