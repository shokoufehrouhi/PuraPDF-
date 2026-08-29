import '../entities/pdf_page_edit.dart';
import '../repositories/pdf_repository.dart';

/// Rebuilds the PDF at [inputPath] keeping only the pages named in [edits],
/// in the given order, each rotated per its own entry.
class EditPdfPagesUseCase {
  final PdfRepository repository;

  const EditPdfPagesUseCase(this.repository);

  Future<String> call(String inputPath, List<PdfPageEdit> edits) async {
    if (edits.isEmpty) {
      throw ArgumentError('errorAtLeastOnePageMustRemainInPdf');
    }
    return repository.editPdfPages(inputPath, edits);
  }
}
