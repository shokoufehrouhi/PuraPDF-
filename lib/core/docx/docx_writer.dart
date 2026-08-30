import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import 'docx_paragraph.dart';

/// Builds a minimal, valid .docx (a ZIP of the handful of OOXML parts Word
/// actually requires) from [DocxParagraph]s.
///
/// Deliberately hand-rolled rather than pulled in from a package: the one
/// promising pure-Dart option (docx_creator) pins xml ^6.x, which conflicts
/// with syncfusion_flutter_pdf's xml ^7.x — a real, currently-unresolvable
/// version clash with this app's core PDF dependency, not something worth
/// downgrading Syncfusion over for one feature. A minimal OOXML writer is a
/// few small string templates, not worth a dependency fight.
///
/// Plain string templates rather than XmlBuilder - the only genuinely
/// dynamic content is paragraph text, which just needs `_escape`; templates
/// keep the required-namespace bookkeeping (`w:` throughout) trivial instead
/// of fighting a builder API over it.
class DocxWriter {
  const DocxWriter._();

  static Uint8List write(List<DocxParagraph> paragraphs) {
    final Archive archive = Archive();
    void addXml(String path, String xml) {
      final List<int> bytes = utf8.encode(xml);
      archive.addFile(ArchiveFile(path, bytes.length, bytes));
    }

    addXml('[Content_Types].xml', _contentTypesXml);
    addXml('_rels/.rels', _rootRelsXml);
    addXml('word/_rels/document.xml.rels', _documentRelsXml);
    addXml('word/document.xml', _documentXml(paragraphs));

    final List<int> zipBytes = ZipEncoder().encode(archive);
    return Uint8List.fromList(zipBytes);
  }

  static const String _contentTypesXml =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
      '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
      '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
      '<Default Extension="xml" ContentType="application/xml"/>'
      '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>'
      '</Types>';

  static const String _rootRelsXml =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>'
      '</Relationships>';

  static const String _documentRelsXml =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"/>';

  static String _documentXml(List<DocxParagraph> paragraphs) {
    final StringBuffer body = StringBuffer();
    for (final DocxParagraph p in paragraphs) {
      body.write(_paragraphXml(p));
    }
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
        '<w:body>'
        '$body'
        '<w:sectPr>'
        '<w:pgSz w:w="12240" w:h="15840"/>'
        '<w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440" w:header="720" w:footer="720" w:gutter="0"/>'
        '</w:sectPr>'
        '</w:body>'
        '</w:document>';
  }

  static String _paragraphXml(DocxParagraph p) {
    final bool bold = p.bold || p.headingLevel > 0;
    final StringBuffer pPr = StringBuffer();
    if (p.headingLevel > 0) {
      pPr.write('<w:pStyle w:val="Heading${p.headingLevel}"/>');
    }
    final StringBuffer rPr = StringBuffer();
    if (bold) rPr.write('<w:b/>');
    if (p.italic) rPr.write('<w:i/>');
    if (p.headingLevel > 0) {
      rPr.write('<w:sz w:val="${_headingHalfPoints(p.headingLevel)}"/>');
    }

    return '<w:p>'
        '${pPr.isEmpty ? '' : '<w:pPr>$pPr</w:pPr>'}'
        '<w:r>'
        '${rPr.isEmpty ? '' : '<w:rPr>$rPr</w:rPr>'}'
        '<w:t xml:space="preserve">${_escape(p.text)}</w:t>'
        '</w:r>'
        '</w:p>';
  }

  /// w:sz is in half-points; bigger headings for lower level numbers.
  static int _headingHalfPoints(int level) {
    switch (level) {
      case 1:
        return 36; // 18pt
      case 2:
        return 32; // 16pt
      case 3:
        return 28; // 14pt
      default:
        return 26; // 13pt
    }
  }

  static String _escape(String text) => text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}
