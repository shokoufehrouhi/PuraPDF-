// Functional test for the Split PDF use case: builds a 6-page PDF, splits
// it into custom ranges and into one-file-per-page, and checks each output.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:purapdf/data/repositories/pdf_repository_impl.dart';
import 'package:purapdf/domain/entities/page_range.dart';
import 'package:purapdf/domain/usecases/split_pdf_usecase.dart';
import 'package:purapdf/presentation/features/split/split_controller.dart';
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

int _pageCountOf(String path) {
  final doc = PdfDocument(inputBytes: File(path).readAsBytesSync());
  final count = doc.pages.count;
  doc.dispose();
  return count;
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('purapdf_split_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir);
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('SplitPdfUseCase splits by custom ranges', () async {
    final source = await _writeDummyPdf('${tempDir.path}/source.pdf', 6);
    final useCase = SplitPdfUseCase(PdfRepositoryImpl());

    final outputs = await useCase(source, [
      const PageRange(1, 3),
      const PageRange(4, 6),
    ]);

    expect(outputs.length, 2);
    expect(_pageCountOf(outputs[0]), 3);
    expect(_pageCountOf(outputs[1]), 3);
  });

  test('SplitPdfUseCase splits into one file per page', () async {
    final source = await _writeDummyPdf('${tempDir.path}/source.pdf', 4);
    final useCase = SplitPdfUseCase(PdfRepositoryImpl());

    final outputs = await useCase(
      source,
      List.generate(4, (i) => PageRange(i + 1, i + 1)),
    );

    expect(outputs.length, 4);
    for (final path in outputs) {
      expect(_pageCountOf(path), 1);
    }
  });

  test('SplitPdfUseCase rejects a range beyond the page count', () async {
    final source = await _writeDummyPdf('${tempDir.path}/source.pdf', 2);
    final useCase = SplitPdfUseCase(PdfRepositoryImpl());

    expect(() => useCase(source, [const PageRange(1, 5)]), throwsArgumentError);
  });

  test('parsePageRanges parses mixed single pages and ranges', () {
    final ranges = parsePageRanges('1-3, 5, 7-9');
    expect(ranges.length, 3);
    expect(ranges[0].start, 1);
    expect(ranges[0].end, 3);
    expect(ranges[1].start, 5);
    expect(ranges[1].end, 5);
    expect(ranges[2].start, 7);
    expect(ranges[2].end, 9);
  });
}
