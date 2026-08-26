// Functional tests for the History feature: generated files show up,
// survive rename, disappear on delete, and stale (externally-deleted)
// entries self-heal out of the index.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:purapdf/data/repositories/pdf_repository_impl.dart';
import 'package:purapdf/domain/usecases/delete_history_file_usecase.dart';
import 'package:purapdf/domain/usecases/list_history_usecase.dart';
import 'package:purapdf/domain/usecases/merge_pdfs_usecase.dart';
import 'package:purapdf/domain/usecases/rename_history_file_usecase.dart';
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
  late PdfRepositoryImpl repo;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('purapdf_history_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir);
    repo = PdfRepositoryImpl();
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('a generated file shows up in history', () async {
    final fileA = await _writeDummyPdf('${tempDir.path}/a.pdf', 1);
    final fileB = await _writeDummyPdf('${tempDir.path}/b.pdf', 1);
    final mergedPath = await MergePdfsUseCase(repo)([fileA, fileB]);

    final history = await ListHistoryUseCase(repo)();

    expect(history.any((f) => f.path == mergedPath), isTrue);
  });

  test(
    'renaming updates the history entry, not just the file on disk',
    () async {
      final fileA = await _writeDummyPdf('${tempDir.path}/a.pdf', 1);
      final fileB = await _writeDummyPdf('${tempDir.path}/b.pdf', 1);
      final mergedPath = await MergePdfsUseCase(repo)([fileA, fileB]);

      final newPath = await RenameHistoryFileUseCase(repo)(
        mergedPath,
        'my_document.pdf',
      );

      expect(File(newPath).existsSync(), isTrue);
      expect(File(mergedPath).existsSync(), isFalse);

      final history = await ListHistoryUseCase(repo)();
      expect(history.any((f) => f.path == newPath), isTrue);
      expect(history.any((f) => f.path == mergedPath), isFalse);
      expect(
        history.firstWhere((f) => f.path == newPath).name,
        'my_document.pdf',
      );
    },
  );

  test('deleting removes the file and its history entry', () async {
    final fileA = await _writeDummyPdf('${tempDir.path}/a.pdf', 1);
    final fileB = await _writeDummyPdf('${tempDir.path}/b.pdf', 1);
    final mergedPath = await MergePdfsUseCase(repo)([fileA, fileB]);

    final deleted = await DeleteHistoryFileUseCase(repo)(mergedPath);
    expect(deleted, isTrue);
    expect(File(mergedPath).existsSync(), isFalse);

    final history = await ListHistoryUseCase(repo)();
    expect(history.any((f) => f.path == mergedPath), isFalse);
  });

  test('a file deleted outside the app self-heals out of history', () async {
    final fileA = await _writeDummyPdf('${tempDir.path}/a.pdf', 1);
    final fileB = await _writeDummyPdf('${tempDir.path}/b.pdf', 1);
    final mergedPath = await MergePdfsUseCase(repo)([fileA, fileB]);

    // Delete the file directly, bypassing the repository/index.
    await File(mergedPath).delete();

    final history = await ListHistoryUseCase(repo)();
    expect(history.any((f) => f.path == mergedPath), isFalse);
  });
}
