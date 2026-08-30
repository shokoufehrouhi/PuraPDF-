import '../entities/pdf_redact_area.dart';
import '../repositories/pdf_repository.dart';

/// Permanently removes the marked [PdfRedactArea]s from a PDF - see
/// [PdfRedactArea]'s doc comment for how this differs from
/// [EditPdfContentUseCase]'s cover-only text replace.
class RedactPdfUseCase {
  final PdfRepository repository;

  const RedactPdfUseCase(this.repository);

  Future<String> call(String inputPath, List<PdfRedactArea> areas) async {
    if (areas.isEmpty) {
      throw ArgumentError('errorMarkAtLeastOneLineToRedact');
    }
    return repository.redactPdf(inputPath, areas);
  }
}
