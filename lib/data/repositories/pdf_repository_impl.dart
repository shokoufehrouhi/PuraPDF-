import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../domain/repositories/pdf_repository.dart';

/// Syncfusion-backed implementation of [PdfRepository].
///
/// Merge is done by rendering each source page onto a fresh page in the
/// output document (via [PdfPage.createTemplate]) rather than relying on a
/// single-call "merge" API, since that keeps output page sizes faithful to
/// each source page.
class PdfRepositoryImpl implements PdfRepository {
  @override
  Future<String> mergePdfs(List<String> inputPaths) async {
    final PdfDocument output = PdfDocument();
    output.pageSettings.margins.all = 0;

    for (final inputPath in inputPaths) {
      final Uint8List bytes = await File(inputPath).readAsBytes();
      final PdfDocument source = PdfDocument(inputBytes: bytes);

      for (int i = 0; i < source.pages.count; i++) {
        final PdfPage sourcePage = source.pages[i];
        final PdfTemplate template = sourcePage.createTemplate();
        // Switching pageSettings.size before each add() starts a fresh
        // section whenever the size changes, so mixed page sizes across
        // source documents are preserved (see PdfPageCollection.addPage,
        // which clones document.pageSettings into a new section on change).
        output.pageSettings.size = sourcePage.size;
        final PdfPage newPage = output.pages.add();
        newPage.graphics.drawPdfTemplate(template, Offset.zero);
      }
      source.dispose();
    }

    final List<int> bytes = await output.save();
    output.dispose();

    final Directory dir = await getApplicationDocumentsDirectory();
    final String outPath =
        '${dir.path}/purapdf_merged_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final File outFile = File(outPath);
    await outFile.writeAsBytes(bytes, flush: true);
    return outPath;
  }
}
