import '../entities/image_output_format.dart';
import '../repositories/pdf_repository.dart';

class PdfToImagesUseCase {
  final PdfRepository repository;

  const PdfToImagesUseCase(this.repository);

  Future<List<String>> call(
    String inputPath, {
    required ImageOutputFormat format,
  }) {
    return repository.pdfToImages(inputPath, format: format);
  }
}
