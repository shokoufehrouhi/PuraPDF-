/// One page to keep in an edited PDF: which page of the source document to
/// copy ([originalIndex], 0-based) and how far to rotate it clockwise
/// ([rotationDegrees], one of 0/90/180/270) before writing it out.
///
/// A full edit is a `List<PdfPageEdit>` in the desired output order — pages
/// dropped from the list are simply not copied, so reordering/deleting/
/// rotating are all expressed as one list.
class PdfPageEdit {
  final int originalIndex;
  final int rotationDegrees;

  const PdfPageEdit({required this.originalIndex, this.rotationDegrees = 0});
}
