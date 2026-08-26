// Functional test for the Merge PDF use case, run entirely off-device:
// builds two tiny in-memory PDFs, merges them through the real repository
// implementation, and checks the output file/page count.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:purapdf/data/repositories/pdf_repository_impl.dart';
import 'package:purapdf/domain/usecases/merge_pdfs_usecase.dart';
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
    tempDir = await Directory.systemTemp.createTemp('purapdf_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir);
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('MergePdfsUseCase combines page counts into one valid PDF', () async {
    final fileA = await _writeDummyPdf('${tempDir.path}/a.pdf', 2);
    final fileB = await _writeDummyPdf('${tempDir.path}/b.pdf', 3);

    final useCase = MergePdfsUseCase(PdfRepositoryImpl());
    final outputPath = await useCase([fileA, fileB]);

    final outFile = File(outputPath);
    expect(outFile.existsSync(), isTrue);

    final merged = PdfDocument(inputBytes: outFile.readAsBytesSync());
    expect(merged.pages.count, 5);
    merged.dispose();
  });

  test('MergePdfsUseCase rejects fewer than 2 files', () async {
    final fileA = await _writeDummyPdf('${tempDir.path}/only.pdf', 1);
    final useCase = MergePdfsUseCase(PdfRepositoryImpl());
    expect(() => useCase([fileA]), throwsArgumentError);
  });
}
