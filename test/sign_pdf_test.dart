// Functional test for the Digital Signature use case: bakes a signature
// image onto a page and checks the output PDF gained the extra image data
// (page count unchanged, file grew).
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:purapdf/data/repositories/pdf_repository_impl.dart';
import 'package:purapdf/domain/entities/pdf_content_edit.dart';
import 'package:purapdf/domain/usecases/sign_pdf_usecase.dart';
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

Uint8List _tinySignaturePng() {
  final image = img.Image(width: 200, height: 80, numChannels: 4);
  img.fill(image, color: img.ColorRgba8(0, 0, 0, 0));
  img.fillRect(
    image,
    x1: 20,
    y1: 20,
    x2: 180,
    y2: 60,
    color: img.ColorRgba8(0, 0, 0, 255),
  );
  return Uint8List.fromList(img.encodePng(image));
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('purapdf_sign_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir);
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'SignPdfUseCase bakes a signature onto the chosen page',
    () async {
      final source = await _writeDummyPdf('${tempDir.path}/source.pdf', 2);
      final useCase = SignPdfUseCase(PdfRepositoryImpl());

      final outPath = await useCase(
        source,
        PdfImageInsert(
          pageIndex: 1,
          imageBytes: _tinySignaturePng(),
          left: 40,
          top: 500,
          width: 150,
          height: 60,
        ),
      );

      final doc = PdfDocument(inputBytes: File(outPath).readAsBytesSync());
      expect(doc.pages.count, 2);
      doc.dispose();

      final int originalSize = File(source).lengthSync();
      final int outSize = File(outPath).lengthSync();
      expect(outSize, greaterThan(originalSize));
    },
  );

  test('SignPdfUseCase rejects an out-of-range page index', () async {
    final source = await _writeDummyPdf('${tempDir.path}/source.pdf', 1);
    final useCase = SignPdfUseCase(PdfRepositoryImpl());

    expect(
      () => useCase(
        source,
        PdfImageInsert(
          pageIndex: 5,
          imageBytes: _tinySignaturePng(),
          left: 0,
          top: 0,
          width: 100,
          height: 50,
        ),
      ),
      throwsArgumentError,
    );
  });
}
