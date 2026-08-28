import '../repositories/pdf_repository.dart';

/// Removes a PDF's password protection, given the correct password.
class DecryptPdfUseCase {
  final PdfRepository repository;

  const DecryptPdfUseCase(this.repository);

  Future<String> call(String inputPath, String password) async {
    if (password.isEmpty) {
      throw ArgumentError('Enter the PDF\'s password.');
    }
    return repository.decryptPdf(inputPath, password);
  }
}
