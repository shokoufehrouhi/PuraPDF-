import '../entities/pdf_content_edit.dart';
import '../repositories/pdf_repository.dart';

/// Applies content edits (text replace/delete, image insert — see
/// [PdfContentEdit]) directly onto an existing PDF's pages.
class EditPdfContentUseCase {
  final PdfRepository repository;

  const EditPdfContentUseCase(this.repository);

  Future<String> call(String inputPath, List<PdfContentEdit> edits) async {
    if (edits.isEmpty) {
      throw ArgumentError('Make at least one change before saving.');
    }
    return repository.editPdfContent(inputPath, edits);
  }
}
