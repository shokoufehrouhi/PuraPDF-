import '../repositories/pdf_repository.dart';

class RenameHistoryFileUseCase {
  final PdfRepository repository;

  const RenameHistoryFileUseCase(this.repository);

  Future<String> call(String path, String newName) {
    if (newName.trim().isEmpty) {
      throw ArgumentError('New name cannot be empty.');
    }
    return repository.renameFile(path, newName.trim());
  }
}
