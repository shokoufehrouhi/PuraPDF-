import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
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
import '../../domain/entities/pdf_content_edit.dart';
import '../../domain/entities/pdf_page_edit.dart';
import '../../domain/entities/pdf_page_image.dart';
import '../../domain/entities/pdf_text_line.dart';
import '../../domain/entities/watermark_options.dart';
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
    //
    // Every attempt below is a real file already written+indexed by
    // _writeOutput (via _compressByRasterizing/_compressByStream) - a
    // superseded attempt has to be explicitly discarded (deleteFile, which
    // also drops its history-index entry) or it would sit on disk forever
    // *and* show up in Recents as an extra, wrong "Compress" result the
    // user never actually got.
    if (compressedSize >= originalSize) {
      if (level == CompressionLevel.high) {
        final String streamPath = await _compressByStream(
          inputPath,
          CompressionLevel.high,
        );
        final int streamSize = await File(streamPath).length();
        if (streamSize < compressedSize) {
          await deleteFile(outPath); // discard the losing rasterized attempt
          outPath = streamPath;
          compressedSize = streamSize;
        } else {
          await deleteFile(streamPath); // discard the losing stream retry
        }
      }
      if (compressedSize >= originalSize) {
        final Directory dir = await getApplicationDocumentsDirectory();
        final String copyPath =
            '${dir.path}/purapdf_compressed_${DateTime.now().millisecondsSinceEpoch}.pdf';
        await File(inputPath).copy(copyPath);
        await deleteFile(outPath); // discard whichever attempt this replaces
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
  Future<String> imagesToPdf(List<String> imagePaths) =>
      _imagesToPdf(imagePaths, 'purapdf_images_');

  @override
  Future<String> scannedImagesToPdf(List<String> imagePaths) =>
      _imagesToPdf(imagePaths, 'purapdf_scan_');

  /// Shared by [imagesToPdf] and [scannedImagesToPdf] — same "one image per
  /// page" assembly either way, just written under a different filename
  /// prefix so Recents can tell "Image -> PDF" and "Scan" apart (see
  /// _operationFor in home_screen.dart).
  Future<String> _imagesToPdf(List<String> imagePaths, String prefix) async {
    const double maxDimension = 842; // cap so huge camera photos stay sane
    final PdfDocument output = PdfDocument();
    output.pageSettings.margins.all = 0;

    for (final imagePath in imagePaths) {
      final Uint8List bytes = await File(imagePath).readAsBytes();
      final PdfBitmap bitmap = PdfBitmap(_normalizeImageBytes(bytes));

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
      '$prefix${DateTime.now().millisecondsSinceEpoch}.pdf',
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
  /// the source page's size.
  ///
  /// Every call starts its own fresh [PdfSection] (`output.sections!.add()`)
  /// rather than reusing `output.pages`/`output.pageSettings` — a section's
  /// `pageSettings` only takes effect for pages added *after* it's set and
  /// *before* the next size/rotate change lands, so sharing one section
  /// across calls with different rotations silently applies the wrong
  /// (usually just the first) rotation to later pages. A dedicated section
  /// per page sidesteps that entirely, matching this class's plain "copy
  /// pages one at a time" style over relying on any single merge/split call.
  ///
  /// [rotationDegrees] (0/90/180/270, clockwise) is written as the new
  /// page's native `/Rotate` entry via `pageSettings.rotate` rather than
  /// transforming the drawn content, so rotated pages stay vector/text (no
  /// rasterizing needed).
  void _copyPage(
    PdfPage sourcePage,
    PdfDocument output, {
    int rotationDegrees = 0,
  }) {
    final PdfTemplate template = sourcePage.createTemplate();
    final PdfSection section = output.sections!.add();
    section.pageSettings.size = sourcePage.size;
    section.pageSettings.rotate = _rotateAngleFor(rotationDegrees);
    final PdfPage newPage = section.pages.add();
    newPage.graphics.drawPdfTemplate(template, Offset.zero);
  }

  PdfPageRotateAngle _rotateAngleFor(int degrees) {
    switch (((degrees % 360) + 360) % 360) {
      case 90:
        return PdfPageRotateAngle.rotateAngle90;
      case 180:
        return PdfPageRotateAngle.rotateAngle180;
      case 270:
        return PdfPageRotateAngle.rotateAngle270;
      default:
        return PdfPageRotateAngle.rotateAngle0;
    }
  }

  Future<PdfDocument> _loadDocument(String path, {String? password}) async {
    final Uint8List bytes = await File(path).readAsBytes();
    return PdfDocument(inputBytes: bytes, password: password);
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

  @override
  Future<List<Uint8List>> renderPageThumbnails(String path) async {
    final rx.PdfDocument doc = await rx.PdfDocument.openFile(path);
    final List<Uint8List> thumbnails = [];

    try {
      for (int i = 0; i < doc.pages.length; i++) {
        final rx.PdfPage page = doc.pages[i];
        // Preview-only scale (~0.5x, well below the 1.3x/2x used for
        // exported images/compression) — this is a small on-screen thumb,
        // never written to disk. fullWidth/fullHeight, not width/height —
        // see the render() doc comment on pdfToImages above.
        final int width = (page.width * 0.5).round();
        final int height = (page.height * 0.5).round();
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
        thumbnails.add(Uint8List.fromList(img.encodeJpg(image, quality: 70)));
      }
    } finally {
      await doc.dispose();
    }

    return thumbnails;
  }

  @override
  Future<String> editPdfPages(
    String inputPath,
    List<PdfPageEdit> edits,
  ) async {
    final PdfDocument source = await _loadDocument(inputPath);
    final int pageCount = source.pages.count;
    for (final edit in edits) {
      if (edit.originalIndex < 0 || edit.originalIndex >= pageCount) {
        source.dispose();
        throw ArgumentError(
          'Page index ${edit.originalIndex} out of range '
          '(0-${pageCount - 1}).',
        );
      }
    }

    final PdfDocument output = PdfDocument();
    output.pageSettings.margins.all = 0;
    for (final edit in edits) {
      _copyPage(
        source.pages[edit.originalIndex],
        output,
        rotationDegrees: edit.rotationDegrees,
      );
    }
    source.dispose();

    return _writeOutput(
      output,
      'purapdf_pages_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  @override
  Future<List<PdfTextLine>> extractTextLines(String path) async {
    final PdfDocument doc = await _loadDocument(path);
    try {
      final List<TextLine> lines = PdfTextExtractor(doc).extractTextLines();
      return [
        for (final line in lines)
          if (line.text.trim().isNotEmpty)
            PdfTextLine(
              pageIndex: line.pageIndex,
              text: line.text,
              left: line.bounds.left,
              top: line.bounds.top,
              width: line.bounds.width,
              height: line.bounds.height,
              fontName: line.fontName,
              fontSize: line.fontSize,
            ),
      ];
    } finally {
      doc.dispose();
    }
  }

  @override
  Future<List<PdfPageImage>> renderPageImages(String path) async {
    final rx.PdfDocument doc = await rx.PdfDocument.openFile(path);
    final List<PdfPageImage> images = [];

    try {
      for (int i = 0; i < doc.pages.length; i++) {
        final rx.PdfPage page = doc.pages[i];
        // 1.5x scale — legible enough to tap/read individual lines without
        // the memory cost of rendering every page at full export quality.
        final int width = (page.width * 1.5).round();
        final int height = (page.height * 1.5).round();
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
        images.add(
          PdfPageImage(
            bytes: Uint8List.fromList(img.encodeJpg(image, quality: 85)),
            pointsWidth: page.width,
            pointsHeight: page.height,
          ),
        );
      }
    } finally {
      await doc.dispose();
    }

    return images;
  }

  @override
  Future<String> editPdfContent(
    String inputPath,
    List<PdfContentEdit> edits,
  ) async {
    final PdfDocument doc = await _loadDocument(inputPath);
    final int pageCount = doc.pages.count;
    for (final edit in edits) {
      if (edit.pageIndex < 0 || edit.pageIndex >= pageCount) {
        doc.dispose();
        throw ArgumentError(
          'Page index ${edit.pageIndex} out of range (0-${pageCount - 1}).',
        );
      }
    }

    for (final edit in edits) {
      final PdfPage page = doc.pages[edit.pageIndex];
      switch (edit) {
        case PdfTextReplace e:
          final Rect redactBounds = Rect.fromLTWH(
            e.left,
            e.top,
            e.width,
            e.height,
          );
          // Redact: an opaque box over the original line's exact bounds,
          // then (unless this is a pure delete) the replacement drawn on
          // top. The original glyphs remain in the content stream beneath
          // the box — see PdfContentEdit's doc comment — this is a visual
          // edit only.
          page.graphics.drawRectangle(
            brush: PdfSolidBrush(PdfColor(255, 255, 255)),
            bounds: redactBounds,
          );
          if (e.newText.trim().isNotEmpty) {
            // drawString silently draws nothing if `bounds` is exactly the
            // extracted line's tight glyph-height box (confirmed: font
            // size == box height reliably produces empty output) — pad
            // generously rather than reusing the tight redact bounds.
            final double drawWidth = math.max(
              e.width,
              e.fontSize * 0.65 * e.newText.length,
            );
            final double drawHeight = math.max(e.height, e.fontSize * 1.5);
            page.graphics.drawString(
              e.newText,
              PdfStandardFont(_mapFontFamily(e.fontName), e.fontSize),
              bounds: Rect.fromLTWH(e.left, e.top, drawWidth, drawHeight),
            );
          }
        case PdfImageInsert e:
          final PdfBitmap bitmap = PdfBitmap(_normalizeImageBytes(e.imageBytes));
          page.graphics.drawImage(
            bitmap,
            Rect.fromLTWH(e.left, e.top, e.width, e.height),
          );
      }
    }

    return _writeOutput(
      doc,
      'purapdf_content_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  /// Re-encodes arbitrary image bytes as PNG via `package:image` (which
  /// recognizes a much wider format range — WebP, GIF, BMP, TIFF, odd PNG
  /// variants, ... — than Syncfusion's own sniffing) before handing them to
  /// [PdfBitmap]. Without this, [PdfBitmap] throws `UnsupportedError:
  /// Invalid/Unsupported image stream` on anything its narrower decoder
  /// doesn't recognize — hit in practice with an image picked from Photos.
  Uint8List _normalizeImageBytes(Uint8List bytes) {
    final img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw ArgumentError(
        'This image format isn\'t supported. Try a JPEG or PNG instead.',
      );
    }
    return Uint8List.fromList(img.encodePng(decoded));
  }

  @override
  Future<String> encryptPdf(String inputPath, String password) async {
    final PdfDocument doc = await _loadDocument(inputPath);
    doc.security.userPassword = password;
    doc.security.ownerPassword = password;
    return _writeOutput(
      doc,
      'purapdf_locked_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  @override
  Future<String> decryptPdf(String inputPath, String password) async {
    final PdfDocument doc;
    try {
      doc = await _loadDocument(inputPath, password: password);
    } catch (_) {
      throw ArgumentError(
        'Wrong password, or this PDF isn\'t password-protected.',
      );
    }
    // Empty passwords are how Syncfusion drops encryption on save — see
    // pdf_repository_impl's test coverage: re-saving a loaded encrypted
    // document without touching security at all preserves the original
    // encryption (it round-trips), so this is the one that actually works.
    doc.security.userPassword = '';
    doc.security.ownerPassword = '';
    return _writeOutput(
      doc,
      'purapdf_unlocked_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  @override
  Future<String> watermarkPdf(
    String inputPath,
    WatermarkOptions options,
  ) async {
    final PdfDocument doc = await _loadDocument(inputPath);

    // Opacity is NOT the 4th (alpha) arg of PdfColor — that has no effect
    // on a fill/stroke brush, only graphics.setTransparency() actually
    // wires up the PDF ExtGState that makes drawing translucent.
    final PdfColor color = PdfColor(
      options.colorR,
      options.colorG,
      options.colorB,
    );
    final PdfFont font = PdfStandardFont(
      PdfFontFamily.helvetica,
      options.fontSize,
      style: PdfFontStyle.bold,
    );
    final PdfBrush brush = PdfSolidBrush(color);
    final PdfStringFormat format = PdfStringFormat(
      alignment: PdfTextAlignment.center,
      lineAlignment: PdfVerticalAlignment.middle,
    );
    final double alpha = options.opacity.clamp(0, 1).toDouble();

    for (int i = 0; i < doc.pages.count; i++) {
      final PdfPage page = doc.pages[i];
      final Size size = page.size;
      final PdfGraphics g = page.graphics;
      g.save();
      g.setTransparency(alpha);
      // Rotate around the page's center and draw the text in a wide box
      // straddling that center — a diagonal stamp, same convention as
      // "CONFIDENTIAL"/"DRAFT" watermarks (bottom-left to top-right).
      g.translateTransform(size.width / 2, size.height / 2);
      g.rotateTransform(-45);
      g.drawString(
        options.text,
        font,
        brush: brush,
        bounds: Rect.fromLTWH(
          -size.width,
          -options.fontSize,
          size.width * 2,
          options.fontSize * 2,
        ),
        format: format,
      );
      g.restore();
    }

    return _writeOutput(
      doc,
      'purapdf_watermark_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  @override
  Future<String> signPdf(String inputPath, PdfImageInsert signature) async {
    final PdfDocument doc = await _loadDocument(inputPath);
    final int pageCount = doc.pages.count;
    if (signature.pageIndex < 0 || signature.pageIndex >= pageCount) {
      doc.dispose();
      throw ArgumentError(
        'Page index ${signature.pageIndex} out of range (0-${pageCount - 1}).',
      );
    }

    final PdfPage page = doc.pages[signature.pageIndex];
    final PdfBitmap bitmap = PdfBitmap(
      _normalizeImageBytes(signature.imageBytes),
    );
    page.graphics.drawImage(
      bitmap,
      Rect.fromLTWH(
        signature.left,
        signature.top,
        signature.width,
        signature.height,
      ),
    );

    return _writeOutput(
      doc,
      'purapdf_signed_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  /// Best-effort match from an extracted font name to one of the PDF
  /// standard fonts — Syncfusion's [PdfStandardFont] can't reproduce an
  /// arbitrary embedded font, so replacement text won't pixel-match the
  /// original, only approximate its general style (serif/monospace/sans).
  PdfFontFamily _mapFontFamily(String fontName) {
    final String lower = fontName.toLowerCase();
    if (lower.contains('courier') || lower.contains('mono')) {
      return PdfFontFamily.courier;
    }
    if (lower.contains('times') ||
        lower.contains('serif') ||
        lower.contains('georgia') ||
        lower.contains('garamond')) {
      return PdfFontFamily.timesRoman;
    }
    return PdfFontFamily.helvetica;
  }
}
