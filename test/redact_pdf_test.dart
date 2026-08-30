// Functional test for the Redact use case: builds a PDF with real text,
// redacts one line, and confirms it's genuinely gone from extraction - not
// just covered (the one check EditPdfContentUseCase's own test explicitly
// cannot make - see pdf_content_edit.dart's doc comment).
import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:purapdf/data/repositories/pdf_repository_impl.dart';
import 'package:purapdf/domain/entities/pdf_redact_area.dart';
import 'package:purapdf/domain/entities/pdf_text_line.dart';
import 'package:purapdf/domain/entities/pdf_text_word.dart';
import 'package:purapdf/domain/usecases/redact_pdf_usecase.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final Directory dir;
  _FakePathProvider(this.dir);

  @override
  Future<String?> getApplicationDocumentsPath() async => dir.path;
}

Future<String> _writeTextPdf(String path) async {
  final doc = PdfDocument();
  final page = doc.pages.add();
  page.graphics.drawString(
    'Social Security Number: 123-45-6789',
    PdfStandardFont(PdfFontFamily.helvetica, 20),
    bounds: const Rect.fromLTWH(40, 40, 400, 30),
  );
  page.graphics.drawString(
    'This line should survive redaction.',
    PdfStandardFont(PdfFontFamily.helvetica, 20),
    bounds: const Rect.fromLTWH(40, 90, 400, 30),
  );
  final bytes = await doc.save();
  doc.dispose();
  await File(path).writeAsBytes(bytes, flush: true);
  return path;
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('purapdf_redact_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir);
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'RedactPdfUseCase permanently removes a line, not just covers it',
    () async {
      final source = await _writeTextPdf('${tempDir.path}/source.pdf');
      final repo = PdfRepositoryImpl();

      final List<PdfTextLine> lines = await repo.extractTextLines(source);
      expect(lines.length, 2);
      final PdfTextLine sensitive = lines.firstWhere(
        (l) => l.text.contains('Security Number'),
      );
      final PdfTextLine safe = lines.firstWhere(
        (l) => l.text.contains('survive'),
      );

      final useCase = RedactPdfUseCase(repo);
      final outPath = await useCase(source, [
        PdfRedactArea(
          pageIndex: sensitive.pageIndex,
          left: sensitive.left,
          top: sensitive.top,
          width: sensitive.width,
          height: sensitive.height,
        ),
      ]);

      final doc = PdfDocument(inputBytes: File(outPath).readAsBytesSync());
      expect(doc.pages.count, 1);
      doc.dispose();

      final String extracted = PdfTextExtractor(
        PdfDocument(inputBytes: File(outPath).readAsBytesSync()),
      ).extractText();

      // The key assertion: genuinely removed, not just covered.
      expect(extracted, isNot(contains('123-45-6789')));
      expect(extracted, isNot(contains('Security Number')));
      // The other line must survive untouched.
      expect(extracted, contains(safe.text));
    },
  );

  test('RedactPdfUseCase rejects an empty area list', () async {
    final source = await _writeTextPdf('${tempDir.path}/source.pdf');
    final useCase = RedactPdfUseCase(PdfRepositoryImpl());

    expect(() => useCase(source, const []), throwsArgumentError);
  });

  test(
    'RedactPdfUseCase removes just one word out of a line, not the whole '
    'line - the neighboring words on either side must survive at their '
    'original position (verified by rendering to a PNG during '
    'development - this only re-checks via extraction, which can\'t see '
    'position, but does prove nothing extra was dropped)',
    () async {
      final doc = PdfDocument();
      final page = doc.pages.add();
      page.graphics.drawString(
        'My name is CONFIDENTIAL and I live here',
        PdfStandardFont(PdfFontFamily.helvetica, 20),
        bounds: const Rect.fromLTWH(40, 40, 500, 30),
      );
      final source = '${tempDir.path}/word_source.pdf';
      await File(source).writeAsBytes(await doc.save());
      doc.dispose();

      final repo = PdfRepositoryImpl();
      final List<PdfTextWord> words = await repo.extractTextWords(source);
      final PdfTextWord target = words.firstWhere(
        (w) => w.text == 'CONFIDENTIAL',
      );

      final useCase = RedactPdfUseCase(repo);
      final outPath = await useCase(source, [
        PdfRedactArea(
          pageIndex: target.pageIndex,
          left: target.left,
          top: target.top,
          width: target.width,
          height: target.height,
        ),
      ]);

      final String extracted = PdfTextExtractor(
        PdfDocument(inputBytes: File(outPath).readAsBytesSync()),
      ).extractText();

      expect(extracted, isNot(contains('CONFIDENTIAL')));
      expect(extracted, contains('My name is'));
      expect(extracted, contains('and I live here'));
    },
  );

  test('RedactPdfUseCase removes a dragged range of consecutive words', () async {
    final doc = PdfDocument();
    final page = doc.pages.add();
    page.graphics.drawString(
      'Patient John Smith was admitted yesterday',
      PdfStandardFont(PdfFontFamily.helvetica, 20),
      bounds: const Rect.fromLTWH(40, 40, 500, 30),
    );
    final source = '${tempDir.path}/range_source.pdf';
    await File(source).writeAsBytes(await doc.save());
    doc.dispose();

    final repo = PdfRepositoryImpl();
    final List<PdfTextWord> words = await repo.extractTextWords(source);
    final PdfTextWord john = words.firstWhere((w) => w.text == 'John');
    final PdfTextWord smith = words.firstWhere((w) => w.text == 'Smith');

    final useCase = RedactPdfUseCase(repo);
    final outPath = await useCase(source, [
      PdfRedactArea(
        pageIndex: john.pageIndex,
        left: john.left,
        top: john.top,
        width: (smith.left + smith.width) - john.left,
        height: john.height,
      ),
    ]);

    final String extracted = PdfTextExtractor(
      PdfDocument(inputBytes: File(outPath).readAsBytesSync()),
    ).extractText();

    expect(extracted, isNot(contains('John')));
    expect(extracted, isNot(contains('Smith')));
    expect(extracted, contains('Patient'));
    expect(extracted, contains('admitted yesterday'));
  });
}
