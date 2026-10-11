import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/platform/file_location.dart';
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
  if (savedUri == null) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.downloadCancelled)));
    return;
  }

  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  downloadSnackBarObserver._show(
    messenger,
    SnackBar(
      content: _SnackBarMarker(child: Text(l10n.downloadSaved(fileName))),
      duration: const Duration(seconds: 5),
      // A SnackBar with an action persists by default until dismissed —
      // let this one time out like any other message instead.
      persist: false,
      action: FileLocation.supported
          ? SnackBarAction(
              label: l10n.showInFolder,
              onPressed: () async {
                final bool opened = await FileLocation.showInFolder(savedUri);
                if (!opened) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(l10n.showInFolderFailed)),
                  );
                }
              },
            )
          : null,
    ),
  );
}

/// Closes the "Saved" snackbar as soon as the user navigates anywhere, or
/// touches anything outside the snackbar itself (another button, a scroll,
/// ...) — it only stays up while the user might still want "Show in
/// folder". The app has a single root [ScaffoldMessenger], so without this
/// the message would follow the user onto the next screen and cover its
/// bottom controls. Registered on MaterialApp.navigatorObservers.
final DownloadSnackBarObserver downloadSnackBarObserver =
    DownloadSnackBarObserver._();

class DownloadSnackBarObserver extends NavigatorObserver {
  DownloadSnackBarObserver._();

  // Contexts of the snackbar's content currently on screen - a set, not a
  // GlobalKey, since during a page transition both pages' Scaffolds build
  // the same snackbar at once.
  final Set<BuildContext> _snackBarContexts = {};
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _current;

  void _show(ScaffoldMessengerState messenger, SnackBar snackBar) {
    _dismiss();
    final controller = messenger.showSnackBar(snackBar);
    _current = controller;
    if (!_listening) {
      GestureBinding.instance.pointerRouter.addGlobalRoute(_onPointer);
      _listening = true;
    }
    controller.closed.whenComplete(() {
      // A newer snackbar may already have replaced this one - keep
      // listening for that one.
      if (identical(_current, controller)) _current = null;
      if (_current == null && _listening) {
        GestureBinding.instance.pointerRouter.removeGlobalRoute(_onPointer);
        _listening = false;
      }
    });
  }

  bool _listening = false;

  void _onPointer(PointerEvent event) {
    if (event is! PointerDownEvent) return;
    for (final BuildContext context in _snackBarContexts) {
      // The whole snackbar, not just its content, so a tap on the "Show in
      // folder" action doesn't count as touching something else.
      RenderObject? box;
      context.visitAncestorElements((element) {
        if (element.widget is! SnackBar) return true;
        box = element.renderObject;
        return false;
      });
      final RenderObject? found = box;
      if (found is RenderBox && found.attached) {
        final Rect bounds = found.localToGlobal(Offset.zero) & found.size;
        if (bounds.contains(event.position)) return;
      }
    }
    _dismiss();
  }

  void _dismiss() {
    final controller = _current;
    _current = null;
    controller?.close();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // Dialogs and popup menus are routes too, but they don't leave the
    // screen — only full page changes should drop the message.
    if (route is PageRoute) _dismiss();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) _dismiss();
  }
}

/// Registers the "Saved" snackbar's on-screen instances with
/// [downloadSnackBarObserver], so a tap inside the snackbar can be told
/// apart from a tap anywhere else.
class _SnackBarMarker extends StatefulWidget {
  final Widget child;

  const _SnackBarMarker({required this.child});

  @override
  State<_SnackBarMarker> createState() => _SnackBarMarkerState();
}

class _SnackBarMarkerState extends State<_SnackBarMarker> {
  @override
  void initState() {
    super.initState();
    downloadSnackBarObserver._snackBarContexts.add(context);
  }

  @override
  void dispose() {
    downloadSnackBarObserver._snackBarContexts.remove(context);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
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
