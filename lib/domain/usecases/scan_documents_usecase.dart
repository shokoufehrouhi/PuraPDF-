import '../repositories/pdf_repository.dart';

class ScanDocumentsUseCase {
  final PdfRepository repository;

  const ScanDocumentsUseCase(this.repository);

  Future<String> call(List<String> scannedImagePaths, {bool ocr = false}) {
    if (scannedImagePaths.isEmpty) {
      throw ArgumentError('errorScanAtLeastOnePage');
    }
    return repository.scannedImagesToPdf(scannedImagePaths, ocr: ocr);
  }
}
