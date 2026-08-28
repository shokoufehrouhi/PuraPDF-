import '../entities/compress_result.dart';
import '../entities/compression_level.dart';
import '../entities/history_file.dart';
import '../entities/image_output_format.dart';
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

  /// Combines [imagePaths] (any format the platform can decode — JPEG, PNG,
  /// ...) into a single PDF, one image per page, in the given order.
  Future<String> imagesToPdf(List<String> imagePaths);

  /// Same as [imagesToPdf], but written under the scanner's own filename
  /// prefix so Recents shows it as "Scan" rather than "Image -> PDF".
  Future<String> scannedImagesToPdf(List<String> imagePaths);

  /// Renders every page of the PDF at [inputPath] as a raster image in
  /// [format] and returns one output path per page, in page order.
  Future<List<String>> pdfToImages(
    String inputPath, {
    required ImageOutputFormat format,
  });

  /// Lists every file PuraPDF has generated on-device, most recent first.
  Future<List<HistoryFile>> listGeneratedFiles();

  /// Deletes the file at [path]. Returns false if it did not exist.
  Future<bool> deleteFile(String path);

  /// Renames the file at [path] to [newName] (same directory) and returns
  /// the new path.
  Future<String> renameFile(String path, String newName);
}
