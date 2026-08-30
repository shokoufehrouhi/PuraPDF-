import 'dart:typed_data';

import '../entities/compress_result.dart';
import '../entities/compression_level.dart';
import '../entities/history_file.dart';
import '../entities/image_output_format.dart';
import '../entities/page_range.dart';
import '../entities/pdf_content_edit.dart';
import '../entities/pdf_page_edit.dart';
import '../entities/pdf_page_image.dart';
import '../entities/pdf_redact_area.dart';
import '../entities/pdf_text_line.dart';
import '../entities/pdf_text_word.dart';
import '../entities/watermark_options.dart';

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
  /// prefix so Recents shows it as "Scan" rather than "Image -> PDF". When
  /// [ocr] is true, each page also gets an invisible, searchable/selectable
  /// text layer from on-device text recognition (Latin script only)
  /// positioned under its recognized text; pages with no recognizable text
  /// are unaffected.
  Future<String> scannedImagesToPdf(
    List<String> imagePaths, {
    bool ocr = false,
  });

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

  /// Renders every page of the PDF at [path] as a small in-memory JPEG
  /// thumbnail, in page order. Purely for on-screen preview while editing —
  /// not written to disk and not recorded in history.
  Future<List<Uint8List>> renderPageThumbnails(String path);

  /// Rebuilds the PDF at [inputPath] keeping/reordering/rotating pages per
  /// [edits] (see [PdfPageEdit]) and returns the new file's path.
  Future<String> editPdfPages(String inputPath, List<PdfPageEdit> edits);

  /// Extracts every line of text (with position/font info) from the PDF at
  /// [path] — used by the content editor to overlay a tappable region per
  /// line.
  Future<List<PdfTextLine>> extractTextLines(String path);

  /// Extracts every *word* of text (with position, grouped by the line it
  /// came from) from the PDF at [path] — used by Redact so the user can
  /// mark a single word or a dragged range of words, not just a whole line.
  Future<List<PdfTextWord>> extractTextWords(String path);

  /// Renders every page of the PDF at [path] as an in-memory image, paired
  /// with that page's size in PDF points — used by the content editor's
  /// per-page canvas. Higher scale than [renderPageThumbnails] (which is
  /// preview-only) so tap targets and edits stay legible/accurate.
  Future<List<PdfPageImage>> renderPageImages(String path);

  /// Applies [edits] (see [PdfContentEdit]) directly onto the existing
  /// pages of the PDF at [inputPath] and returns the new file's path.
  Future<String> editPdfContent(String inputPath, List<PdfContentEdit> edits);

  /// Permanently removes [areas] (see [PdfRedactArea]) from the PDF at
  /// [inputPath] and returns the new file's path.
  Future<String> redactPdf(String inputPath, List<PdfRedactArea> areas);

  /// Password-protects the PDF at [inputPath] with [password] (used as both
  /// the open and permissions password) and returns the new file's path.
  Future<String> encryptPdf(String inputPath, String password);

  /// Removes password protection from the PDF at [inputPath], given the
  /// correct [password], and returns the new file's path. Throws if the
  /// password is wrong.
  Future<String> decryptPdf(String inputPath, String password);

  /// Stamps [options]'s text diagonally across every page of the PDF at
  /// [inputPath] and returns the new file's path.
  Future<String> watermarkPdf(String inputPath, WatermarkOptions options);

  /// Bakes [signature] (a drawn or typed signature image, already
  /// positioned via its [PdfImageInsert] fields) onto one page of the PDF
  /// at [inputPath] and returns the new file's path.
  Future<String> signPdf(String inputPath, PdfImageInsert signature);

  /// Extracts the text of the PDF at [inputPath] into a new .docx and
  /// returns its path. Text-only: paragraph-level bold/italic/heading are
  /// preserved, but not images, tables, or exact layout.
  Future<String> pdfToWord(String inputPath);

  /// Extracts the text of the .docx at [inputPath] into a new PDF and
  /// returns its path. Same text-only fidelity as [pdfToWord].
  Future<String> wordToPdf(String inputPath);
}
