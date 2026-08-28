import 'dart:typed_data';

/// One edit applied directly to an existing PDF page's content — unlike
/// [PdfPageEdit] (page structure: order/rotation/presence), this changes
/// what's actually drawn on a page.
///
/// Text edits are "redact + redraw": the original line's area is covered
/// with an opaque box, then the replacement text (if any) is drawn on top.
/// This is a visual edit, not true reflow-aware text editing — the
/// underlying PDF has no general API for that — so the original glyphs
/// still exist in the content stream beneath the cover box; a viewer never
/// shows them, but text extraction of that region isn't guaranteed to be
/// gone. Good enough for "fix a word" / "delete a sentence"; not a
/// redaction/security tool.
sealed class PdfContentEdit {
  final int pageIndex;
  const PdfContentEdit(this.pageIndex);
}

/// Covers the text line at ([left], [top], [width], [height]) on
/// [pageIndex] and draws [newText] in its place using [fontName]/
/// [fontSize] as a best-effort match (mapped to the nearest of the PDF
/// standard fonts). An empty [newText] leaves the area blank — a delete.
class PdfTextReplace extends PdfContentEdit {
  final double left;
  final double top;
  final double width;
  final double height;
  final String fontName;
  final double fontSize;
  final String newText;

  const PdfTextReplace({
    required int pageIndex,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.fontName,
    required this.fontSize,
    required this.newText,
  }) : super(pageIndex);
}

/// Draws [imageBytes] into the box at ([left], [top], [width], [height])
/// on [pageIndex].
class PdfImageInsert extends PdfContentEdit {
  final Uint8List imageBytes;
  final double left;
  final double top;
  final double width;
  final double height;

  const PdfImageInsert({
    required int pageIndex,
    required this.imageBytes,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  }) : super(pageIndex);
}
