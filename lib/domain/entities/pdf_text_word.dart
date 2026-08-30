/// One word of extractable text on a PDF page, with its position (PDF
/// points, top-left origin — same space as [PdfTextLine]/page width/height
/// elsewhere in this app). Used by Redact so the user can mark a single word
/// or drag across a range of adjacent words, rather than only a whole line.
///
/// [lineIndex] groups words back into the line they came from (the index
/// into that same extraction pass's line list, *not* [pageIndex] — two
/// words with the same [lineIndex] but different [pageIndex] never happen
/// since lines don't cross pages) — used to bucket a multi-word selection
/// back into one bounding rect per line it touches.
class PdfTextWord {
  final int pageIndex;
  final int lineIndex;
  final String text;
  final double left;
  final double top;
  final double width;
  final double height;

  const PdfTextWord({
    required this.pageIndex,
    required this.lineIndex,
    required this.text,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });
}
