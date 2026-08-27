// Integration test for the "High" compression level, which rasterizes
// pages via pdfrx - needs a real engine (native PDFium bindings), same
// reason as integration_test/pdf_to_images_test.dart. Run with:
//   flutter test integration_test/compress_high_test.dart -d macos
//
// NOTE: only checks size/validity, not pixel content — see the note atop
// pdf_to_images_test.dart on why a pixel-content check was unreliable here.
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:purapdf/data/repositories/pdf_repository_impl.dart';
import 'package:purapdf/domain/entities/compression_level.dart';
import 'package:purapdf/domain/usecases/compress_pdf_usecase.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Builds a single-page PDF wrapping one large image of true per-pixel
/// random noise — like a real photo/scan, lossless (PNG/deflate) formats
/// can't compress it much, but lossy JPEG at a lower quality genuinely
/// shrinks it by discarding high-frequency detail. (A smooth/deterministic
/// pattern would favor PNG's delta filtering unrealistically and defeat the
/// point of this test — it has to be actually hard to compress losslessly.)
Future<String> _writeImageHeavyPdf(String path) async {
  const int width = 1200;
  const int height = 1600;
  final image = img.Image(width: width, height: height);
  final random = Random(42);
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      image.setPixelRgb(
        x,
        y,
        random.nextInt(256),
        random.nextInt(256),
        random.nextInt(256),
      );
    }
  }
  final pngBytes = img.encodePng(image);

  final doc = PdfDocument();
  final bitmap = PdfBitmap(pngBytes);
  doc.pageSettings.size = Size(
    bitmap.width.toDouble(),
    bitmap.height.toDouble(),
  );
  final page = doc.pages.add();
  page.graphics.drawImage(
    bitmap,
    Rect.fromLTWH(0, 0, bitmap.width.toDouble(), bitmap.height.toDouble()),
  );
  final bytes = await doc.save();
  doc.dispose();
  await File(path).writeAsBytes(bytes, flush: true);
  return path;
}

/// A page of dense, sharp-edged text — the pathological case for High:
/// rasterizing lots of small text as JPEG is often *larger* than the
/// original's efficient text-operator encoding (real bug report: "high
/// bishtar shod be jaye kam shodan" on a merged multi-page document).
Future<String> _writeTextHeavyPdf(String path, int pageCount) async {
  final doc = PdfDocument();
  final font = PdfStandardFont(PdfFontFamily.helvetica, 10);
  final line = List.filled(12, 'Lorem ipsum dolor sit amet. ').join();
  for (int p = 0; p < pageCount; p++) {
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
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test(
    'High level meaningfully shrinks an image-heavy PDF, unlike Medium',
    () async {
      final dir = await getApplicationDocumentsDirectory();
      final source = await _writeImageHeavyPdf(
        '${dir.path}/image_heavy_source.pdf',
      );
      final useCase = CompressPdfUseCase(PdfRepositoryImpl());

      final medium = await useCase(source, CompressionLevel.medium);
      final high = await useCase(source, CompressionLevel.high);

      // The whole point of rasterizing: High should be substantially
      // smaller than both the original and the stream-only Medium level.
      expect(high.compressedSizeBytes, lessThan(medium.compressedSizeBytes));
      expect(high.compressedSizeBytes, lessThan(high.originalSizeBytes ~/ 2));

      // Output must still be a valid, readable single-page PDF.
      final reopened = PdfDocument(
        inputBytes: File(high.outputPath).readAsBytesSync(),
      );
      expect(reopened.pages.count, 1);
      reopened.dispose();
    },
  );

  test('High level never returns a file bigger than the original, even on '
      'text-heavy PDFs where rasterizing backfires', () async {
    final dir = await getApplicationDocumentsDirectory();
    final source = await _writeTextHeavyPdf(
      '${dir.path}/text_heavy_source.pdf',
      20,
    );
    final useCase = CompressPdfUseCase(PdfRepositoryImpl());

    final high = await useCase(source, CompressionLevel.high);

    expect(high.compressedSizeBytes, lessThanOrEqualTo(high.originalSizeBytes));
    expect(high.reductionPercent, greaterThanOrEqualTo(0));

    // Output must still be a valid, readable PDF with the same page count
    // (whichever fallback tier kicked in - rasterized, stream-compressed,
    // or a plain copy - must not have dropped/corrupted pages).
    final reopened = PdfDocument(
      inputBytes: File(high.outputPath).readAsBytesSync(),
    );
    expect(reopened.pages.count, 20);
    reopened.dispose();
  });
}
