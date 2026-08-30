import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:archive/archive_io.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart' as rx;
import 'package:syncfusion_flutter_pdf/pdf.dart';
// Not a public export - see _drawMixedScriptParagraph's doc comment for why
// this reaches into Syncfusion's src/ for its Arabic shaper and bidi
// reorderer anyway.
import 'package:syncfusion_flutter_pdf/src/pdf/implementation/graphics/fonts/rtl/arabic_shape_renderer.dart';
import 'package:syncfusion_flutter_pdf/src/pdf/implementation/graphics/fonts/rtl/bidi.dart';
// Same situation, for redactPdf: Syncfusion's own content-stream tokenizer
// (the one PdfTextExtractor uses internally) plus the low-level primitives
// needed to read/write a page's raw stream bytes - none of it public. Each
// `show`n to just the one symbol needed so these don't collide with each
// other or with the public exports above.
import 'package:syncfusion_flutter_pdf/src/pdf/implementation/exporting/pdf_text_extractor/parser/content_parser.dart'
    show ContentParser, PdfRecord, PdfRecordCollection;
import 'package:syncfusion_flutter_pdf/src/pdf/implementation/io/pdf_cross_table.dart'
    show PdfCrossTable;
import 'package:syncfusion_flutter_pdf/src/pdf/implementation/pages/pdf_page.dart'
    show PdfPageHelper;
import 'package:syncfusion_flutter_pdf/src/pdf/implementation/primitives/pdf_array.dart'
    show PdfArray;
import 'package:syncfusion_flutter_pdf/src/pdf/implementation/primitives/pdf_stream.dart'
    show PdfStream;

