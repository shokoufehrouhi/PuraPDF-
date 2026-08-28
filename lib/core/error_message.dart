/// Turns a caught error into text that's safe to put in front of a user.
///
/// Our own domain/usecase validation throws `ArgumentError` with an
/// already user-facing message (see `domain/usecases/*.dart` — things like
/// "Enter a password." or "Merge requires at least 2 PDF files.") — show
/// that message as-is. Left as `e.toString()` it would come out prefixed
/// with Dart's own "Invalid argument(s): ", which reads like an error we
/// forgot to handle rather than a validation message.
///
/// Anything else — a `FileSystemException`, a `PlatformException` from a
/// plugin, a Syncfusion parse failure on a malformed PDF, disk-full, and so
/// on — is not something a user should have to parse, so it falls back to
/// a plain, actionable message instead of raw exception text.
String friendlyErrorMessage(Object error) {
  if (error is ArgumentError && error.message is String) {
    return error.message as String;
  }
  return 'Something went wrong. Please try again.';
}
