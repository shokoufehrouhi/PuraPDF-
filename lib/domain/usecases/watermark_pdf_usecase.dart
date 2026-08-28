import '../entities/watermark_options.dart';
import '../repositories/pdf_repository.dart';

/// Stamps a diagonal text watermark across every page of a PDF.
class WatermarkPdfUseCase {
  final PdfRepository repository;

  const WatermarkPdfUseCase(this.repository);

  Future<String> call(String inputPath, WatermarkOptions options) async {
    if (options.text.trim().isEmpty) {
      throw ArgumentError('Enter watermark text.');
    }
    return repository.watermarkPdf(inputPath, options);
  }
}
