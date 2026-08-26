/// A 1-indexed, inclusive page range (e.g. pages 1 through 5).
class PageRange {
  final int start;
  final int end;

  const PageRange(this.start, this.end);

  bool get isValid => start >= 1 && end >= start;

  @override
  String toString() => start == end ? '$start' : '$start-$end';
}
