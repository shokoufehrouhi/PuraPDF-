/// One line of extractable text on a PDF page, with its position (PDF
/// points, top-left origin — same space as page width/height elsewhere in
/// this app) and font info. Used by the content editor to place a tappable
/// region over each line so the user can edit or delete it.
class PdfTextLine {
  final int pageIndex;
  final String text;
  final double left;
  final double top;
  final double width;
  final double height;
  final String fontName;
  final double fontSize;

  const PdfTextLine({
    required this.pageIndex,
    required this.text,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.fontName,
    required this.fontSize,
  });
}
