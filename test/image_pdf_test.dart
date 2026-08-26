// Functional tests for the Images -> PDF direction. The PDF -> Images
// direction needs pdfrx's native PDFium bindings, which aren't available in
// the headless `flutter test` VM — that direction is covered by
// integration_test/pdf_to_images_test.dart instead, run against a real
// engine (`flutter test integration_test/pdf_to_images_test.dart -d macos`).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:purapdf/data/repositories/pdf_repository_impl.dart';
import 'package:purapdf/domain/usecases/images_to_pdf_usecase.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final Directory dir;
  _FakePathProvider(this.dir);

  @override
  Future<String?> getApplicationDocumentsPath() async => dir.path;
}

Future<String> _writeSolidColorImage(
  String path, {
  int width = 200,
  int height = 100,
  required int color,
}) async {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(color, color, color));
  await File(path).writeAsBytes(img.encodePng(image), flush: true);
  return path;
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('purapdf_imgpdf_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir);
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'ImagesToPdfUseCase combines images into one PDF, one per page',
    () async {
      final imageA = await _writeSolidColorImage(
        '${tempDir.path}/a.png',
        color: 255,
      );
      final imageB = await _writeSolidColorImage(
        '${tempDir.path}/b.png',
        color: 0,
      );

      final useCase = ImagesToPdfUseCase(PdfRepositoryImpl());
      final outputPath = await useCase([imageA, imageB]);

      final outFile = File(outputPath);
      expect(outFile.existsSync(), isTrue);

      final doc = PdfDocument(inputBytes: outFile.readAsBytesSync());
      expect(doc.pages.count, 2);
      doc.dispose();
    },
  );

  test('ImagesToPdfUseCase rejects an empty selection', () async {
    final useCase = ImagesToPdfUseCase(PdfRepositoryImpl());
    expect(() => useCase([]), throwsArgumentError);
  });
}
