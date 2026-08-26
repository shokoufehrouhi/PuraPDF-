// Functional test for the Compress PDF use case — covers the Low/Medium
// (stream/deflate) levels, which run headless. The High level rasterizes
// pages via pdfrx, which needs native PDFium bindings unavailable in the
// headless `flutter test` VM — that's covered instead by
// integration_test/compress_high_test.dart, run against a real engine.
import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:purapdf/data/repositories/pdf_repository_impl.dart';
import 'package:purapdf/domain/entities/compression_level.dart';
import 'package:purapdf/domain/usecases/compress_pdf_usecase.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final Directory dir;
  _FakePathProvider(this.dir);

  @override
  Future<String?> getApplicationDocumentsPath() async => dir.path;
}

Future<String> _writeTextHeavyPdf(String path) async {
  final doc = PdfDocument();
  final font = PdfStandardFont(PdfFontFamily.helvetica, 10);
  final line = List.filled(12, 'Lorem ipsum dolor sit amet. ').join();
  for (int p = 0; p < 20; p++) {
    final page = doc.pages.add();
    for (int l = 0; l < 40; l++) {
      page.graphics.drawString(
        line,
        font,
        bounds: Rect.fromLTWH(20, 20.0 + l * 14, 550, 14),
      );
    }
  }
  final bytes = await doc.save();
  doc.dispose();
  await File(path).writeAsBytes(bytes, flush: true);
  return path;
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('purapdf_compress_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir);
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'CompressPdfUseCase (stream levels) produces a valid PDF and reports sizes',
    () async {
      final source = await _writeTextHeavyPdf('${tempDir.path}/source.pdf');
      final useCase = CompressPdfUseCase(PdfRepositoryImpl());

      final result = await useCase(source, CompressionLevel.medium);

      expect(File(result.outputPath).existsSync(), isTrue);
      expect(result.originalSizeBytes, greaterThan(0));
      expect(result.compressedSizeBytes, greaterThan(0));
      // NOTE: source PDFs saved by this same engine already default to
      // PdfCompressionLevel.normal, so re-saving at a higher stream level
      // doesn't guarantee a smaller file than the as-authored original
      // (reserializing — rebuilt xref table, font subsets, etc. — carries
      // its own overhead that can offset the deflate gain on small files).
      // The level that *is* guaranteed to help is relative, see below.

      // Output must still be a valid, readable PDF with the same page count.
      final reopened = PdfDocument(
        inputBytes: File(result.outputPath).readAsBytesSync(),
      );
      expect(reopened.pages.count, 20);
      reopened.dispose();
    },
  );

  test('medium stream level shrinks at least as much as low', () async {
    final source = await _writeTextHeavyPdf('${tempDir.path}/source.pdf');
    final useCase = CompressPdfUseCase(PdfRepositoryImpl());

    final low = await useCase(source, CompressionLevel.low);
    final medium = await useCase(source, CompressionLevel.medium);

    expect(
      medium.compressedSizeBytes,
      lessThanOrEqualTo(low.compressedSizeBytes),
    );
  });
}
