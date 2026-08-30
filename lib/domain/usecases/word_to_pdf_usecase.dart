import '../repositories/pdf_repository.dart';

class WordToPdfUseCase {
  final PdfRepository repository;

  const WordToPdfUseCase(this.repository);

  Future<String> call(String inputPath) {
    if (inputPath.isEmpty) {
      throw ArgumentError('errorSelectWordFirst');
    }
    return repository.wordToPdf(inputPath);
  }
}
