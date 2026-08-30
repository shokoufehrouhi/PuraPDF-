import '../repositories/pdf_repository.dart';

class PdfToWordUseCase {
  final PdfRepository repository;

  const PdfToWordUseCase(this.repository);

  Future<String> call(String inputPath) {
    if (inputPath.isEmpty) {
      throw ArgumentError('errorSelectPdfFirst');
    }
    return repository.pdfToWord(inputPath);
  }
}
