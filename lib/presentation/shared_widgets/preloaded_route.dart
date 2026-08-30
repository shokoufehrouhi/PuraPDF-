import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Wraps [child] (one of the existing feature screens, e.g. `const
/// ContentEditScreen()`) and runs [preload] once [child] has actually
/// mounted, instead of before pushing it.
///
/// Used by the share-extension hand-off (see
/// `core/share_intent/share_intent_router.dart`) to open a screen already
/// loaded with the shared file, skipping the normal "select a PDF" step -
/// without needing to touch any of those screens' widgets or add an
/// `initialFile` constructor param to each one.
///
/// Order matters here: most of these screens' controllers are
/// `NotifierProvider.autoDispose`, which tears down state once nothing is
/// watching it. Calling [preload] (a `ref.read(...).setSourceFile(...)`)
/// *before* [child] has ever built would set that state with zero active
/// listeners - fair game for immediate disposal. Waiting for the
/// post-frame callback guarantees [child]'s own `ref.watch` has already
/// run at least once by then, so the provider has a real subscriber
/// before [preload] touches it.
class PreloadedRoute extends ConsumerStatefulWidget {
  final Widget child;
  final FutureOr<void> Function(WidgetRef ref) preload;

  const PreloadedRoute({super.key, required this.child, required this.preload});

  @override
  ConsumerState<PreloadedRoute> createState() => _PreloadedRouteState();
}

class _PreloadedRouteState extends ConsumerState<PreloadedRoute> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        await widget.preload(ref);
      } catch (error, stackTrace) {
        // Every current router entry's controller already catches its own
        // I/O errors and surfaces them via its own `error` state field (see
        // e.g. ContentEditController.setSourceFile) - this only exists as a
        // backstop against a *future* entry that forgets to, so a bad share
        // hand-off fails loudly (in the log) instead of leaving the screen
        // silently stuck on its empty state with no explanation.
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'preloaded_route',
            context: ErrorDescription('while preloading a shared file'),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
