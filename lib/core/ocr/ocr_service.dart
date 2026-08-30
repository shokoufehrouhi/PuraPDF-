import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// One recognized line of text from [OcrService.recognizeLines], with its
/// bounding box in the SOURCE IMAGE's pixel coordinates (top-left origin) —
/// callers scale this into whatever space they're drawing into (e.g. PDF
/// points) themselves.
class OcrLine {
  final String text;
  final double left;
  final double top;
  final double width;
  final double height;

  const OcrLine({
    required this.text,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });
}

/// Thin wrapper around ML Kit's on-device text recognizer, used to lay an
/// invisible, searchable/selectable text layer under each scanned page's
/// image (see [PdfRepositoryImpl._imagesToPdf]'s `ocr` flag).
///
/// Only the Latin-script model ships with this package on both platforms —
/// Arabic/Persian/CJK/Devanagari aren't supported by on-device ML Kit OCR at
/// all. Recognizing a non-Latin-script scan just yields no lines, which is a
/// harmless no-op for callers, not an error.
class OcrService {
  OcrService._();
  static final OcrService instance = OcrService._();

  TextRecognizer? _recognizer;

  Future<List<OcrLine>> recognizeLines(String imagePath) async {
    final TextRecognizer recognizer =
        _recognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
    final RecognizedText result = await recognizer.processImage(
      InputImage.fromFilePath(imagePath),
    );
    return [
      for (final TextBlock block in result.blocks)
        for (final TextLine line in block.lines)
          if (line.text.trim().isNotEmpty)
            OcrLine(
              text: line.text,
              left: line.boundingBox.left,
              top: line.boundingBox.top,
              width: line.boundingBox.width,
              height: line.boundingBox.height,
            ),
    ];
  }

  /// Releases the native recognizer. Not strictly required (the OS reclaims
  /// it), but avoids holding the model in memory between unrelated scans —
  /// call once after a batch of pages is done, not per-page.
  Future<void> dispose() async {
    await _recognizer?.close();
    _recognizer = null;
  }
}
