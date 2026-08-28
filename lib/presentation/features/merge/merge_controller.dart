import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ads/ads_service.dart';
import '../../../core/providers.dart';
import '../../../domain/entities/pdf_file.dart';
import '../../../domain/usecases/merge_pdfs_usecase.dart';

final mergePdfsUseCaseProvider = Provider(
  (ref) => MergePdfsUseCase(ref.watch(pdfRepositoryProvider)),
);

class MergeState {
  final List<PdfFile> files;
  final bool isMerging;
  final String? resultPath;
  final String? error;

  const MergeState({
    this.files = const [],
    this.isMerging = false,
    this.resultPath,
    this.error,
  });

  MergeState copyWith({
    List<PdfFile>? files,
    bool? isMerging,
    String? resultPath,
    String? error,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return MergeState(
      files: files ?? this.files,
      isMerging: isMerging ?? this.isMerging,
      resultPath: clearResult ? null : (resultPath ?? this.resultPath),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class MergeController extends Notifier<MergeState> {
  @override
  MergeState build() => const MergeState();

  void addFiles(List<PdfFile> picked) {
    state = state.copyWith(
      files: [...state.files, ...picked],
      clearResult: true,
      clearError: true,
    );
  }

  void removeAt(int index) {
    final updated = [...state.files]..removeAt(index);
    state = state.copyWith(files: updated);
  }

  /// [newIndex] is expected pre-adjusted for the removed item, matching
  /// [ReorderableListView.onReorderItem]'s contract (unlike the legacy
  /// [ReorderableListView.onReorder]).
  void reorderItem(int oldIndex, int newIndex) {
    final updated = [...state.files];
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);
    state = state.copyWith(files: updated);
  }

  Future<void> merge() async {
    if (state.files.length < 2) {
      state = state.copyWith(error: 'Hadde aghal 2 file PDF entekhab kon.');
      return;
    }
    state = state.copyWith(
      isMerging: true,
      clearError: true,
      clearResult: true,
    );
    try {
      final useCase = ref.read(mergePdfsUseCaseProvider);
      final path = await useCase(state.files.map((f) => f.path).toList());
      state = state.copyWith(isMerging: false, resultPath: path);
      unawaited(AdsService.instance.interstitial.recordOperationAndMaybeShow());
    } catch (e) {
      state = state.copyWith(isMerging: false, error: e.toString());
    }
  }

  void reset() {
    state = const MergeState();
  }
}

// autoDispose: state resets when the screen is popped, so returning to
// Merge later starts fresh instead of showing the previous result.
final mergeControllerProvider =
    NotifierProvider.autoDispose<MergeController, MergeState>(
      MergeController.new,
    );
