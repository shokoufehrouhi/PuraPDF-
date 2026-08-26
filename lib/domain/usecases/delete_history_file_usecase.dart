import '../repositories/pdf_repository.dart';

class DeleteHistoryFileUseCase {
  final PdfRepository repository;

  const DeleteHistoryFileUseCase(this.repository);

  Future<bool> call(String path) => repository.deleteFile(path);
}
