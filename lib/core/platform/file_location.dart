import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Opens the system file manager at the folder of a file the user just
/// saved via the "Save As" picker. Only Android has a native handler (see
/// MainActivity.showInFolder) — the app is only published on Google Play.
class FileLocation {
  FileLocation._();

  static const MethodChannel _channel = MethodChannel('purapdf/file_location');

  static bool get supported => defaultTargetPlatform == TargetPlatform.android;

  /// [savedUri] is what `FilePicker.saveFile` returned. Returns false when
  /// the folder couldn't be opened (e.g. the file went to a cloud provider).
  static Future<bool> showInFolder(Uri savedUri) async {
    if (!supported) return false;
    String path = savedUri.path;
    try {
      path = Uri.decodeFull(path);
    } catch (_) {
      // Not valid percent-encoding — use the path as-is.
    }
    try {
      return await _channel.invokeMethod<bool>('showInFolder', {
            'path': path,
          }) ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
