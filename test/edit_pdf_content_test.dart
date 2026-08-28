// Functional test for the Edit PDF (content) use case: builds a PDF with
// real text, replaces one line and deletes another, inserts an image, and
// checks the rebuilt output.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:purapdf/data/repositories/pdf_repository_impl.dart';
import 'package:purapdf/domain/entities/pdf_content_edit.dart';
import 'package:purapdf/domain/entities/pdf_text_line.dart';
import 'package:purapdf/domain/usecases/edit_pdf_content_usecase.dart';
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
    'Hello wrold',
    PdfStandardFont(PdfFontFamily.helvetica, 20),
    bounds: const Rect.fromLTWH(40, 40, 300, 30),
  );
  page.graphics.drawString(
    'This sentence should be removed.',
    PdfStandardFont(PdfFontFamily.helvetica, 20),
    bounds: const Rect.fromLTWH(40, 90, 400, 30),
  );
  final bytes = await doc.save();
  doc.dispose();
  await File(path).writeAsBytes(bytes, flush: true);
  return path;
}

Uint8List _tinyPng() {
  final image = img.Image(width: 4, height: 4);
  img.fill(image, color: img.ColorRgb8(255, 0, 0));
  return Uint8List.fromList(img.encodePng(image));
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('purapdf_content_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir);
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'EditPdfContentUseCase replaces a line, deletes another, inserts an image',
    () async {
      final source = await _writeTextPdf('${tempDir.path}/source.pdf');
      final repo = PdfRepositoryImpl();

      final List<PdfTextLine> lines = await repo.extractTextLines(source);
      expect(lines.length, 2);
      final PdfTextLine typo = lines.firstWhere((l) => l.text.contains('wrold'));
      final PdfTextLine sentence = lines.firstWhere(
        (l) => l.text.contains('removed'),
      );

      final useCase = EditPdfContentUseCase(repo);
      final outPath = await useCase(source, [
        PdfTextReplace(
          pageIndex: typo.pageIndex,
          left: typo.left,
          top: typo.top,
          width: typo.width,
          height: typo.height,
          fontName: typo.fontName,
          fontSize: typo.fontSize,
          newText: 'Hello world',
        ),
        PdfTextReplace(
          pageIndex: sentence.pageIndex,
          left: sentence.left,
          top: sentence.top,
          width: sentence.width,
          height: sentence.height,
          fontName: sentence.fontName,
          fontSize: sentence.fontSize,
          newText: '', // delete
        ),
        PdfImageInsert(
          pageIndex: 0,
          imageBytes: _tinyPng(),
          left: 40,
          top: 140,
          width: 60,
          height: 60,
        ),
      ]);

      final doc = PdfDocument(inputBytes: File(outPath).readAsBytesSync());
      expect(doc.pages.count, 1);
      doc.dispose();

      final String extracted = PdfTextExtractor(
        PdfDocument(inputBytes: File(outPath).readAsBytesSync()),
      ).extractText();
      expect(extracted, contains('Hello world'));

      final int originalSize = File(source).lengthSync();
      final int outSize = File(outPath).lengthSync();
      expect(outSize, greaterThan(originalSize)); // image bytes were added
    },
  );

  test('EditPdfContentUseCase rejects an empty edit list', () async {
    final source = await _writeTextPdf('${tempDir.path}/source.pdf');
    final useCase = EditPdfContentUseCase(PdfRepositoryImpl());

    expect(() => useCase(source, const []), throwsArgumentError);
  });
}
