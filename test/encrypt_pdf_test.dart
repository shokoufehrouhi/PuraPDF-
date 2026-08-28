// Functional test for the Password Protect use cases: locks a PDF, checks
// it can no longer be opened without the password, then unlocks it and
// checks it opens freely again.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:purapdf/data/repositories/pdf_repository_impl.dart';
import 'package:purapdf/domain/usecases/decrypt_pdf_usecase.dart';
import 'package:purapdf/domain/usecases/encrypt_pdf_usecase.dart';
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
    tempDir = await Directory.systemTemp.createTemp('purapdf_encrypt_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir);
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('EncryptPdfUseCase locks a PDF so it needs a password to open', () async {
    final source = await _writeDummyPdf('${tempDir.path}/source.pdf', 2);
    final useCase = EncryptPdfUseCase(PdfRepositoryImpl());

    final outPath = await useCase(source, 'hunter2');

    expect(
      () => PdfDocument(inputBytes: File(outPath).readAsBytesSync()),
      throwsArgumentError,
    );
    final doc = PdfDocument(
      inputBytes: File(outPath).readAsBytesSync(),
      password: 'hunter2',
    );
    expect(doc.pages.count, 2);
    doc.dispose();
  });

  test(
    'DecryptPdfUseCase removes the password so the PDF opens freely',
    () async {
      final source = await _writeDummyPdf('${tempDir.path}/source.pdf', 2);
      final encryptUseCase = EncryptPdfUseCase(PdfRepositoryImpl());
      final lockedPath = await encryptUseCase(source, 'hunter2');

      final decryptUseCase = DecryptPdfUseCase(PdfRepositoryImpl());
      final unlockedPath = await decryptUseCase(lockedPath, 'hunter2');

      final doc = PdfDocument(
        inputBytes: File(unlockedPath).readAsBytesSync(),
      );
      expect(doc.pages.count, 2);
      doc.dispose();
    },
  );

  test('DecryptPdfUseCase rejects the wrong password', () async {
    final source = await _writeDummyPdf('${tempDir.path}/source.pdf', 1);
    final encryptUseCase = EncryptPdfUseCase(PdfRepositoryImpl());
    final lockedPath = await encryptUseCase(source, 'hunter2');

    final decryptUseCase = DecryptPdfUseCase(PdfRepositoryImpl());
    expect(
      () => decryptUseCase(lockedPath, 'wrong-password'),
      throwsArgumentError,
    );
  });

  test('EncryptPdfUseCase rejects an empty password', () async {
    final source = await _writeDummyPdf('${tempDir.path}/source.pdf', 1);
    final useCase = EncryptPdfUseCase(PdfRepositoryImpl());

    expect(() => useCase(source, ''), throwsArgumentError);
  });

  test('EncryptPdfUseCase rejects a whitespace-only password', () async {
    final source = await _writeDummyPdf('${tempDir.path}/source.pdf', 1);
    final useCase = EncryptPdfUseCase(PdfRepositoryImpl());

    expect(() => useCase(source, '    '), throwsArgumentError);
  });

  test('EncryptPdfUseCase rejects a password containing a space', () async {
    final source = await _writeDummyPdf('${tempDir.path}/source.pdf', 1);
    final useCase = EncryptPdfUseCase(PdfRepositoryImpl());

    expect(() => useCase(source, '12 34'), throwsArgumentError);
  });
}
