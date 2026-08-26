import '../entities/compress_result.dart';
import '../entities/compression_level.dart';
import '../repositories/pdf_repository.dart';

class CompressPdfUseCase {
  final PdfRepository repository;

  const CompressPdfUseCase(this.repository);

  Future<CompressResult> call(String inputPath, CompressionLevel level) {
    return repository.compressPdf(inputPath, level);
  }
}
