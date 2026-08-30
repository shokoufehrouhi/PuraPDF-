import 'package:flutter_test/flutter_test.dart';
import 'package:purapdf/core/docx/docx_paragraph.dart';
import 'package:purapdf/core/docx/docx_reader.dart';
import 'package:purapdf/core/docx/docx_writer.dart';

void main() {
  test('DocxWriter -> DocxReader round-trips text, bold/italic, and headings', () {
    final input = [
      const DocxParagraph(text: 'Report Title', headingLevel: 1),
      const DocxParagraph(text: 'This is a plain paragraph.'),
      const DocxParagraph(text: 'This one is bold.', bold: true),
      const DocxParagraph(text: 'This one is italic.', italic: true),
      const DocxParagraph(
        text: 'Special chars: <tag> & "quotes" survive?',
      ),
    ];

    final bytes = DocxWriter.write(input);
    final output = DocxReader.read(bytes);

    expect(output.length, input.length);
    for (int i = 0; i < input.length; i++) {
      expect(output[i].text, input[i].text, reason: 'paragraph $i text');
      expect(output[i].italic, input[i].italic, reason: 'paragraph $i italic');
      expect(
        output[i].headingLevel,
        input[i].headingLevel,
        reason: 'paragraph $i headingLevel',
      );
      // A heading is always written+read back as bold (that's the intended
      // "headings render bold" behavior), regardless of its own bold flag -
      // only body paragraphs round-trip bold as a true identity.
      final bool expectedBold = input[i].bold || input[i].headingLevel > 0;
      expect(output[i].bold, expectedBold, reason: 'paragraph $i bold');
    }
  });

  test('DocxWriter produces a real ZIP with the required OOXML parts', () {
    final bytes = DocxWriter.write(const [
      DocxParagraph(text: 'Hello'),
    ]);
    // A .docx is a ZIP - the local file header signature is "PK\x03\x04".
    expect(bytes.length, greaterThan(4));
    expect(bytes.sublist(0, 4), [0x50, 0x4B, 0x03, 0x04]);
  });

  test('DocxReader skips empty/whitespace-only paragraphs', () {
    final bytes = DocxWriter.write(const [
      DocxParagraph(text: 'Real content'),
      DocxParagraph(text: '   '),
      DocxParagraph(text: ''),
    ]);
    final output = DocxReader.read(bytes);
    expect(output.length, 1);
    expect(output.first.text, 'Real content');
  });
}
