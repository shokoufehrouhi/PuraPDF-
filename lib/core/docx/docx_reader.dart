import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import 'docx_paragraph.dart';

/// Reads a .docx's paragraphs back out — the inverse of [DocxWriter], and at
/// the same fidelity level (see docx_paragraph.dart): a paragraph's
/// bold/italic/heading come from its FIRST run/style only, not preserved
/// per-word. Any real-world .docx opens fine here (this reads, it doesn't
/// require the file to have been written by this app), just flattened down
/// to that level on the way out.
class DocxReader {
  const DocxReader._();

  static List<DocxParagraph> read(Uint8List bytes) {
    final Archive archive = ZipDecoder().decodeBytes(bytes);
    final ArchiveFile? documentEntry = archive.findFile('word/document.xml');
    if (documentEntry == null) {
      throw const FormatException(
        'Not a valid .docx file (missing word/document.xml)',
      );
    }
    final List<int> content = documentEntry.content as List<int>;
    final XmlDocument doc = XmlDocument.parse(utf8.decode(content));

    final List<DocxParagraph> paragraphs = [];
    for (final XmlElement p in doc.findAllElements('w:p')) {
      final String text = p.findAllElements('w:t').map((t) => t.innerText).join();
      if (text.trim().isEmpty) continue;

      final XmlElement? pStyle = _firstOrNull(
        p.findElements('w:pPr').expand((pPr) => pPr.findElements('w:pStyle')),
      );
      final int headingLevel = _headingLevelFrom(pStyle?.getAttribute('w:val'));

      final XmlElement? firstRunProps = _firstOrNull(
        p.findElements('w:r').expand((r) => r.findElements('w:rPr')),
      );
      final bool bold = firstRunProps != null &&
          firstRunProps.findElements('w:b').isNotEmpty;
      final bool italic = firstRunProps != null &&
          firstRunProps.findElements('w:i').isNotEmpty;

      paragraphs.add(
        DocxParagraph(
          text: text,
          bold: bold,
          italic: italic,
          headingLevel: headingLevel,
        ),
      );
    }
    return paragraphs;
  }

  static XmlElement? _firstOrNull(Iterable<XmlElement> elements) {
    for (final XmlElement e in elements) {
      return e;
    }
    return null;
  }

  static int _headingLevelFrom(String? styleId) {
    if (styleId == null) return 0;
    final RegExpMatch? match = RegExp(r'^Heading([1-6])$').firstMatch(styleId);
    if (match != null) return int.parse(match.group(1)!);
    if (styleId == 'Title') return 1;
    return 0;
  }
}
