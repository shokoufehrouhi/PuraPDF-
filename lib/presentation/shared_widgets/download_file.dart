import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Saves the file at [sourcePath] straight to the device's Downloads
/// folder when the platform exposes one directly (macOS, Android — see
/// [getDownloadsDirectory]) — no dialog, just a snackbar with the outcome.
/// Falls back to the native "Save As" picker on platforms/situations where
/// that isn't available (iOS has no shared Downloads folder apps can write
/// to directly; sandboxed macOS without the entitlement would also fail).
Future<void> downloadFile(BuildContext context, String sourcePath) async {
  final Uint8List bytes = await File(sourcePath).readAsBytes();
  final String fileName = sourcePath.split('/').last;

  String message;
  try {
    final Directory? downloadsDir = await getDownloadsDirectory();
    if (downloadsDir == null) {
      throw const FileSystemException('No Downloads directory available');
    }
    if (!downloadsDir.existsSync()) {
      downloadsDir.createSync(recursive: true);
    }
    await File(
      '${downloadsDir.path}/$fileName',
    ).writeAsBytes(bytes, flush: true);
    message = 'Saved to Downloads: $fileName';
  } catch (_) {
    final Uri? savedUri = await FilePicker.saveFile(
      fileName: fileName,
      bytes: bytes,
      mimeType: _mimeTypeFor(fileName),
    );
    message = savedUri != null ? 'Saved: $fileName' : 'Cancelled';
  }

  if (!context.mounted) return;
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}

String _mimeTypeFor(String fileName) {
  if (fileName.endsWith('.pdf')) return 'application/pdf';
  if (fileName.endsWith('.png')) return 'image/png';
  if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) {
    return 'image/jpeg';
  }
  if (fileName.endsWith('.zip')) return 'application/zip';
  return 'application/octet-stream';
}

/// Icon button wired to [downloadFile], for use as a `trailing` widget next
/// to a Share icon in result lists.
class DownloadIconButton extends StatelessWidget {
  final String path;

  const DownloadIconButton({super.key, required this.path});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.download_outlined),
      tooltip: 'Download',
      onPressed: () => downloadFile(context, path),
    );
  }
}
