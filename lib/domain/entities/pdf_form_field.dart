/// What kind of AcroForm field a [PdfFormField] represents - controls which
/// widget Fill & Sign draws over it and whether it's actually editable.
enum PdfFormFieldKind {
  text,
  checkbox,
  /// Anything else a real-world PDF form can contain (radio groups,
  /// combo/list boxes, signature fields, buttons) - detected so the screen
  /// can draw a plain "not editable yet" outline instead of silently doing
  /// nothing when tapped, but not fillable in this pass. Still gets baked
  /// into the flattened output at whatever value it loaded with.
  unsupported,
}

/// One AcroForm field found in a PDF, as read by
/// `PdfRepository.extractFormFields` - used by Fill & Sign to draw a
/// tappable/editable overlay in-place on the rendered page.
class PdfFormField {
  /// This field's position in `PdfForm.fields` - the join key
  /// `PdfRepository.fillAndSignPdf` uses to match a [PdfFormFill] back to
  /// the right field (see that method's doc comment for why index, not
  /// name).
  final int fieldIndex;
  final int pageIndex;
  final PdfFormFieldKind kind;

  /// Top-down PDF points, already normalized the same way
  /// `PdfPageImage`/`PdfTextWord` are - no coordinate flip needed to
  /// position this against a rendered page image.
  final double left;
  final double top;
  final double width;
  final double height;

  /// Text fields only - empty for every other kind.
  final String initialText;
  final bool multiline;
  final int maxLength; // 0 = unlimited

  /// Checkboxes only - false for every other kind.
  final bool initialChecked;

  const PdfFormField({
    required this.fieldIndex,
    required this.pageIndex,
    required this.kind,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    this.initialText = '',
    this.multiline = false,
    this.maxLength = 0,
    this.initialChecked = false,
  });
}
