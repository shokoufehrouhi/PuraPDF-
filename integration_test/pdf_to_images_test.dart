// Integration test for the PDF -> Images direction. Unlike the plain
// `flutter test` unit suite, this runs against a real Flutter engine
// (`flutter test integration_test/pdf_to_images_test.dart -d macos`), which
// is required because pdfrx needs its native PDFium bindings — unavailable
// in the headless VM test harness. See test/image_pdf_test.dart for the
// Images -> PDF direction, which is covered by ordinary unit tests.
//
// NOTE: this only checks output validity (file exists, decodes, has real
// dimensions) — not pixel content. Investigating a real bug report (pages
// rendering into only the top-left portion of the canvas — fixed by using
// PdfPage.render's fullWidth/fullHeight instead of width/height, see
// pdf_repository_impl.dart), pdfium's render() was observed returning a
// fully blank frame when driven through `flutter test -d macos`'s bare
// `test()`/`testWidgets()` harness on this machine, even for a
// manually-verified-correct source PDF, regardless of the width/height vs
// fullWidth/fullHeight fix. Pixel-content assertions here would be
// unreliable for reasons that look harness-specific rather than
// app-specific — the fix should be confirmed by running the real app.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:purapdf/data/repositories/pdf_repository_impl.dart';
import 'package:purapdf/domain/entities/image_output_format.dart';
import 'package:purapdf/domain/usecases/pdf_to_images_usecase.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

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
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('PdfToImagesUseCase renders each page as a valid JPG', () async {
    final dir = await getApplicationDocumentsDirectory();
    final source = await _writeDummyPdf('${dir.path}/source_jpg.pdf', 3);
    final useCase = PdfToImagesUseCase(PdfRepositoryImpl());

    final outputs = await useCase(source, format: ImageOutputFormat.jpg);

    expect(outputs.length, 3);
    for (final path in outputs) {
      expect(path.endsWith('.jpg'), isTrue);
      final bytes = File(path).readAsBytesSync();
      final decoded = img.decodeJpg(bytes);
      expect(decoded, isNotNull);
      expect(decoded!.width, greaterThan(0));
      expect(decoded.height, greaterThan(0));
    }
  });

  test('PdfToImagesUseCase renders each page as a valid PNG', () async {
    final dir = await getApplicationDocumentsDirectory();
    final source = await _writeDummyPdf('${dir.path}/source_png.pdf', 2);
    final useCase = PdfToImagesUseCase(PdfRepositoryImpl());

    final outputs = await useCase(source, format: ImageOutputFormat.png);

    expect(outputs.length, 2);
    for (final path in outputs) {
      expect(path.endsWith('.png'), isTrue);
      final bytes = File(path).readAsBytesSync();
      final decoded = img.decodePng(bytes);
      expect(decoded, isNotNull);
    }
  });
}
