import '../entities/history_file.dart';
import '../repositories/pdf_repository.dart';

class ListHistoryUseCase {
  final PdfRepository repository;

  const ListHistoryUseCase(this.repository);

  Future<List<HistoryFile>> call() => repository.listGeneratedFiles();
}
