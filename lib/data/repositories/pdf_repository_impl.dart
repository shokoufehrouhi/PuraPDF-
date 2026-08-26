import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../domain/entities/compress_result.dart';
import '../../domain/entities/compression_level.dart';
import '../../domain/entities/page_range.dart';
import '../../domain/repositories/pdf_repository.dart';

/// Syncfusion-backed implementation of [PdfRepository].
///
/// Page copies are done by rendering each source page onto a fresh page in
/// the output document (via [PdfPage.createTemplate]) rather than relying on
/// a single-call "merge"/"split" API, since that keeps output page sizes
/// faithful to each source page.
class PdfRepositoryImpl implements PdfRepository {
  @override
  Future<CompressResult> compressPdf(
    String inputPath,
    CompressionLevel level,
  ) async {
    final File inputFile = File(inputPath);
    final int originalSize = await inputFile.length();

    final PdfDocument doc = await _loadDocument(inputPath);
    doc.compressionLevel = _mapCompressionLevel(level);
    final List<int> outBytes = await doc.save();
    doc.dispose();

    final Directory dir = await getApplicationDocumentsDirectory();
    final String outPath =
        '${dir.path}/purapdf_compressed_${DateTime.now().millisecondsSinceEpoch}.pdf';
    await File(outPath).writeAsBytes(outBytes, flush: true);

    return CompressResult(
      outputPath: outPath,
      originalSizeBytes: originalSize,
      compressedSizeBytes: outBytes.length,
    );
  }

  /// NOTE: this compresses the PDF's internal streams (fonts, text, vector
  /// content) via zlib deflate — a real, lossless reduction, but it does
  /// **not** re-encode embedded images at a lower quality. Syncfusion's
  /// Flutter PDF API (this version) does not expose image extraction/
  /// re-encoding, so photo-heavy PDFs (already JPEG-compressed) will shrink
  /// little or not at all. True image requantization is tracked as a
  /// follow-up (see roadmap Phase 1 notes) and would need either a lower-
  /// level PDF stream editor or a native/platform image pipeline.
  PdfCompressionLevel _mapCompressionLevel(CompressionLevel level) {
    switch (level) {
      case CompressionLevel.low:
        return PdfCompressionLevel.belowNormal;
      case CompressionLevel.medium:
        return PdfCompressionLevel.aboveNormal;
      case CompressionLevel.high:
        return PdfCompressionLevel.best;
    }
  }
  @override
  Future<String> mergePdfs(List<String> inputPaths) async {
    final PdfDocument output = PdfDocument();
    output.pageSettings.margins.all = 0;

    for (final inputPath in inputPaths) {
      final PdfDocument source = await _loadDocument(inputPath);
      for (int i = 0; i < source.pages.count; i++) {
        _copyPage(source.pages[i], output);
      }
      source.dispose();
    }

    final outPath = await _writeOutput(
      output,
      'purapdf_merged_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    return outPath;
  }

  @override
  Future<int> getPageCount(String path) async {
    final PdfDocument doc = await _loadDocument(path);
    final int count = doc.pages.count;
    doc.dispose();
    return count;
  }

  @override
  Future<List<String>> splitPdf(
    String inputPath,
    List<PageRange> ranges,
  ) async {
    final PdfDocument source = await _loadDocument(inputPath);
    final int pageCount = source.pages.count;
    for (final range in ranges) {
      if (range.end > pageCount) {
        source.dispose();
        throw ArgumentError(
          'Range $range exceeds document page count ($pageCount).',
        );
      }
    }

    final int ts = DateTime.now().millisecondsSinceEpoch;
    final List<String> outputPaths = [];

    for (int idx = 0; idx < ranges.length; idx++) {
      final range = ranges[idx];
      final PdfDocument output = PdfDocument();
      output.pageSettings.margins.all = 0;

      for (int p = range.start; p <= range.end; p++) {
        _copyPage(source.pages[p - 1], output);
      }

      final outPath = await _writeOutput(
        output,
        'purapdf_split_${ts}_part${idx + 1}.pdf',
      );
      outputPaths.add(outPath);
    }

    source.dispose();
    return outputPaths;
  }

  @override
  Future<String> zipFiles(List<String> filePaths, String zipName) async {
    final Directory dir = await getApplicationDocumentsDirectory();
    final String zipPath = '${dir.path}/$zipName';
    final encoder = ZipFileEncoder();
    encoder.create(zipPath);
    for (final path in filePaths) {
      await encoder.addFile(File(path));
    }
    await encoder.close();
    return zipPath;
  }

  /// Copies [sourcePage] onto a new page appended to [output], preserving
  /// the source page's size (switching `pageSettings.size` before each
  /// `add()` starts a fresh section whenever the size changes — see
  /// `PdfPageCollection.addPage`, which clones `document.pageSettings` into
  /// a new section on change).
  void _copyPage(PdfPage sourcePage, PdfDocument output) {
    final PdfTemplate template = sourcePage.createTemplate();
    output.pageSettings.size = sourcePage.size;
    final PdfPage newPage = output.pages.add();
    newPage.graphics.drawPdfTemplate(template, Offset.zero);
  }

  Future<PdfDocument> _loadDocument(String path) async {
    final Uint8List bytes = await File(path).readAsBytes();
    return PdfDocument(inputBytes: bytes);
  }

  Future<String> _writeOutput(PdfDocument output, String fileName) async {
    final List<int> bytes = await output.save();
    output.dispose();

    final Directory dir = await getApplicationDocumentsDirectory();
    final String outPath = '${dir.path}/$fileName';
    await File(outPath).writeAsBytes(bytes, flush: true);
    return outPath;
  }
}
