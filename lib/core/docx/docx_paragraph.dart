/// One paragraph of text, at the fidelity level this app's PDF<->Word
/// conversion actually supports: plain text plus paragraph-level bold/
/// italic/heading — no per-word (run-level) mixed formatting, no images,
/// no tables, no exact layout. A real .docx/PDF can mix styles mid-
/// paragraph; this app doesn't try to preserve that, only which paragraphs
/// read as "a heading" or "emphasized" as a whole. See docx_reader.dart and
/// docx_writer.dart's doc comments for why.
class DocxParagraph {
  final String text;
  final bool bold;
  final bool italic;

  /// 0 = body text, 1-6 = heading level (matches Word's Heading1..Heading6
  /// styles / this app's own PDF heading-size convention).
  final int headingLevel;

  const DocxParagraph({
    required this.text,
    this.bold = false,
    this.italic = false,
    this.headingLevel = 0,
  });
}