import '../../core/docx/docx_paragraph.dart';
import '../../core/docx/docx_reader.dart';
import '../../core/docx/docx_writer.dart';
import '../../core/ocr/ocr_service.dart';
import '../../domain/entities/compress_result.dart';
import '../../domain/entities/compression_level.dart';
import '../../domain/entities/history_file.dart';
import '../../domain/entities/image_output_format.dart';
import '../../domain/entities/page_range.dart';
import '../../domain/entities/pdf_content_edit.dart';
import '../../domain/entities/pdf_form_field.dart';
import '../../domain/entities/pdf_form_fill.dart';
import '../../domain/entities/pdf_page_edit.dart';
import '../../domain/entities/pdf_page_image.dart';
import '../../domain/entities/pdf_redact_area.dart';
import '../../domain/entities/pdf_text_line.dart';
import '../../domain/entities/pdf_text_word.dart';
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
  Future<String> scannedImagesToPdf(List<String> imagePaths, {bool ocr = false}) =>
      _imagesToPdf(imagePaths, 'purapdf_scan_', ocr: ocr);

  /// Shared by [imagesToPdf] and [scannedImagesToPdf] — same "one image per
  /// page" assembly either way, just written under a different filename
  /// prefix so Recents can tell "Image -> PDF" and "Scan" apart (see
  /// _operationFor in home_screen.dart).
  ///
  /// [ocr]: after drawing each page's image, run on-device text recognition
  /// on it and draw every recognized line again on top, fully transparent
  /// (same setTransparency trick as the watermark stamp below) — invisible
  /// to the eye, but a real text run in the content stream, so the page
  /// becomes searchable/selectable without changing how it looks. Only used
  /// by [scannedImagesToPdf] — [imagesToPdf]'s general-purpose converter
  /// leaves images as plain images.
  Future<String> _imagesToPdf(
    List<String> imagePaths,
    String prefix, {
    bool ocr = false,
  }) async {
    const double maxDimension = 842; // cap so huge camera photos stay sane
    final PdfDocument output = PdfDocument();
    output.pageSettings.margins.all = 0;

    for (final imagePath in imagePaths) {
      final Uint8List bytes = await File(imagePath).readAsBytes();
      final PdfBitmap bitmap = PdfBitmap(_normalizeImageBytes(bytes));

      final double originalWidth = bitmap.width.toDouble();
      final double originalHeight = bitmap.height.toDouble();
      double w = originalWidth;
      double h = originalHeight;
      if (w > maxDimension || h > maxDimension) {
        final double scale = maxDimension / (w > h ? w : h);
        w *= scale;
        h *= scale;
      }

      output.pageSettings.size = Size(w, h);
      final PdfPage page = output.pages.add();
      page.graphics.drawImage(bitmap, Rect.fromLTWH(0, 0, w, h));

      if (ocr) {
        await _stampInvisibleTextLayer(
          page,
          imagePath,
          scaleX: w / originalWidth,
          scaleY: h / originalHeight,
        );
      }
    }

    if (ocr) {
      await OcrService.instance.dispose();
    }

    return _writeOutput(
      output,
      '$prefix${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  /// Recognizes text in the image at [imagePath] and draws each line back
  /// onto [page], fully transparent, scaled from the source image's pixel
  /// space into the page's point space via [scaleX]/[scaleY]. A page ML Kit
  /// finds no text on (a blank page, a non-Latin-script scan, ...) is left
  /// untouched — not an error, just no text layer.
  Future<void> _stampInvisibleTextLayer(
    PdfPage page,
    String imagePath, {
    required double scaleX,
    required double scaleY,
  }) async {
    final List<OcrLine> lines = await OcrService.instance.recognizeLines(
      imagePath,
    );
    if (lines.isEmpty) return;

    final PdfGraphics g = page.graphics;
    final PdfBrush brush = PdfSolidBrush(PdfColor(0, 0, 0));
    g.save();
    g.setTransparency(0);
    for (final OcrLine line in lines) {
      final double lineHeight = line.height * scaleY;
      if (lineHeight < 1) continue;
      final PdfFont font = PdfStandardFont(
        PdfFontFamily.helvetica,
        // ML Kit's box is the full glyph height (ascender to descender);
        // a font's point size renders taller than its own cap-height, so
        // sizing straight off the box tends to overshoot - 0.85 keeps the
        // invisible run roughly matching the box without needing exact
        // font-metric fidelity (nobody sees this, they only search/select
        // it, so "roughly lines up" is the actual bar, not pixel-perfect).
        lineHeight * 0.85,
      );
      g.drawString(
        line.text,
        font,
        brush: brush,
        bounds: Rect.fromLTWH(
          line.left * scaleX,
          line.top * scaleY,
          line.width * scaleX,
          lineHeight,
        ),
      );
    }
    g.restore();
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
  Future<List<PdfTextWord>> extractTextWords(String path) async {
    final PdfDocument doc = await _loadDocument(path);
    try {
      final List<TextLine> lines = PdfTextExtractor(doc).extractTextLines();
      final List<PdfTextWord> words = [];
      int lineIndex = 0;
      for (final TextLine line in lines) {
        if (line.text.trim().isEmpty) continue;
        for (final TextWord word in line.wordCollection) {
          if (word.text.trim().isEmpty) continue;
          words.add(
            PdfTextWord(
              pageIndex: line.pageIndex,
              lineIndex: lineIndex,
              text: word.text,
              left: word.bounds.left,
              top: word.bounds.top,
              width: word.bounds.width,
              height: word.bounds.height,
            ),
          );
        }
        lineIndex++;
      }
      return words;
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
        case PdfCheckmarkStamp e:
          _drawCheckmark(
            page,
            Rect.fromLTWH(e.left, e.top, e.width, e.height),
            color: PdfColor(e.colorRed, e.colorGreen, e.colorBlue),
          );
      }
    }

    return _writeOutput(
      doc,
      'purapdf_content_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  @override
  Future<String> redactPdf(String inputPath, List<PdfRedactArea> areas) async {
    final PdfDocument doc = await _loadDocument(inputPath);
    final int pageCount = doc.pages.count;
    for (final area in areas) {
      if (area.pageIndex < 0 || area.pageIndex >= pageCount) {
        doc.dispose();
        throw ArgumentError(
          'Page index ${area.pageIndex} out of range (0-${pageCount - 1}).',
        );
      }
    }

    final Map<int, List<PdfRedactArea>> byPage = {};
    for (final area in areas) {
      byPage.putIfAbsent(area.pageIndex, () => []).add(area);
    }

    for (final MapEntry<int, List<PdfRedactArea>> entry in byPage.entries) {
      final PdfPage page = doc.pages[entry.key];
      _removeContentInAreas(doc, entry.key, page, entry.value);
      // Visual cover on top of the now-actually-empty area - handles any
      // background graphic/image still there (see the method doc comment
      // on why images aren't content-stream-redacted) and gives the
      // expected bar look. Defaults to black (not Edit PDF's white erase
      // box), but color/opacity are per-area - opacity is NOT PdfColor's
      // 4th arg (that has no effect on a fill brush), it's
      // graphics.setTransparency() between save()/restore() (same trick
      // as the watermark stamp) - see PdfRedactArea's doc comment for why
      // a non-1.0 opacity here is a look choice, not a privacy one.
      final PdfGraphics g = page.graphics;
      for (final PdfRedactArea area in entry.value) {
        g.save();
        g.setTransparency(area.opacity.clamp(0, 1).toDouble());
        g.drawRectangle(
          brush: PdfSolidBrush(
            PdfColor(area.colorR, area.colorG, area.colorB),
          ),
          bounds: Rect.fromLTWH(area.left, area.top, area.width, area.height),
        );
        g.restore();
      }
    }

    return _writeOutput(
      doc,
      'purapdf_redacted_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  /// The actual removal half of redaction: permanently drops (or, since the
  /// word/range-selection round, partially trims) text-showing operators
  /// (`Tj`/`TJ`/`'`/`"`) from [page]'s raw content stream wherever they land
  /// inside [areas], so the text is gone from copy-paste/extraction - not
  /// just visually covered (contrast [editPdfContent], which only ever
  /// draws over existing content).
  ///
  /// Syncfusion has no public API for this - reaches into its
  /// unexported `src/` internals for the same content-stream tokenizer
  /// [PdfTextExtractor] itself uses (`ContentParser`/`PdfRecordCollection`/
  /// `PdfRecord`), plus the primitives needed to get a page's raw stream
  /// bytes and write new ones back (`PdfPageHelper`, `PdfCrossTable`,
  /// `PdfStream`, `PdfArray`) - not a supported import, a Syncfusion
  /// version bump could move or remove any of these.
  ///
  /// Word/range-precision mechanism: matching is still gated on each
  /// operator's *y* position first (`Tm`/`Td`/`TD`/`T*`/`TL`/translation-only
  /// `cm`/`q`/`Q`, exactly as before - see those tracking vars below and the
  /// CTM note that was already load-bearing for whole-line redaction). Once
  /// an operator's line is near an area, [_splitTextOperator] does the new
  /// part: it cross-references the operator's raw string byte-for-byte
  /// against [PdfTextExtractor]'s own already-correct per-glyph positions
  /// ([_flattenPageGlyphs]) to find exactly which glyphs fall inside an
  /// area, and rewrites the operator as a `TJ` array with the redacted
  /// run(s) replaced by a spacing number (so the surviving text doesn't
  /// visually shift to close the gap) instead of dropping the whole thing.
  ///
  /// This byte-for-byte cross-reference only works when the font's string
  /// encoding is simple single-byte (WinAnsi, every base-14 standard font)
  /// - confirmed empirically, not assumed. Anything that doesn't verify
  /// cleanly (a hex-string operand, a CID-keyed/multi-byte embedded font,
  /// ...) permanently drops this whole page back to the *original*
  /// whole-operator behavior for every operator from that point on, since
  /// a broken byte↔glyph correlation can't be trusted for any operator
  /// after it either - safe (never mis-splits mid-encoding-unit), just
  /// coarser than word-precision in that case.
  ///
  /// Everything else about scope is unchanged from the whole-line version:
  /// - **Images are never touched.** A `Do` operator is always kept as-is
  ///   regardless of whether it points at an image inside a redact area -
  ///   only the visual bar (drawn by the caller) covers it.
  /// - **Nested Form XObjects are not recursed into** - text living inside
  ///   a Form XObject's own content stream won't be found.
  void _removeContentInAreas(
    PdfDocument doc,
    int pageIndex,
    PdfPage page,
    List<PdfRedactArea> areas,
  ) {
    final PdfArray contentRefs = PdfPageHelper.getHelper(page).contents;
    if (contentRefs.count == 0) return;

    final List<PdfStream> streams = [];
    for (int i = 0; i < contentRefs.count; i++) {
      final dynamic dereferenced = PdfCrossTable.dereference(contentRefs[i]);
      if (dereferenced is PdfStream) {
        dereferenced.decompress();
        streams.add(dereferenced);
      }
    }
    if (streams.isEmpty) return;

    // TextLine/PdfRedactArea bounds are top-left-origin, full-page-relative
    // (the same space editPdfContent already draws into directly) - raw
    // Tm/Td content-stream y is bottom-left-origin, so flip via page
    // height for every comparison below.
    final double pageHeight = page.size.height;
    const double tolerance = 2.0; // baseline sits inside, not at, the box
    bool hitsAreaY(double topOriginY) => areas.any(
      (PdfRedactArea a) =>
          topOriginY >= a.top - tolerance &&
          topOriginY <= a.top + a.height + tolerance,
    );
    bool hitsAreaRect(Rect glyphBounds) => areas.any(
      (PdfRedactArea a) => glyphBounds.overlaps(
        Rect.fromLTWH(a.left, a.top, a.width, a.height),
      ),
    );

    final List<TextGlyph> pageGlyphs = _flattenPageGlyphs(doc, pageIndex);
    int glyphCursor = 0;
    bool preciseMode = true;

    double tlmY = 0; // text line matrix y, reset per BT, bottom-left origin
    double leading = 0; // TL, or the implicit one TD sets
    double fontSize = 0; // Tf's size operand - needed for gap-adjustment math
    // Translation-only CTM y - confirmed necessary by testing, not an
    // exotic case: Syncfusion's own PdfGraphics wraps *every* page's
    // drawing in `q ... cm 1 0 0 1 0 <pageHeight> ... cm 1 0 0 1 <x> <y>
    // ... BT ... ET ... Q` to implement its top-left-origin drawing
    // convenience over PDF's native bottom-left space - ignoring it (as
    // Syncfusion's own extractor does) put every line hundreds of points
    // off. Still deliberately translation-only (`a`/`b`/`c`/`d` ignored) -
    // fine for ordinary axis-aligned content, wrong for rotated/scaled
    // `cm`s.
    double ctmY = 0;
    final List<double> ctmStack = [];
    final List<PdfRecord> kept = [];
    for (final PdfStream stream in streams) {
      final List<int>? bytes = stream.data;
      if (bytes == null || bytes.isEmpty) continue;
      final PdfRecordCollection? records = ContentParser(bytes).readContent();
      if (records == null) continue;

      for (final PdfRecord record in records.recordCollection) {
        final String? op = record.operatorName;
        final List<String> operands = record.operands ?? const <String>[];
        if (op == 'q') {
          ctmStack.add(ctmY);
          kept.add(record);
        } else if (op == 'Q') {
          if (ctmStack.isNotEmpty) ctmY = ctmStack.removeLast();
          kept.add(record);
        } else if (op == 'cm' && operands.length == 6) {
          ctmY += double.tryParse(operands[5]) ?? 0;
          kept.add(record);
        } else if (op == 'BT') {
          tlmY = 0;
          kept.add(record);
        } else if (op == 'Tm' && operands.length == 6) {
          tlmY = double.tryParse(operands[5]) ?? tlmY;
          kept.add(record);
        } else if (op == 'Td' && operands.length == 2) {
          tlmY += double.tryParse(operands[1]) ?? 0;
          kept.add(record);
        } else if (op == 'TD' && operands.length == 2) {
          final double ty = double.tryParse(operands[1]) ?? 0;
          leading = -ty;
          tlmY += ty;
          kept.add(record);
        } else if (op == 'TL' && operands.length == 1) {
          leading = double.tryParse(operands[0]) ?? leading;
          kept.add(record);
        } else if (op == 'T*') {
          tlmY -= leading;
          kept.add(record);
        } else if (op == 'Tf' && operands.length == 2) {
          fontSize = double.tryParse(operands[1]) ?? fontSize;
          kept.add(record);
        } else if (op == "'" || op == '"' || op == 'Tj' || op == 'TJ') {
          // '/" move to the next line (T*'s equivalent) *and* show text -
          // the movement happens before the position check.
          if (op == "'" || op == '"') tlmY -= leading;
          final double topY = pageHeight - (ctmY + tlmY);
          final bool lineNear = hitsAreaY(topY);
          final _SplitOutcome outcome = _splitTextOperator(
            record: record,
            pageGlyphs: pageGlyphs,
            cursor: glyphCursor,
            lineNear: lineNear,
            preciseMode: preciseMode,
            fontSize: fontSize,
            hitsAreaRect: hitsAreaRect,
          );
          glyphCursor = outcome.newCursor;
          preciseMode = outcome.precisionHeld;
          kept.addAll(outcome.records);
        } else {
          kept.add(record);
        }
      }
    }

    // Re-serialize. The lexer strips a TJ array's brackets when tokenizing
    // (each string/number inside becomes its own operand), so TJ is the
    // one operator that needs them added back; every other operand string
    // already carries whatever delimiters it needs (Tj's `(...)`/`<...>`
    // literal already includes its own parens/angle-brackets verbatim,
    // escape sequences untouched - confirmed by reading the lexer).
    final StringBuffer out = StringBuffer();
    for (final PdfRecord r in kept) {
      final List<String>? operands = r.operands;
      if (operands != null && operands.isNotEmpty) {
        if (r.operatorName == 'TJ') {
          out
            ..write('[')
            ..write(operands.join(' '))
            ..write(']');
        } else {
          out.write(operands.join(' '));
        }
        out.write(' ');
      }
      out
        ..write(r.operatorName)
        ..write('\n');
    }

    streams.first.clearStream();
    final String rewritten = out.toString();
    // PdfStream.write throws on an empty string - a page redacted down to
    // nothing is already correctly empty after clearStream(), just don't
    // call write() on it.
    if (rewritten.isNotEmpty) {
      streams.first.write(rewritten);
    }
    for (int i = 1; i < streams.length; i++) {
      streams[i].clearStream();
    }
  }

  /// This page's glyphs, in extraction (= reading/content-stream) order,
  /// flattened from every line's already-public `wordCollection`/`glyphs`
  /// (Syncfusion computes real per-glyph bounds here - no font-metrics math
  /// to reimplement). Whitespace "words" are deliberately *not* filtered
  /// out here (unlike [extractTextWords], which is UI-facing) - a raw
  /// operator's string includes its spaces, so the byte↔glyph
  /// cross-reference in [_splitTextOperator] needs them too, or every
  /// count past the first space would be off by one.
  List<TextGlyph> _flattenPageGlyphs(PdfDocument doc, int pageIndex) {
    final List<TextLine> lines = PdfTextExtractor(
      doc,
    ).extractTextLines(startPageIndex: pageIndex, endPageIndex: pageIndex);
    final List<TextGlyph> glyphs = [];
    for (final TextLine line in lines) {
      for (final TextWord word in line.wordCollection) {
        glyphs.addAll(word.glyphs);
      }
    }
    return glyphs;
  }

  /// Decides what a single text-showing [record] becomes in the rewritten
  /// stream, and keeps [_removeContentInAreas]'s glyph cursor in sync so
  /// the next operator's cross-reference starts in the right place.
  ///
  /// - Not near any area (`!lineNear`): kept unchanged. Still has to work
  ///   out how many glyphs it consumed (via [_operatorGlyphCount]) purely
  ///   to keep the cursor synced for later operators.
  /// - Near an area but precision is already lost for this page
  ///   (`!preciseMode`): falls back to the whole-line behavior - drop the
  ///   entire record, since `lineNear` was already true.
  /// - Near an area, precision still held: attempts the byte↔glyph
  ///   cross-reference. A clean verification produces a precise split
  ///   (unchanged if nothing in it was actually redacted); a failed one
  ///   drops the whole record *and* permanently flips `precisionHeld` off
  ///   for the rest of the page (see the big doc comment above).
  _SplitOutcome _splitTextOperator({
    required PdfRecord record,
    required List<TextGlyph> pageGlyphs,
    required int cursor,
    required bool lineNear,
    required bool preciseMode,
    required double fontSize,
    required bool Function(Rect) hitsAreaRect,
  }) {
    final List<String> operands = record.operands ?? const <String>[];

    // Hex strings (`<...>`) aren't decoded here (see the class doc comment)
    // - if one shows up, this operator can't be verified either way.
    final bool hasHexOperand = operands.any((o) => o.startsWith('<'));

    if (!preciseMode || !lineNear || hasHexOperand) {
      final int n = hasHexOperand
          ? 0 // truly unknown - fine, precision is off from here anyway
          : _operatorGlyphCount(operands);
      final bool drop = lineNear; // whole-operator behavior, as before
      return _SplitOutcome(
        records: drop ? const <PdfRecord>[] : [record],
        newCursor: cursor + n,
        precisionHeld: preciseMode && !hasHexOperand,
      );
    }

    final int totalGlyphs = _operatorGlyphCount(operands);
    if (cursor + totalGlyphs > pageGlyphs.length) {
      // Ran out of glyphs to cross-reference against - can't trust this
      // or anything after it on this page.
      return _SplitOutcome(
        records: const <PdfRecord>[],
        newCursor: cursor + totalGlyphs,
        precisionHeld: false,
      );
    }

    // Verify every byte in every string operand matches the next glyph's
    // text, in order, before trusting a split.
    int probe = cursor;
    for (final String operand in operands) {
      if (!operand.startsWith('(')) continue; // number adjustment, skip
      for (final int byteVal in _decodePdfLiteralBytes(operand)) {
        final String glyphText = pageGlyphs[probe].text;
        if (glyphText.length != 1 || glyphText.codeUnitAt(0) != byteVal) {
          return _SplitOutcome(
            records: const <PdfRecord>[],
            newCursor: cursor + totalGlyphs,
            precisionHeld: false,
          );
        }
        probe++;
      }
    }

    // Verified - build the real kept/dropped runs using each glyph's own
    // bounds, chunk by chunk (a TJ's existing number adjustments pass
    // through untouched between chunks).
    final List<String> newOperands = [];
    int glyphIdx = cursor;
    bool anyDropped = false;
    for (final String operand in operands) {
      if (!operand.startsWith('(')) {
        newOperands.add(operand);
        continue;
      }
      final List<int> chunkBytes = _decodePdfLiteralBytes(operand);
      final List<_GlyphRun> runs = [];
      for (final int byteVal in chunkBytes) {
        final TextGlyph g = pageGlyphs[glyphIdx];
        final bool dropped = hitsAreaRect(g.bounds);
        if (dropped) anyDropped = true;
        if (runs.isNotEmpty && runs.last.dropped == dropped) {
          runs.last.bytes.add(byteVal);
          runs.last.width += g.bounds.width;
        } else {
          runs.add(_GlyphRun(dropped, [byteVal], g.bounds.width));
        }
        glyphIdx++;
      }
      for (final _GlyphRun run in runs) {
        if (run.dropped) {
          // Negative spacing adjustment (PDF's thousandths-of-em TJ unit)
          // sized to the dropped run's width, so surviving text on either
          // side keeps its original on-page position instead of the gap
          // visually collapsing.
          final double adjustment = fontSize > 0
              ? -(run.width / fontSize) * 1000
              : 0;
          newOperands.add(adjustment.toStringAsFixed(3));
        } else {
          newOperands.add(_encodePdfLiteral(run.bytes));
        }
      }
    }

    if (!anyDropped) {
      // Nothing in this operator was actually targeted - keep it verbatim
      // rather than gratuitously rewriting an untouched line as a TJ array.
      return _SplitOutcome(
        records: [record],
        newCursor: cursor + totalGlyphs,
        precisionHeld: true,
      );
    }
    if (newOperands.every((o) => !o.startsWith('('))) {
      // Every glyph in it was dropped - nothing left to show at all.
      return _SplitOutcome(
        records: const <PdfRecord>[],
        newCursor: cursor + totalGlyphs,
        precisionHeld: true,
      );
    }
    return _SplitOutcome(
      records: [PdfRecord('TJ', newOperands)],
      newCursor: cursor + totalGlyphs,
      precisionHeld: true,
    );
  }

  /// How many glyphs a text-showing operator's operands account for -
  /// the sum of each string operand's decoded byte length (hex operands
  /// contribute 0; callers already treat any hex operand's presence as
  /// "can't verify" and stop relying on the cursor regardless).
  int _operatorGlyphCount(List<String> operands) {
    int total = 0;
    for (final String operand in operands) {
      if (operand.startsWith('(')) {
        total += _decodePdfLiteralBytes(operand).length;
      }
    }
    return total;
  }

  /// Decodes a raw PDF literal-string operand (still including its outer
  /// parens, exactly as the lexer captured it) into the individual
  /// character byte-values it represents, resolving `\(`, `\)`, `\\`,
  /// `\n`/`\r`/`\t`/`\b`/`\f`, and up-to-3-digit octal (`\ddd`) escapes -
  /// needed because the raw *text* length of an escape sequence (2+
  /// characters) doesn't match the *one byte* it actually decodes to,
  /// which would otherwise throw off every glyph-count comparison past the
  /// first escape.
  List<int> _decodePdfLiteralBytes(String literal) {
    final String inner = literal.substring(1, literal.length - 1);
    final List<int> bytes = [];
    int i = 0;
    while (i < inner.length) {
      final int c = inner.codeUnitAt(i);
      if (c == 0x5C && i + 1 < inner.length) {
        final int next = inner.codeUnitAt(i + 1);
        switch (String.fromCharCode(next)) {
          case 'n':
            bytes.add(0x0A);
            i += 2;
          case 'r':
            bytes.add(0x0D);
            i += 2;
          case 't':
            bytes.add(0x09);
            i += 2;
          case 'b':
            bytes.add(0x08);
            i += 2;
          case 'f':
            bytes.add(0x0C);
            i += 2;
          case '(':
            bytes.add(0x28);
            i += 2;
          case ')':
            bytes.add(0x29);
            i += 2;
          case '\\':
            bytes.add(0x5C);
            i += 2;
          default:
            if (next >= 0x30 && next <= 0x37) {
              int j = i + 1;
              int value = 0;
              int digits = 0;
              while (j < inner.length &&
                  digits < 3 &&
                  inner.codeUnitAt(j) >= 0x30 &&
                  inner.codeUnitAt(j) <= 0x37) {
                value = value * 8 + (inner.codeUnitAt(j) - 0x30);
                j++;
                digits++;
              }
              bytes.add(value & 0xFF);
              i = j;
            } else {
              i += 2; // e.g. a backslash-newline line continuation
            }
        }
      } else {
        bytes.add(c & 0xFF);
        i++;
      }
    }
    return bytes;
  }

  /// The inverse of [_decodePdfLiteralBytes]: wraps raw character
  /// byte-values back into a valid `(...)` PDF literal, escaping `(`, `)`,
  /// and `\`.
  String _encodePdfLiteral(List<int> rawBytes) {
    final StringBuffer out = StringBuffer('(');
    for (final int b in rawBytes) {
      if (b == 0x28 || b == 0x29 || b == 0x5C) out.writeCharCode(0x5C);
      out.writeCharCode(b);
    }
    out.write(')');
    return out.toString();
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
      throw ArgumentError('errorUnsupportedImageFormat');
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
      throw ArgumentError('errorWrongPasswordOrNotProtected');
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

  @override
  Future<List<PdfFormField>> extractFormFields(String path) async {
    final PdfDocument doc = await _loadDocument(path);
    final List<PdfFormField> result = [];
    final PdfFormFieldCollection fields = doc.form.fields;
    for (int i = 0; i < fields.count; i++) {
      final PdfField f = fields[i];
      if (f.page == null) continue; // no widget on any page - nothing to draw
      final int pageIndex = doc.pages.indexOf(f.page!);
      final Rect bounds = f.bounds;
      if (f is PdfTextBoxField) {
        result.add(
          PdfFormField(
            fieldIndex: i,
            pageIndex: pageIndex,
            kind: PdfFormFieldKind.text,
            left: bounds.left,
            top: bounds.top,
            width: bounds.width,
            height: bounds.height,
            initialText: f.text,
            multiline: f.multiline,
            maxLength: f.maxLength,
          ),
        );
      } else if (f is PdfCheckBoxField) {
        result.add(
          PdfFormField(
            fieldIndex: i,
            pageIndex: pageIndex,
            kind: PdfFormFieldKind.checkbox,
            left: bounds.left,
            top: bounds.top,
            width: bounds.width,
            height: bounds.height,
            initialChecked: f.isChecked,
          ),
        );
      } else {
        // Radio groups, combo/list boxes, signature fields, buttons - not
        // fillable in this pass (see PdfFormFieldKind.unsupported's doc
        // comment). Still reported so the screen can draw a plain
        // non-interactive outline instead of leaving an unexplained dead
        // spot on the form.
        result.add(
          PdfFormField(
            fieldIndex: i,
            pageIndex: pageIndex,
            kind: PdfFormFieldKind.unsupported,
            left: bounds.left,
            top: bounds.top,
            width: bounds.width,
            height: bounds.height,
          ),
        );
      }
    }
    doc.dispose();
    return result;
  }

  @override
  Future<String> fillAndSignPdf(
    String inputPath,
    List<PdfFormFill> fills,
  ) async {
    final PdfDocument doc = await _loadDocument(inputPath);
    final Map<int, PdfFormFill> byIndex = {
      for (final PdfFormFill fill in fills) fill.fieldIndex: fill,
    };
    final PdfForm form = doc.form;
    // Checked boxes to re-stroke after flatten (see below) - bounds captured
    // now, before flattenAllFields() removes the AcroForm these came from.
    final List<({int pageIndex, Rect bounds})> checkedBoxes = [];
    for (int i = 0; i < form.fields.count; i++) {
      final PdfFormFill? fill = byIndex[i];
      if (fill == null) continue; // left at whatever value it loaded with
      final PdfField f = form.fields[i];
      if (f is PdfTextBoxField && fill.text != null) {
        f.text = fill.text!;
      } else if (f is PdfCheckBoxField && fill.checked != null) {
        f.isChecked = fill.checked!;
        if (fill.checked! && f.page != null) {
          // indexOf resolves by identity - falls back to skipping the
          // re-stroke (not crashing the whole save) on the off chance a
          // field's own `.page` getter ever resolves to an instance that
          // isn't `==` the one `doc.pages` hands back for that page.
          final int resolvedIndex = doc.pages.indexOf(f.page!);
          if (resolvedIndex >= 0) {
            checkedBoxes.add((pageIndex: resolvedIndex, bounds: f.bounds));
          }
        }
      }
    }
    // Bakes every field's current value (edited or not) into ordinary page
    // content and removes the AcroForm itself - the result is a plain PDF,
    // not a still-fillable one (per the user's explicit choice for this
    // feature).
    form.flattenAllFields();

    // Some PDFs (seen in the wild - forms exported by third-party/no-code
    // tools) ship a checkbox whose "on" appearance stream is byte-identical
    // to its "off" one - a defect in the source file, not in isChecked or
    // flattenAllFields: /V and /AS do get set to /Yes correctly, but that
    // state's own appearance simply has no visible check. flatten has
    // nothing better to draw in that case, so it's baked in "invisibly
    // checked". Stroking our own mark over every box we just checked (same
    // vector approach as Edit PDF's checkmark stamp - see
    // PdfCheckmarkStamp's doc comment) makes checking a box visible
    // regardless of whether the source file's own appearance is trustworthy.
    for (final box in checkedBoxes) {
      _drawCheckmark(doc.pages[box.pageIndex], box.bounds);
    }

    return _writeOutput(
      doc,
      'purapdf_filled_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  /// Strokes a checkmark (two line segments, not a filled glyph - reliable
  /// across viewers with no font dependency) inside [bounds] on [page].
  /// Shared by [fillAndSignPdf] (over a just-checked checkbox) and
  /// [editPdfContent]'s [PdfCheckmarkStamp] handler (a user-placed stamp).
  void _drawCheckmark(PdfPage page, Rect bounds, {PdfColor? color}) {
    final PdfPen pen = PdfPen(
      color ?? PdfColor(22, 163, 74),
      width: bounds.width * 0.14,
    )..lineCap = PdfLineCap.round;
    final Offset start = Offset(
      bounds.left + bounds.width * 0.16,
      bounds.top + bounds.height * 0.54,
    );
    final Offset mid = Offset(
      bounds.left + bounds.width * 0.42,
      bounds.top + bounds.height * 0.80,
    );
    final Offset end = Offset(
      bounds.left + bounds.width * 0.86,
      bounds.top + bounds.height * 0.22,
    );
    page.graphics.drawLine(pen, start, mid);
    page.graphics.drawLine(pen, mid, end);
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

  // --- PDF <-> Word (text-only) ---------------------------------------
  //
  // See core/docx/docx_paragraph.dart's doc comment for exactly what
  // fidelity this supports: paragraph-level text/bold/italic/heading only
  // - no images, tables, or per-word mixed formatting either direction.

  @override
  Future<String> pdfToWord(String inputPath) async {
    final PdfDocument doc = await _loadDocument(inputPath);
    final List<TextLine> lines;
    try {
      lines = PdfTextExtractor(doc).extractTextLines();
    } finally {
      doc.dispose();
    }

    final List<DocxParagraph> paragraphs = _groupLinesIntoParagraphs(lines);
    if (paragraphs.isEmpty) {
      throw ArgumentError('errorPdfHasNoExtractableText');
    }

    final Uint8List bytes = DocxWriter.write(paragraphs);
    return _writeBytesOutput(
      bytes,
      'purapdf_pdftoword_${DateTime.now().millisecondsSinceEpoch}.docx',
    );
  }

  /// Groups extracted [TextLine]s (Syncfusion hands back one per visual
  /// line, not per paragraph) into paragraphs: a big vertical gap relative
  /// to the previous line's own height, or a page boundary, starts a new
  /// paragraph; otherwise the line is a wrapped continuation of the current
  /// one. Bold/italic for the whole paragraph come from its first line's
  /// font name (e.g. "ABCDEF+Helvetica-Bold") - the same one-style-per-
  /// paragraph simplification as the Word->PDF direction.
  List<DocxParagraph> _groupLinesIntoParagraphs(List<TextLine> lines) {
    final List<DocxParagraph> paragraphs = [];
    final List<TextLine> group = [];
    int? currentPage;
    double? previousBottom;
    double? previousHeight;

    void flush() {
      if (group.isEmpty) return;
      final String text = group.map((l) => l.text).join(' ').trim();
      if (text.isNotEmpty) {
        final String fontName = group.first.fontName.toLowerCase();
        paragraphs.add(
          DocxParagraph(
            text: text,
            bold: fontName.contains('bold'),
            italic: fontName.contains('italic') || fontName.contains('oblique'),
          ),
        );
      }
      group.clear();
    }

    for (final TextLine line in lines) {
      if (line.text.trim().isEmpty) continue;
      final bool newPage = currentPage != null && currentPage != line.pageIndex;
      final double gap = previousBottom == null
          ? 0
          : line.bounds.top - previousBottom;
      final bool bigGap = previousHeight != null && gap > previousHeight * 0.6;
      if (newPage || bigGap) flush();

      group.add(line);
      currentPage = line.pageIndex;
      previousBottom = line.bounds.top + line.bounds.height;
      previousHeight = line.bounds.height;
    }
    flush();
    return paragraphs;
  }

  @override
  Future<String> wordToPdf(String inputPath) async {
    final Uint8List bytes = await File(inputPath).readAsBytes();
    final List<DocxParagraph> paragraphs = DocxReader.read(bytes);
    if (paragraphs.isEmpty) {
      throw ArgumentError('errorWordHasNoExtractableText');
    }

    final PdfDocument doc = PdfDocument();
    PdfPage page = doc.pages.add();
    Size clientSize = page.getClientSize();
    double y = 0;

    for (final DocxParagraph p in paragraphs) {
      // Bounds height would go negative past the page's bottom edge (the
      // element's own pagination only kicks in once it's actually asked to
      // lay out into insufficient bounds) - start the next page ourselves
      // first rather than hand it a degenerate Rect.
      if (y >= clientSize.height - 20) {
        page = doc.pages.add();
        clientSize = page.getClientSize();
        y = 0;
      }

      if (_containsArabicScript(p.text)) {
        // Farsi/Arabic paragraphs get their own manual layout below - see
        // _drawMixedScriptParagraph's doc comment for why PdfTextElement
        // alone can't do this.
        final (PdfPage newPage, Size newClientSize, double newY) =
            await _drawMixedScriptParagraph(doc, page, clientSize, y, p);
        page = newPage;
        clientSize = newClientSize;
        y = newY + (p.headingLevel > 0 ? 14 : 10);
        continue;
      }

      final List<PdfFontStyle> styles = [
        if (p.bold || p.headingLevel > 0) PdfFontStyle.bold,
        if (p.italic) PdfFontStyle.italic,
      ];
      final PdfFont font = PdfStandardFont(
        PdfFontFamily.helvetica,
        _wordToPdfFontSize(p.headingLevel),
        style: styles.isEmpty ? PdfFontStyle.regular : null,
        multiStyle: styles.isEmpty ? null : styles,
      );
      final PdfLayoutResult? result = PdfTextElement(
        text: p.text,
        font: font,
      ).draw(
        page: page,
        bounds: Rect.fromLTWH(0, y, clientSize.width, clientSize.height - y),
        format: PdfLayoutFormat(layoutType: PdfLayoutType.paginate),
      );
      if (result != null) {
        page = result.page;
        clientSize = page.getClientSize();
        y = result.bounds.bottom + (p.headingLevel > 0 ? 14 : 10);
      }
    }

    return _writeOutput(
      doc,
      'purapdf_wordtopdf_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  double _wordToPdfFontSize(int headingLevel) {
    switch (headingLevel) {
      case 1:
        return 20;
      case 2:
        return 16;
      case 3:
        return 14;
      default:
        return headingLevel > 3 ? 13 : 11;
    }
  }

  Future<String> _writeBytesOutput(Uint8List bytes, String fileName) async {
    final Directory dir = await getApplicationDocumentsDirectory();
    final String outPath = '${dir.path}/$fileName';
    await File(outPath).writeAsBytes(bytes, flush: true);
    await _recordGenerated(outPath);
    return outPath;
  }

  /// Arabic script (Arabic, Persian, Urdu, ...) — checked by numeric
  /// codepoint range rather than a regex of literal RTL characters, so this
  /// file stays bidi-neutral and the ranges stay checkable at a glance:
  /// Arabic (0600-06FF), Arabic Supplement (0750-077F), Arabic Extended-A
  /// (08A0-08FF), Arabic Presentation Forms A/B (FB50-FDFF, FE70-FEFF) - the
  /// latter block is what shaped Arabic letters land in (see
  /// _drawMixedScriptParagraph), so this doubles as the post-shaping check.
  bool _isArabicScriptRune(int c) =>
      (c >= 0x0600 && c <= 0x06FF) ||
      (c >= 0x0750 && c <= 0x077F) ||
      (c >= 0x08A0 && c <= 0x08FF) ||
      (c >= 0xFB50 && c <= 0xFDFF) ||
      (c >= 0xFE70 && c <= 0xFEFF);

  bool _containsArabicScript(String text) => text.runes.any(_isArabicScriptRune);

  Uint8List? _arabicFontBytes;

  /// Loads the bundled Unicode font once (bytes are cheap to reuse; a fresh
  /// [PdfTrueTypeFont] is still built per size since the size is baked into
  /// the font object itself).
  Future<PdfFont> _arabicFont(double size) async {
    final Uint8List bytes = _arabicFontBytes ??= (await rootBundle.load(
      'assets/fonts/NotoNaskhArabic-Regular.ttf',
    )).buffer.asUint8List();
    return PdfTrueTypeFont(bytes, size);
  }

  /// Draws a paragraph that mixes Arabic-script (RTL) and Latin/other (LTR)
  /// text - a plain [PdfTextElement] can't do this correctly:
  ///
  /// 1. The bundled Arabic font (assets/fonts/NotoNaskhArabic-Regular.ttf)
  ///    has *no* Latin glyphs at all (confirmed via font inspection - not
  ///    just unhinted, genuinely absent from its cmap). Syncfusion's own
  ///    TtfReader silently drops any character it can't find a glyph for,
  ///    so a single PdfTrueTypeFont call on "این یک PDF است." renders with
  ///    "PDF" missing entirely - no error, just gone. One font per script
  ///    is the norm for complex scripts (it's why Noto ships this way);
  ///    the fix is drawing each script run with its own font, not finding
  ///    a mythical font that covers both.
  /// 2. PdfStringFormat.textDirection does turn on Syncfusion's real
  ///    Arabic shaper + bidi reorderer (PdfGraphics._drawUnicodeLine), but
  ///    only for a single font/single line at a time - there's no public
  ///    API to hand it a line of mixed-font runs.
  ///
  /// So this reimplements just enough of that pipeline by hand:
  /// shape the whole paragraph once (shaping is per-character, order never
  /// matters for it), word-wrap in *logical* order (line-breaking is
  /// direction-agnostic - only the words placed within an already-decided
  /// line need reordering), then bidi-reorder each finished line
  /// independently and draw its script runs left to right at manually
  /// tracked x/y coordinates, right-aligned to read as RTL.
  ///
  /// Reuses Syncfusion's own shaper/bidi classes (ArabicShapeRenderer,
  /// Bidi) via their `src/` implementation path since there's no public
  /// export for them - not a supported import, so a Syncfusion upgrade
  /// could move or remove them; if this throws a "not found" import error
  /// after a version bump, that's why.
  Future<(PdfPage, Size, double)> _drawMixedScriptParagraph(
    PdfDocument doc,
    PdfPage page,
    Size clientSize,
    double y,
    DocxParagraph p,
  ) async {
    final double fontSize = _wordToPdfFontSize(p.headingLevel);
    final PdfFont arabicFont = await _arabicFont(fontSize);
    final List<PdfFontStyle> latinStyles = [
      if (p.bold || p.headingLevel > 0) PdfFontStyle.bold,
      if (p.italic) PdfFontStyle.italic,
    ];
    final PdfFont latinFont = PdfStandardFont(
      PdfFontFamily.helvetica,
      fontSize,
      style: latinStyles.isEmpty ? PdfFontStyle.regular : null,
      multiStyle: latinStyles.isEmpty ? null : latinStyles,
    );
    final double lineHeight = math.max(arabicFont.height, latinFont.height);
    PdfFont fontFor(bool arabic) => arabic ? arabicFont : latinFont;

    // Shape once up front - shape() maps each character to its contextual
    // glyph form independently of its neighbors' *order*, so re-slicing
    // this per line below doesn't need to re-shape.
    final String shaped = ArabicShapeRenderer().shape(p.text.split(''), 0);
    // measureString(' ') comes back 0 - a standalone whitespace-only
    // string measures as empty (confirmed by reproducing it: every run
    // boundary collapsed to zero gap, including plain Arabic-to-Arabic
    // ones, tracing back to this exact call) - so the space width is
    // Helvetica's own fixed AFM advance (278/1000 em, the same constant
    // for every base-14 standard font size) rather than measured.
    final double spaceWidth = fontSize * 0.278;

    double wordWidth(String word) => _splitScriptRuns(word).fold(
      0.0,
      (sum, r) => sum + (r.arabic == null
          ? spaceWidth
          : fontFor(r.arabic!).measureString(r.text).width),
    );

    // Greedy word-wrap in logical (unreordered) order - wrapping decisions
    // are direction-agnostic; only reorder *within* a line once its words
    // are fixed, or a long paragraph's later lines end up scrambled to the
    // top (reordering the whole paragraph as one unit first would reverse
    // line order too, not just word order within a line).
    final List<List<String>> lines = [];
    List<String> currentLine = [];
    double currentWidth = 0;
    for (final String word in shaped.split(' ')) {
      if (word.isEmpty) continue;
      final double w = wordWidth(word);
      final double candidate =
          currentWidth + (currentLine.isEmpty ? 0 : spaceWidth) + w;
      if (candidate > clientSize.width && currentLine.isNotEmpty) {
        lines.add(currentLine);
        currentLine = [word];
        currentWidth = w;
      } else {
        currentLine.add(word);
        currentWidth = candidate;
      }
    }
    if (currentLine.isNotEmpty) lines.add(currentLine);

    final Bidi bidi = Bidi()..isVisualOrder = false;
    for (final List<String> lineWords in lines) {
      if (y + lineHeight > clientSize.height) {
        page = doc.pages.add();
        clientSize = page.getClientSize();
        y = 0;
      }

      final String lineVisual =
          bidi.getLogicalToVisualString(lineWords.join(' '), true)['rtlText']
              as String;
      final List<_ScriptRun> runs = _splitScriptRuns(lineVisual);
      final double lineWidth = runs.fold(
        0.0,
        (sum, r) => sum + (r.arabic == null
            ? spaceWidth
            : fontFor(r.arabic!).measureString(r.text).width),
      );

      double x = (clientSize.width - lineWidth).clamp(0, clientSize.width);
      for (final _ScriptRun run in runs) {
        if (run.arabic == null) {
          // A space between runs is never drawn with either font - just
          // skip over spaceWidth by hand (see its own comment for why).
          x += spaceWidth;
          continue;
        }
        final PdfFont runFont = fontFor(run.arabic!);
        page.graphics.drawString(
          run.text,
          runFont,
          bounds: Rect.fromLTWH(x, y, clientSize.width - x, lineHeight),
        );
        x += runFont.measureString(run.text).width;
      }
      y += lineHeight;
    }

    return (page, clientSize, y);
  }

  /// Splits already-shaped text into runs of consecutive Arabic-script vs.
  /// Latin/other characters, in whatever order it's given (callers pass
  /// already visually-ordered text). Spaces are their own runs (arabic:
  /// null) rather than attached to either neighbor, so a run's text is
  /// never anything drawString has to render a space glyph within - see
  /// the space-handling comment where these runs get drawn.
  List<_ScriptRun> _splitScriptRuns(String text) {
    final List<_ScriptRun> runs = [];
    final StringBuffer buf = StringBuffer();
    bool? currentArabic;
    for (final int c in text.runes) {
      if (c == 0x20) {
        if (currentArabic != null) {
          runs.add(_ScriptRun(buf.toString(), currentArabic));
          buf.clear();
          currentArabic = null;
        }
        runs.add(const _ScriptRun(' ', null));
        continue;
      }
      final bool isArabic = _isArabicScriptRune(c);
      if (currentArabic != null && isArabic != currentArabic) {
        runs.add(_ScriptRun(buf.toString(), currentArabic));
        buf.clear();
      }
      currentArabic = isArabic;
      buf.writeCharCode(c);
    }
    if (buf.isNotEmpty) runs.add(_ScriptRun(buf.toString(), currentArabic));
    return runs;
  }
}

class _ScriptRun {
  final String text;
  /// null marks a space run (see _splitScriptRuns).
  final bool? arabic;
  const _ScriptRun(this.text, this.arabic);
}

/// Result of processing one text-showing operator in
/// [PdfRepositoryImpl._splitTextOperator] - see that method's doc comment.
class _SplitOutcome {
  final List<PdfRecord> records;
  final int newCursor;
  final bool precisionHeld;
  const _SplitOutcome({
    required this.records,
    required this.newCursor,
    required this.precisionHeld,
  });
}

/// One consecutive run of kept-or-dropped glyph bytes within a single
/// string operand, accumulated while walking its bytes in
/// [PdfRepositoryImpl._splitTextOperator].
class _GlyphRun {
  final bool dropped;
  final List<int> bytes;
  double width;
  _GlyphRun(this.dropped, this.bytes, this.width);
}
