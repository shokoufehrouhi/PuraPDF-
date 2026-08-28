import '../repositories/pdf_repository.dart';

/// Adds a password to a PDF — both the open (user) and permissions (owner)
/// password are set to the same value, since exposing that distinction to
/// end users adds complexity most won't need.
class EncryptPdfUseCase {
  final PdfRepository repository;

  const EncryptPdfUseCase(this.repository);

  Future<String> call(String inputPath, String password) async {
    if (password.trim().isEmpty) {
      throw ArgumentError('Enter a password.');
    }
    return repository.encryptPdf(inputPath, password);
  }
}
