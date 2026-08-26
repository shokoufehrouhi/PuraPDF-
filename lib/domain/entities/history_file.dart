/// A file PuraPDF generated on-device (merge/split/compress/... output),
/// as tracked for the in-app History list.
class HistoryFile {
  final String path;
  final String name;
  final int sizeBytes;
  final DateTime createdAt;

  const HistoryFile({
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.createdAt,
  });
}
