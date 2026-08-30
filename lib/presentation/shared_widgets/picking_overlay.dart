import 'dart:async';

import 'package:flutter/material.dart';

/// Shows a blocking, non-dismissible spinner for the duration of [action] -
/// meant to wrap a `FilePicker.pickFiles()`/`pickFiles(type: FileType.image)`
/// call specifically.
///
/// The native file/photo picker sheet can take a real, sometimes multi-second
/// while to actually return control to Flutter *after* the user taps a file
/// (an iCloud/Drive file still needing to download, for one) - with nothing
/// on Flutter's side changing during that gap, since every feature screen
/// here only flips its own `isLoading` state on once `pickFiles()` has
/// already returned. That reads as the app having silently frozen. This
/// overlay covers exactly that gap: it appears the instant the picker call
/// starts (briefly hidden behind the native sheet itself while that's up,
/// same as it would be for an instant pick) and disappears the moment
/// [action] resolves, whether that's a real pick or a cancel.
Future<T> withPickingOverlay<T>(
  BuildContext context,
  Future<T> Function() action,
) async {
  final NavigatorState navigator = Navigator.of(context, rootNavigator: true);
  bool dialogShowing = true;
  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _PickingOverlay(),
    ).whenComplete(() => dialogShowing = false),
  );
  try {
    return await action();
  } finally {
    if (dialogShowing) navigator.pop();
  }
}

class _PickingOverlay extends StatelessWidget {
  const _PickingOverlay();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 44,
        height: 44,
        child: CircularProgressIndicator(),
      ),
    );
  }
}
