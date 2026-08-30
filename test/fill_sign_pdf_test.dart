// Functional test for the Fill & Sign use case: builds a PDF with a real
// AcroForm (one text field, one checkbox), fills them in, and confirms the
// output is genuinely flattened - the form is gone and the typed text is
// now ordinary page content, not just a form field carrying a new value.
import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:purapdf/data/repositories/pdf_repository_impl.dart';
import 'package:purapdf/domain/entities/pdf_form_field.dart';
import 'package:purapdf/domain/entities/pdf_form_fill.dart';
import 'package:purapdf/domain/usecases/fill_sign_pdf_usecase.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final Directory dir;
  _FakePathProvider(this.dir);

  @override
  Future<String?> getApplicationDocumentsPath() async => dir.path;
}

Future<String> _writeFormPdf(String path) async {
  final doc = PdfDocument();
  final page = doc.pages.add();
  page.graphics.drawString(
    'Name:',
    PdfStandardFont(PdfFontFamily.helvetica, 14),
    bounds: const Rect.fromLTWH(40, 40, 60, 20),
  );
  doc.form.fields.add(
    PdfTextBoxField(
      page,
      'Name',
      const Rect.fromLTWH(110, 40, 200, 20),
    ),
  );
  page.graphics.drawString(
    'Agree:',
    PdfStandardFont(PdfFontFamily.helvetica, 14),
    bounds: const Rect.fromLTWH(40, 80, 60, 20),
  );
  doc.form.fields.add(
    PdfCheckBoxField(page, 'Agree', const Rect.fromLTWH(110, 80, 16, 16)),
  );
  final bytes = await doc.save();
  doc.dispose();
  await File(path).writeAsBytes(bytes, flush: true);
  return path;
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('purapdf_fillsign_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir);
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('extractFormFields finds the text field and checkbox with their kinds', () async {
    final source = await _writeFormPdf('${tempDir.path}/form_source.pdf');
    final repo = PdfRepositoryImpl();

    final fields = await repo.extractFormFields(source);

    expect(fields.length, 2);
    expect(fields[0].kind, PdfFormFieldKind.text);
    expect(fields[1].kind, PdfFormFieldKind.checkbox);
  });

  test(
    'FillSignPdfUseCase fills the fields and permanently flattens the form',
    () async {
      final source = await _writeFormPdf('${tempDir.path}/form_source.pdf');
      final repo = PdfRepositoryImpl();
      final fields = await repo.extractFormFields(source);

      final useCase = FillSignPdfUseCase(repo);
      final outPath = await useCase(source, [
        PdfFormFill(fieldIndex: fields[0].fieldIndex, text: 'John Doe'),
        PdfFormFill(fieldIndex: fields[1].fieldIndex, checked: true),
      ]);

      final doc = PdfDocument(inputBytes: File(outPath).readAsBytesSync());
      // Genuinely flattened, not just saved-with-values-but-still-editable.
      expect(doc.form.fields.count, 0);

      final String extracted = PdfTextExtractor(doc).extractText();
      expect(extracted, contains('John Doe'));
      doc.dispose();
    },
  );

  test('FillSignPdfUseCase rejects an empty fills list', () async {
    final source = await _writeFormPdf('${tempDir.path}/form_source.pdf');
    final useCase = FillSignPdfUseCase(PdfRepositoryImpl());

    expect(() => useCase(source, const []), throwsArgumentError);
  });
}
