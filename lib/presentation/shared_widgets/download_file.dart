import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../l10n/app_localizations.dart';

/// Lets the user pick where to save the file at [sourcePath] — and under
/// what name — via the platform's native "Save As" dialog. The dialog's
/// initial folder is hinted to the device's Downloads directory (when the
/// platform exposes one — see [getDownloadsDirectory]) purely as a
/// starting point; the user is always free to rename the file or pick a
/// different destination before confirming.
Future<void> downloadFile(BuildContext context, String sourcePath) async {
  final Uint8List bytes = await File(sourcePath).readAsBytes();
  final String fileName = sourcePath.split('/').last;
  if (!context.mounted) return;
  final l10n = AppLocalizations.of(context);

  String? initialDirectory;
  try {
    final Directory? downloadsDir = await getDownloadsDirectory();
    if (downloadsDir != null) {
      if (!downloadsDir.existsSync()) {
        downloadsDir.createSync(recursive: true);
      }
      initialDirectory = downloadsDir.path;
    }
  } catch (_) {
    // No usable Downloads directory on this platform/situation — the
    // picker just opens at its own default location instead.
  }

  final Uri? savedUri = await FilePicker.saveFile(
    fileName: fileName,
    bytes: bytes,
    mimeType: _mimeTypeFor(fileName),
    initialDirectory: initialDirectory,
  );

  if (!context.mounted) return;
  final String message = savedUri != null
      ? l10n.downloadSaved(fileName)
      : l10n.downloadCancelled;
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
      tooltip: AppLocalizations.of(context).download,
      onPressed: () => downloadFile(context, path),
    );
  }
}
