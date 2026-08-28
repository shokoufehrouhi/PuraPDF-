// Functional test for the Edit Pages use case: builds a multi-page PDF,
// reorders/rotates/drops pages, and checks the rebuilt output.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:purapdf/data/repositories/pdf_repository_impl.dart';
import 'package:purapdf/domain/entities/pdf_page_edit.dart';
import 'package:purapdf/domain/usecases/edit_pdf_pages_usecase.dart';
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
    tempDir = await Directory.systemTemp.createTemp('purapdf_pages_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir);
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('EditPdfPagesUseCase drops, reorders, and rotates pages', () async {
    final source = await _writeDummyPdf('${tempDir.path}/source.pdf', 4);
    final useCase = EditPdfPagesUseCase(PdfRepositoryImpl());

    // Keep pages 3, 1 (0-based: 2, 0) in that order, drop 2 and 4, rotate
    // the first output page 90° and the second 180°.
    final outPath = await useCase(source, const [
      PdfPageEdit(originalIndex: 2, rotationDegrees: 90),
      PdfPageEdit(originalIndex: 0, rotationDegrees: 180),
    ]);

    final doc = PdfDocument(inputBytes: File(outPath).readAsBytesSync());
    expect(doc.pages.count, 2);
    expect(doc.pages[0].rotation, PdfPageRotateAngle.rotateAngle90);
    expect(doc.pages[1].rotation, PdfPageRotateAngle.rotateAngle180);
    doc.dispose();
  });

  test('EditPdfPagesUseCase rejects an empty edit list', () async {
    final source = await _writeDummyPdf('${tempDir.path}/source.pdf', 2);
    final useCase = EditPdfPagesUseCase(PdfRepositoryImpl());

    expect(() => useCase(source, const []), throwsArgumentError);
  });

  test('EditPdfPagesUseCase rejects an out-of-range page index', () async {
    final source = await _writeDummyPdf('${tempDir.path}/source.pdf', 2);
    final useCase = EditPdfPagesUseCase(PdfRepositoryImpl());

    expect(
      () => useCase(source, const [PdfPageEdit(originalIndex: 5)]),
      throwsArgumentError,
    );
  });
}
