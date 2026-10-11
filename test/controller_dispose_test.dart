// Regression test for the UnmountedRefException crashes reported in Sentry
// (PURAPDF-9/A/D): the user starts an operation, leaves the screen before
// it finishes, and the autoDispose controller then tried to write its
// result into an already-disposed provider. Controllers now check
// `ref.mounted` after every await, so finishing late must be a no-op.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purapdf/data/repositories/pdf_repository_impl.dart';
import 'package:purapdf/domain/entities/pdf_file.dart';
import 'package:purapdf/domain/usecases/merge_pdfs_usecase.dart';
import 'package:purapdf/presentation/features/merge/merge_controller.dart';

class _SlowMerge extends MergePdfsUseCase {
  _SlowMerge() : super(PdfRepositoryImpl());

  final Completer<String> result = Completer<String>();
  bool called = false;

  @override
  Future<String> call(List<String> inputPaths) {
    called = true;
    return result.future;
  }
}

void main() {
  // Off Android/iOS so the ad and review plugins (not registered in unit
  // tests) are skipped entirely - see adsSupported / reviewSupported.
  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.linux);
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  Future<void> runMergeThenLeave(void Function(_SlowMerge) finish) async {
    final slowMerge = _SlowMerge();
    final container = ProviderContainer(
      overrides: [mergePdfsUseCaseProvider.overrideWithValue(slowMerge)],
    );
    addTearDown(container.dispose);

    final sub = container.listen(mergeControllerProvider, (_, _) {});
    final controller = container.read(mergeControllerProvider.notifier);
    controller.addFiles(const [
      PdfFile(path: '/a.pdf', name: 'a.pdf'),
      PdfFile(path: '/b.pdf', name: 'b.pdf'),
    ]);

    final Future<void> merging = controller.merge();
    await pumpEventQueue();
    expect(slowMerge.called, isTrue);

    // The user leaves the Merge screen while the merge is still running.
    sub.close();
    await pumpEventQueue();

    finish(slowMerge);
    await merging;
  }

  test('a merge that succeeds after the screen closed does not throw', () {
    return runMergeThenLeave((m) => m.result.complete('/out.pdf'));
  });

  test('a merge that fails after the screen closed does not throw', () {
    return runMergeThenLeave((m) => m.result.completeError(Exception('x')));
  });
}
