import '../repositories/pdf_repository.dart';

/// Merges 2+ PDF files, in the given order, into a single output file.
class MergePdfsUseCase {
  final PdfRepository repository;

  const MergePdfsUseCase(this.repository);

  Future<String> call(List<String> inputPaths) {
    if (inputPaths.length < 2) {
      throw ArgumentError('errorMergeNeedsTwoFiles');
    }
    return repository.mergePdfs(inputPaths);
  }
}
