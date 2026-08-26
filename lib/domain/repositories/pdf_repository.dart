import '../entities/compress_result.dart';
import '../entities/compression_level.dart';
import '../entities/page_range.dart';

/// Abstract contract for PDF operations. Implementations live in the data
/// layer so the domain/presentation layers never depend on a specific PDF
/// engine (currently Syncfusion).
abstract class PdfRepository {
  /// Merges [inputPaths] (in the given order) into a single PDF file and
  /// returns the path of the generated file.
  Future<String> mergePdfs(List<String> inputPaths);

  /// Re-saves the PDF at [inputPath] with stream compression at [level] and
  /// returns the before/after sizes.
  Future<CompressResult> compressPdf(String inputPath, CompressionLevel level);

  /// Returns the page count of the PDF at [path].
  Future<int> getPageCount(String path);

  /// Splits the PDF at [inputPath] into one output file per [ranges] entry
  /// (in order) and returns the generated file paths.
  Future<List<String>> splitPdf(String inputPath, List<PageRange> ranges);

  /// Bundles [filePaths] into a single ZIP file and returns its path.
  Future<String> zipFiles(List<String> filePaths, String zipName);
}
