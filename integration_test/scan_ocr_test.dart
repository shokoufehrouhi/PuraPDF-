// Integration test for Scan's OCR option - needs a real device/simulator
// (Android or iOS), since google_mlkit_text_recognition is a real native ML
// model with no macOS/host-VM implementation at all (unlike the pdfrx/
// compress integration tests here, which just need *a* real engine and
// happen to run fine on -d macos). Run with:
//   flutter test integration_test/scan_ocr_test.dart -d <device-id>
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:purapdf/data/repositories/pdf_repository_impl.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Rasterizes [text] onto a plain white PNG - a stand-in for a "scanned"
/// photo of a page, sharp/high-contrast enough for OCR to read reliably.
Future<String> _writeTextImage(String path, String text) async {
  const double width = 900;
  const double height = 300;
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(
    recorder,
    const Rect.fromLTWH(0, 0, width, height),
  );
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, width, height),
    Paint()..color = const Color(0xFFFFFFFF),
  );
  final TextPainter painter = TextPainter(
    text: TextSpan(
      text: text,
      style: const TextStyle(color: Color(0xFF000000), fontSize: 44),
    ),
    textDirection: TextDirection.ltr,
  );
  painter.layout(maxWidth: width - 60);
  painter.paint(canvas, const Offset(30, 110));

  final ui.Image image = await recorder.endRecording().toImage(
    width.toInt(),
    height.toInt(),
  );
  final ByteData? byteData = await image.toByteData(
    format: ui.ImageByteFormat.png,
  );
  image.dispose();
  await File(path).writeAsBytes(byteData!.buffer.asUint8List());
  return path;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'scannedImagesToPdf(ocr: true) makes scanned text searchable',
    (tester) async {
      const String needle = 'PuraPDF OCR integration test line';
      final Directory dir = await getTemporaryDirectory();
      final String imagePath = '${dir.path}/purapdf_ocr_source.png';
      await _writeTextImage(imagePath, needle);

      final repo = PdfRepositoryImpl();
      final String pdfPath = await repo.scannedImagesToPdf(
        [imagePath],
        ocr: true,
      );
      addTearDown(() async {
        await File(imagePath).delete().catchError((_) => File(imagePath));
        await repo.deleteFile(pdfPath);
      });

      final PdfDocument doc = PdfDocument(
        inputBytes: await File(pdfPath).readAsBytes(),
      );
      final String extracted = PdfTextExtractor(doc).extractText();
      doc.dispose();

      // Loose match: OCR word-spacing/casing can wobble a little, but the
      // distinctive "PuraPDF" token surviving is a solid signal recognition
      // actually ran and the text layer is real, extractable text - not
      // just a rendered-looking image.
      expect(extracted, contains('PuraPDF'));
    },
  );

  testWidgets(
    'scannedImagesToPdf(ocr: false) stays plain (no OCR text layer)',
    (tester) async {
      const String needle = 'This text should not be extracted';
      final Directory dir = await getTemporaryDirectory();
      final String imagePath = '${dir.path}/purapdf_ocr_off_source.png';
      await _writeTextImage(imagePath, needle);

      final repo = PdfRepositoryImpl();
      final String pdfPath = await repo.scannedImagesToPdf(
        [imagePath],
        ocr: false,
      );
      addTearDown(() async {
        await File(imagePath).delete().catchError((_) => File(imagePath));
        await repo.deleteFile(pdfPath);
      });

      final PdfDocument doc = PdfDocument(
        inputBytes: await File(pdfPath).readAsBytes(),
      );
      final String extracted = PdfTextExtractor(doc).extractText();
      doc.dispose();

      expect(extracted.trim(), isEmpty);
    },
  );
}
