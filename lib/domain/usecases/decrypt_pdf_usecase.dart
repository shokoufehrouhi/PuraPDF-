import '../repositories/pdf_repository.dart';

/// Removes a PDF's password protection, given the correct password.
class DecryptPdfUseCase {
  final PdfRepository repository;

  const DecryptPdfUseCase(this.repository);

  Future<String> call(String inputPath, String password) async {
    if (password.isEmpty) {
      throw ArgumentError('errorEnterPdfPassword');
    }
    return repository.decryptPdf(inputPath, password);
  }
}
