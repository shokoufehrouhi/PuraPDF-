import '../repositories/pdf_repository.dart';

class ImagesToPdfUseCase {
  final PdfRepository repository;

  const ImagesToPdfUseCase(this.repository);

  Future<String> call(List<String> imagePaths) {
    if (imagePaths.isEmpty) {
      throw ArgumentError('Select at least one image.');
    }
    return repository.imagesToPdf(imagePaths);
  }
}
