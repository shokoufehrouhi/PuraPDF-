/// One user-entered value for a single AcroForm field, keyed by
/// [PdfFormField.fieldIndex] - passed to `PdfRepository.fillAndSignPdf`.
/// Exactly one of [text]/[checked] is meaningful, matching whichever kind
/// the target field actually is; the other is left null.
class PdfFormFill {
  final int fieldIndex;
  final String? text;
  final bool? checked;

  const PdfFormFill({required this.fieldIndex, this.text, this.checked});
}
