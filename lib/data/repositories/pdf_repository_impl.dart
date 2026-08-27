import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:archive/archive_io.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart' as rx;
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../domain/entities/compress_result.dart';
import '../../domain/entities/compression_level.dart';
import '../../domain/entities/history_file.dart';
import '../../domain/entities/image_output_format.dart';
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
    final int originalSize = await File(inputPath).length();

    // Low/Medium: lossless stream (font/text/vector) compression - keeps
    // text selectable/searchable, but barely touches image-heavy PDFs.
    // High: rasterize every page to a lower-DPI JPEG and rebuild the PDF
    // from those images - a real size win on photo/scan-heavy PDFs, traded
    // against losing selectable text on the compressed output. See
    // _compressByRasterizing's doc comment.
    String outPath = level == CompressionLevel.high
        ? await _compressByRasterizing(inputPath)
        : await _compressByStream(inputPath, level);
    int compressedSize = await File(outPath).length();

    // Rasterizing a text/vector-heavy page (sharp edges, lots of small
    // detail) as JPEG is often *larger* than the original's efficient
    // vector/text encoding - the opposite of "compress". Never ship a
    // result bigger than the input: fall back to stream compression, and
    // as a last resort a plain copy of the original (0% smaller, never
    // negative), rather than silently returning a bloated "compressed" file.
    if (compressedSize >= originalSize) {
      if (level == CompressionLevel.high) {
        final String streamPath = await _compressByStream(
          inputPath,
          CompressionLevel.high,
        );
        final int streamSize = await File(streamPath).length();
        if (streamSize < compressedSize) {
          outPath = streamPath;
          compressedSize = streamSize;
        }
      }
      if (compressedSize >= originalSize) {
        final Directory dir = await getApplicationDocumentsDirectory();
        final String copyPath =
            '${dir.path}/purapdf_compressed_${DateTime.now().millisecondsSinceEpoch}.pdf';
        await File(inputPath).copy(copyPath);
        await _recordGenerated(copyPath);
        outPath = copyPath;
        compressedSize = originalSize;
      }
    }

    return CompressResult(
      outputPath: outPath,
      originalSizeBytes: originalSize,
      compressedSizeBytes: compressedSize,
    );
  }

  Future<String> _compressByStream(
    String inputPath,
    CompressionLevel level,
  ) async {
    final PdfDocument doc = await _loadDocument(inputPath);
    doc.compressionLevel = _mapCompressionLevel(level);
    return _writeOutput(
      doc,
      'purapdf_compressed_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

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

  /// Renders each page at a reduced scale (1.3x = ~94dpi, vs. ~144dpi for
  /// the Image<->PDF feature) and re-encodes it as a JPEG at quality 40,
  /// then rebuilds a PDF from those images (same [PdfBitmap] approach as
  /// [imagesToPdf]). Uses pdfrx for rendering, since Syncfusion's Flutter
  /// PDF API has no page-to-raster export (see [pdfToImages]).
  ///
  /// This genuinely shrinks image/scan-heavy PDFs, unlike the stream-only
  /// compression above — but every page becomes a flat raster image, so the
  /// output loses selectable/searchable text. That tradeoff is inherent to
  /// rasterizing; it is not something a lower-level fix removes.
  Future<String> _compressByRasterizing(String inputPath) async {
    final rx.PdfDocument source = await rx.PdfDocument.openFile(inputPath);
    final PdfDocument output = PdfDocument();
    output.pageSettings.margins.all = 0;

    try {
      for (int i = 0; i < source.pages.length; i++) {
        final rx.PdfPage page = source.pages[i];
        final int width = (page.width * 1.3).round();
        final int height = (page.height * 1.3).round();
        // fullWidth/fullHeight (not width/height!) control the actual
        // render scale — passing width/height alone renders the page at
        // its natural 72dpi size into the top-left corner of a width x
        // height canvas, leaving the rest blank. See PdfPage.render's doc
        // comment.
        final rx.PdfImage? rendered = await page.render(
          fullWidth: width.toDouble(),
          fullHeight: height.toDouble(),
        );
        if (rendered == null) continue;

        final img.Image image = img.Image.fromBytes(
          width: rendered.width,
          height: rendered.height,
          bytes: rendered.pixels.buffer,
          numChannels: 4,
          order: img.ChannelOrder.bgra,
        );
        rendered.dispose();
        final List<int> jpegBytes = img.encodeJpg(image, quality: 40);

        final PdfBitmap bitmap = PdfBitmap(jpegBytes);
        output.pageSettings.size = Size(page.width, page.height);
        final PdfPage newPage = output.pages.add();
        newPage.graphics.drawImage(
          bitmap,
          Rect.fromLTWH(0, 0, page.width, page.height),
        );
      }
    } finally {
      await source.dispose();
    }

    return _writeOutput(
      output,
      'purapdf_compressed_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
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
    await _recordGenerated(zipPath);
    return zipPath;
  }

  @override
  Future<String> imagesToPdf(List<String> imagePaths) async {
    const double maxDimension = 842; // cap so huge camera photos stay sane
    final PdfDocument output = PdfDocument();
    output.pageSettings.margins.all = 0;

    for (final imagePath in imagePaths) {
      final Uint8List bytes = await File(imagePath).readAsBytes();
      final PdfBitmap bitmap = PdfBitmap(bytes);

      double w = bitmap.width.toDouble();
      double h = bitmap.height.toDouble();
      if (w > maxDimension || h > maxDimension) {
        final double scale = maxDimension / (w > h ? w : h);
        w *= scale;
        h *= scale;
      }

      output.pageSettings.size = Size(w, h);
      final PdfPage page = output.pages.add();
      page.graphics.drawImage(bitmap, Rect.fromLTWH(0, 0, w, h));
    }

    return _writeOutput(
      output,
      'purapdf_images_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  @override
  Future<List<String>> pdfToImages(
    String inputPath, {
    required ImageOutputFormat format,
  }) async {
    final rx.PdfDocument doc = await rx.PdfDocument.openFile(inputPath);
    final Directory dir = await getApplicationDocumentsDirectory();
    final int ts = DateTime.now().millisecondsSinceEpoch;
    final List<String> outputPaths = [];

    try {
      for (int i = 0; i < doc.pages.length; i++) {
        final rx.PdfPage page = doc.pages[i];
        // Render at ~144dpi (2x the PDF's 72dpi base) for a usable image.
        // fullWidth/fullHeight (not width/height!) control the actual
        // render scale — passing width/height alone renders the page at
        // its natural 72dpi size into the top-left corner of a width x
        // height canvas, leaving the rest blank. See PdfPage.render's doc
        // comment.
        final int width = (page.width * 2).round();
        final int height = (page.height * 2).round();
        final rx.PdfImage? rendered = await page.render(
          fullWidth: width.toDouble(),
          fullHeight: height.toDouble(),
        );
        if (rendered == null) continue;

        final img.Image image = img.Image.fromBytes(
          width: rendered.width,
          height: rendered.height,
          bytes: rendered.pixels.buffer,
          numChannels: 4,
          order: img.ChannelOrder.bgra,
        );
        rendered.dispose();

        final List<int> encoded = format == ImageOutputFormat.png
            ? img.encodePng(image)
            : img.encodeJpg(image, quality: 90);
        final String outPath =
            '${dir.path}/purapdf_page_${ts}_${i + 1}.${format.extension}';
        await File(outPath).writeAsBytes(encoded, flush: true);
        await _recordGenerated(outPath);
        outputPaths.add(outPath);
      }
    } finally {
      await doc.dispose();
    }

    return outputPaths;
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
    await _recordGenerated(outPath);
    return outPath;
  }

  // --- History index -------------------------------------------------
  //
  // Every method above writes into the same app documents directory, so
  // rather than re-deriving "files we made" from a filename convention
  // (which breaks the moment a file is renamed), we keep a small JSON
  // index of {path, createdAt} alongside the files themselves. It is
  // self-healing: listGeneratedFiles() drops entries whose file no longer
  // exists (e.g. deleted outside the app) instead of erroring.

  Future<File> _indexFile() async {
    final Directory dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/.purapdf_history_index.json');
  }

  Future<List<Map<String, dynamic>>> _readIndex() async {
    final File file = await _indexFile();
    if (!file.existsSync()) return [];
    try {
      final decoded = jsonDecode(await file.readAsString()) as List<dynamic>;
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeIndex(List<Map<String, dynamic>> entries) async {
    final File file = await _indexFile();
    await file.writeAsString(jsonEncode(entries));
  }

  Future<void> _recordGenerated(String path) async {
    final entries = await _readIndex();
    entries.add({'path': path, 'createdAt': DateTime.now().toIso8601String()});
    await _writeIndex(entries);
  }

  @override
  Future<List<HistoryFile>> listGeneratedFiles() async {
    final entries = await _readIndex();
    final List<HistoryFile> files = [];
    final List<Map<String, dynamic>> stillValid = [];

    for (final entry in entries) {
      final String path = entry['path'] as String;
      final File file = File(path);
      if (!file.existsSync()) continue; // dropped: deleted outside the app
      stillValid.add(entry);
      final FileStat stat = await file.stat();
      final DateTime createdAt =
          DateTime.tryParse(entry['createdAt'] as String? ?? '') ??
          stat.modified;
      files.add(
        HistoryFile(
          path: path,
          name: path.split('/').last,
          sizeBytes: stat.size,
          createdAt: createdAt,
        ),
      );
    }

    if (stillValid.length != entries.length) {
      await _writeIndex(stillValid); // self-heal
    }

    files.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return files;
  }

  @override
  Future<bool> deleteFile(String path) async {
    final File file = File(path);
    final bool existed = file.existsSync();
    if (existed) await file.delete();

    final entries = await _readIndex();
    entries.removeWhere((e) => e['path'] == path);
    await _writeIndex(entries);
    return existed;
  }

  @override
  Future<String> renameFile(String path, String newName) async {
    final File file = File(path);
    final String newPath = '${file.parent.path}/$newName';
    final File renamed = await file.rename(newPath);

    final entries = await _readIndex();
    for (final entry in entries) {
      if (entry['path'] == path) {
        entry['path'] = renamed.path;
      }
    }
    await _writeIndex(entries);
    return renamed.path;
  }
}
