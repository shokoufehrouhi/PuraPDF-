/// Outcome of a compress operation — enough to show a before/after size UI.
class CompressResult {
  final String outputPath;
  final int originalSizeBytes;
  final int compressedSizeBytes;

  const CompressResult({
    required this.outputPath,
    required this.originalSizeBytes,
    required this.compressedSizeBytes,
  });

  /// Positive when the output is smaller; can be zero/negative for PDFs
  /// that were already tightly packed (e.g. image-heavy, already-compressed
  /// content — see [PdfRepositoryImpl.compressPdf] doc comment).
  double get reductionPercent => originalSizeBytes == 0
      ? 0
      : (1 - compressedSizeBytes / originalSizeBytes) * 100;
}
