import '../repositories/pdf_repository.dart';

class ScanDocumentsUseCase {
  final PdfRepository repository;

  const ScanDocumentsUseCase(this.repository);

  Future<String> call(List<String> scannedImagePaths) {
    if (scannedImagePaths.isEmpty) {
      throw ArgumentError('Scan at least one page.');
    }
    return repository.scannedImagesToPdf(scannedImagePaths);
  }
}
