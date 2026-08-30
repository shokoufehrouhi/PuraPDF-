// Functional test for PDF<->Word: writes a real PDF with Syncfusion, runs
// it through PdfToWordUseCase, then reads the resulting .docx straight back
// with DocxReader (bypassing Word/LibreOffice, this only proves the file is
// valid OOXML with the right text in it) - and the same round-trip the
// other way for WordToPdfUseCase.
import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:purapdf/core/docx/docx_paragraph.dart';
import 'package:purapdf/core/docx/docx_reader.dart';
import 'package:purapdf/core/docx/docx_writer.dart';
import 'package:purapdf/data/repositories/pdf_repository_impl.dart';
import 'package:purapdf/domain/usecases/pdf_to_word_usecase.dart';
import 'package:purapdf/domain/usecases/word_to_pdf_usecase.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final Directory dir;
  _FakePathProvider(this.dir);

  @override
  Future<String?> getApplicationDocumentsPath() async => dir.path;
}

Future<String> _writeTextPdf(String path, List<String> lines) async {
  final doc = PdfDocument();
  final PdfPage page = doc.pages.add();
  final PdfFont font = PdfStandardFont(PdfFontFamily.helvetica, 14);
  double y = 0;
  for (final line in lines) {
    page.graphics.drawString(
      line,
      font,
      bounds: Rect.fromLTWH(0, y, page.getClientSize().width, 20),
    );
    y += 40; // a big gap on purpose - one paragraph per line
  }
  final bytes = await doc.save();
  doc.dispose();
  await File(path).writeAsBytes(bytes, flush: true);
  return path;
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('purapdf_pdf_word_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir);
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('PdfToWordUseCase produces a .docx containing the PDF\'s text', () async {
    final source = await _writeTextPdf('${tempDir.path}/source.pdf', [
      'First paragraph of the document.',
      'A second, separate paragraph.',
    ]);
    final useCase = PdfToWordUseCase(PdfRepositoryImpl());

    final outPath = await useCase(source);
    expect(outPath.endsWith('.docx'), isTrue);

    final paragraphs = DocxReader.read(File(outPath).readAsBytesSync());
    final allText = paragraphs.map((p) => p.text).join('\n');
    expect(allText, contains('First paragraph of the document.'));
    expect(allText, contains('A second, separate paragraph.'));
  });

  test('PdfToWordUseCase rejects a missing source path', () async {
    final useCase = PdfToWordUseCase(PdfRepositoryImpl());
    expect(() => useCase(''), throwsArgumentError);
  });

  test('WordToPdfUseCase produces a PDF containing the docx\'s text', () async {
    final docxPath = '${tempDir.path}/source.docx';
    final bytes = DocxWriter.write(const [
      DocxParagraph(text: 'A Heading', headingLevel: 1),
      DocxParagraph(text: 'Ordinary body text in the paragraph.'),
      DocxParagraph(text: 'An emphasized line.', italic: true),
    ]);
    await File(docxPath).writeAsBytes(bytes);

    final useCase = WordToPdfUseCase(PdfRepositoryImpl());
    final outPath = await useCase(docxPath);
    expect(outPath.endsWith('.pdf'), isTrue);

    final doc = PdfDocument(inputBytes: File(outPath).readAsBytesSync());
    final extracted = PdfTextExtractor(doc).extractText();
    doc.dispose();

    expect(extracted, contains('A Heading'));
    expect(extracted, contains('Ordinary body text in the paragraph.'));
    expect(extracted, contains('An emphasized line.'));
  });

  test('WordToPdfUseCase rejects a missing source path', () async {
    final useCase = WordToPdfUseCase(PdfRepositoryImpl());
    expect(() => useCase(''), throwsArgumentError);
  });

  test(
    'WordToPdfUseCase paginates a document with many paragraphs across multiple PDF pages',
    () async {
      final docxPath = '${tempDir.path}/long.docx';
      final paragraphs = [
        for (int i = 0; i < 80; i++)
          DocxParagraph(
            text:
                'Paragraph number $i - a reasonably long sentence so this document runs to several pages once converted to PDF.',
          ),
      ];
      await File(docxPath).writeAsBytes(DocxWriter.write(paragraphs));

      final useCase = WordToPdfUseCase(PdfRepositoryImpl());
      final outPath = await useCase(docxPath);

      final doc = PdfDocument(inputBytes: File(outPath).readAsBytesSync());
      final int pageCount = doc.pages.count;
      final extracted = PdfTextExtractor(doc).extractText();
      doc.dispose();

      expect(pageCount, greaterThan(1));
      expect(extracted, contains('Paragraph number 0 -'));
      expect(extracted, contains('Paragraph number 79 -'));
    },
  );

  // testWidgets, not test() - loading the bundled Arabic-script font goes
  // through rootBundle, which needs a real Flutter test binding. That
  // binding runs the test body in a fake-async zone, so any *real*
  // asynchronous dart:io work (temp dirs, file writes - anything not driven
  // by widget-test pumping) has to go through tester.runAsync(), or it just
  // hangs forever instead of erroring (confirmed by reproducing it: the
  // exact same await Directory.systemTemp.createTemp() that works fine in a
  // plain test() never returned here without runAsync).
  testWidgets(
    'WordToPdfUseCase handles Persian/Arabic-script text (regression - used '
    'to crash: PdfStandardFont only supports WinAnsi/Latin-1)',
    (tester) async {
      late String extracted;
      await tester.runAsync(() async {
        final farsiTempDir = await Directory.systemTemp.createTemp(
          'purapdf_pdf_word_farsi_test_',
        );
        PathProviderPlatform.instance = _FakePathProvider(farsiTempDir);
        addTearDown(() {
          if (farsiTempDir.existsSync()) {
            farsiTempDir.deleteSync(recursive: true);
          }
        });

        final docxPath = '${farsiTempDir.path}/farsi.docx';
        final bytes = DocxWriter.write(const [
          DocxParagraph(text: 'یادداشت جلسه', headingLevel: 1),
          DocxParagraph(text: 'این یک متن فارسی است که باید تبدیل شود.'),
          // Mixed script in one paragraph - a Latin acronym embedded in a
          // Farsi sentence, the realistic common case.
          DocxParagraph(text: 'این یک PDF است.'),
        ]);
        await File(docxPath).writeAsBytes(bytes);

        final useCase = WordToPdfUseCase(PdfRepositoryImpl());
        final outPath = await useCase(docxPath);

        final doc = PdfDocument(inputBytes: File(outPath).readAsBytesSync());
        extracted = PdfTextExtractor(doc).extractText();
        doc.dispose();
      });

      // Not expect(extracted, contains('یادداشت جلسه')): Arabic-script
      // paragraphs are drawn through a hand-rolled shape+bidi+multi-font
      // pipeline (see _drawMixedScriptParagraph), and extraction reads
      // back what was actually drawn - shaped presentation-form glyphs
      // (a different, but equally valid, set of codepoints than the
      // original base letters), in visual (reversed) order, one extracted
      // "line" per script run rather than per paragraph. So the original
      // literal Farsi string never round-trips through extraction even
      // when the PDF renders perfectly - confirmed by rendering this
      // exact case to a PNG during development and inspecting it
      // (correct letter joining, correct RTL order, "PDF" visible and
      // properly spaced). What extraction *can* verify: real Arabic-script
      // glyphs were actually drawn (not skipped/crashed past), and the
      // embedded Latin word survived (the regression this test was
      // originally written to catch, and the one the shape/bidi pipeline
      // re-introduced before the run-splitting fix - see git history).
      expect(extracted, contains('PDF'));
      expect(extracted.runes.any(_isArabicScriptRune), isTrue);
    },
  );
}

bool _isArabicScriptRune(int c) =>
    (c >= 0x0600 && c <= 0x06FF) ||
    (c >= 0x0750 && c <= 0x077F) ||
    (c >= 0x08A0 && c <= 0x08FF) ||
    (c >= 0xFB50 && c <= 0xFDFF) ||
    (c >= 0xFE70 && c <= 0xFEFF);
