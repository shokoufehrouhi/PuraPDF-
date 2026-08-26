import '../entities/page_range.dart';
import '../repositories/pdf_repository.dart';

/// Splits one PDF into several, one output file per requested page range.
class SplitPdfUseCase {
  final PdfRepository repository;

  const SplitPdfUseCase(this.repository);

  Future<List<String>> call(String inputPath, List<PageRange> ranges) async {
    if (ranges.isEmpty) {
      throw ArgumentError('Provide at least one page range to split.');
    }
    for (final range in ranges) {
      if (!range.isValid) {
        throw ArgumentError('Invalid page range: $range');
      }
    }
    final pageCount = await repository.getPageCount(inputPath);
    for (final range in ranges) {
      if (range.end > pageCount) {
        throw ArgumentError(
          'Range $range exceeds document page count ($pageCount).',
        );
      }
    }
    return repository.splitPdf(inputPath, ranges);
  }
}
