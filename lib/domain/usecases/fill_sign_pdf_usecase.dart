import '../entities/pdf_form_fill.dart';
import '../repositories/pdf_repository.dart';

/// Fills a PDF's real AcroForm fields with [fills] and permanently flattens
/// the whole form - see [PdfFormFill]'s doc comment for the fieldIndex join
/// key, and `PdfRepository.fillAndSignPdf` for the flatten step itself.
class FillSignPdfUseCase {
  final PdfRepository repository;

  const FillSignPdfUseCase(this.repository);

  Future<String> call(String inputPath, List<PdfFormFill> fills) async {
    if (fills.isEmpty) {
      throw ArgumentError('errorFillAtLeastOneFieldFirst');
    }
    return repository.fillAndSignPdf(inputPath, fills);
  }
}
