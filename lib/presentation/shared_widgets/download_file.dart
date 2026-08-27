import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

/// Opens the native "Save As" dialog so the user can pick where to save the
/// file at [sourcePath] (Downloads, a specific folder, etc.), separate from
/// the OS share sheet. Shows a snackbar with the outcome.
Future<void> downloadFile(BuildContext context, String sourcePath) async {
  final Uint8List bytes = await File(sourcePath).readAsBytes();
  final String fileName = sourcePath.split('/').last;

  final Uri? savedUri = await FilePicker.saveFile(
    fileName: fileName,
    bytes: bytes,
    mimeType: _mimeTypeFor(fileName),
  );

  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(savedUri != null ? 'Saved: $fileName' : 'Cancelled'),
    ),
  );
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
