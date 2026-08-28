import '../entities/pdf_content_edit.dart';
import '../repositories/pdf_repository.dart';

/// Bakes a signature image onto one page of a PDF — reuses [PdfImageInsert]
/// (the same "place an image on a page" shape Edit PDF's image insert
/// uses), since a signature is exactly that.
class SignPdfUseCase {
  final PdfRepository repository;

  const SignPdfUseCase(this.repository);

  Future<String> call(String inputPath, PdfImageInsert signature) {
    return repository.signPdf(inputPath, signature);
  }
}
