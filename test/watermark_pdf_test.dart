// Functional test for the Watermark use case: stamps text across a
// multi-page PDF and checks it was actually drawn (re-extractable) on
// every page.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:purapdf/data/repositories/pdf_repository_impl.dart';
import 'package:purapdf/domain/entities/watermark_options.dart';
import 'package:purapdf/domain/usecases/watermark_pdf_usecase.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final Directory dir;
  _FakePathProvider(this.dir);

  @override
  Future<String?> getApplicationDocumentsPath() async => dir.path;
}

Future<String> _writeDummyPdf(String path, int pageCount) async {
  final doc = PdfDocument();
  for (int i = 0; i < pageCount; i++) {
    doc.pages.add();
  }
  final bytes = await doc.save();
  doc.dispose();
  await File(path).writeAsBytes(bytes, flush: true);
  return path;
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'purapdf_watermark_test_',
    );
    PathProviderPlatform.instance = _FakePathProvider(tempDir);
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'WatermarkPdfUseCase stamps text on every page without changing page count',
    () async {
      final source = await _writeDummyPdf('${tempDir.path}/source.pdf', 3);
      final useCase = WatermarkPdfUseCase(PdfRepositoryImpl());

      final outPath = await useCase(
        source,
        const WatermarkOptions(
          text: 'CONFIDENTIAL',
          opacity: 0.3,
          fontSize: 60,
          colorR: 128,
          colorG: 128,
          colorB: 128,
        ),
      );

      final doc = PdfDocument(inputBytes: File(outPath).readAsBytesSync());
      expect(doc.pages.count, 3);
      final extracted = PdfTextExtractor(doc).extractText();
      doc.dispose();

      // Once per page.
      expect('CONFIDENTIAL'.allMatches(extracted).length, 3);
    },
  );

  test('WatermarkPdfUseCase rejects empty text', () async {
    final source = await _writeDummyPdf('${tempDir.path}/source.pdf', 1);
    final useCase = WatermarkPdfUseCase(PdfRepositoryImpl());

    expect(
      () => useCase(
        source,
        const WatermarkOptions(
          text: '',
          opacity: 0.3,
          fontSize: 60,
          colorR: 0,
          colorG: 0,
          colorB: 0,
        ),
      ),
      throwsArgumentError,
    );
  });
}
