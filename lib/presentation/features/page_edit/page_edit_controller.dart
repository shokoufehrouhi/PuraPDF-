import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ads/ads_service.dart';
import '../../../core/error_message.dart';
import '../../../core/providers.dart';
import '../../../domain/entities/pdf_file.dart';
import '../../../domain/entities/pdf_page_edit.dart';
import '../../../domain/usecases/edit_pdf_pages_usecase.dart';

final editPdfPagesUseCaseProvider = Provider(
  (ref) => EditPdfPagesUseCase(ref.watch(pdfRepositoryProvider)),
);

/// One page in the editor: which page of the source PDF it came from (its
/// original, 0-based index — fixed through reordering so the source page
/// stays addressable), its unrotated preview thumbnail, and how far it's
/// currently rotated clockwise (0/90/180/270).
class PageEditItem {
  final int originalIndex;
  final Uint8List thumbnail;
  final int rotation;

  const PageEditItem({
    required this.originalIndex,
    required this.thumbnail,
    this.rotation = 0,
  });

  PageEditItem copyWith({int? rotation}) => PageEditItem(
    originalIndex: originalIndex,
    thumbnail: thumbnail,
    rotation: rotation ?? this.rotation,
  );
}

class PageEditState {
  final PdfFile? sourceFile;
  final List<PageEditItem> pages;
  final bool isLoadingPages;
  final bool isSaving;
  final String? resultPath;
  final String? error;

  const PageEditState({
    this.sourceFile,
    this.pages = const [],
    this.isLoadingPages = false,
    this.isSaving = false,
    this.resultPath,
    this.error,
  });

  PageEditState copyWith({
    PdfFile? sourceFile,
    List<PageEditItem>? pages,
    bool? isLoadingPages,
    bool? isSaving,
    String? resultPath,
    String? error,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return PageEditState(
      sourceFile: sourceFile ?? this.sourceFile,
      pages: pages ?? this.pages,
      isLoadingPages: isLoadingPages ?? this.isLoadingPages,
      isSaving: isSaving ?? this.isSaving,
      resultPath: clearResult ? null : (resultPath ?? this.resultPath),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class PageEditController extends Notifier<PageEditState> {
  @override
  PageEditState build() => const PageEditState();

  Future<void> setSourceFile(PdfFile file) async {
    state = PageEditState(sourceFile: file, isLoadingPages: true);
    try {
      final repo = ref.read(pdfRepositoryProvider);
      final thumbnails = await repo.renderPageThumbnails(file.path);
      state = state.copyWith(
        isLoadingPages: false,
        pages: [
          for (int i = 0; i < thumbnails.length; i++)
            PageEditItem(originalIndex: i, thumbnail: thumbnails[i]),
        ],
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingPages: false,
        error: friendlyErrorMessage(e),
      );
    }
  }

  void rotateAt(int index) {
    final updated = [...state.pages];
    final item = updated[index];
    updated[index] = item.copyWith(rotation: (item.rotation + 90) % 360);
    state = state.copyWith(pages: updated);
  }

  void removeAt(int index) {
    final updated = [...state.pages]..removeAt(index);
    state = state.copyWith(pages: updated);
  }

  /// [newIndex] is expected pre-adjusted for the removed item, matching
  /// [ReorderableListView.onReorderItem]'s contract.
  void reorderItem(int oldIndex, int newIndex) {
    final updated = [...state.pages];
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);
    state = state.copyWith(pages: updated);
  }

  Future<void> save() async {
    final file = state.sourceFile;
    if (file == null) return;
    if (state.pages.isEmpty) {
      state = state.copyWith(error: 'At least one page must remain.');
      return;
    }

    await AdsService.instance.interstitial.showBeforeOperation();
    state = state.copyWith(
      isSaving: true,
      clearError: true,
      clearResult: true,
    );
    try {
      final useCase = ref.read(editPdfPagesUseCaseProvider);
      final path = await useCase(file.path, [
        for (final p in state.pages)
          PdfPageEdit(originalIndex: p.originalIndex, rotationDegrees: p.rotation),
      ]);
      state = state.copyWith(isSaving: false, resultPath: path);
    } catch (e) {
      state = state.copyWith(isSaving: false, error: friendlyErrorMessage(e));
    }
  }

  void reset() {
    state = const PageEditState();
  }
}

// autoDispose: state resets when the screen is popped, so returning to
// Edit Pages later starts fresh instead of showing the previous result.
final pageEditControllerProvider =
    NotifierProvider.autoDispose<PageEditController, PageEditState>(
      PageEditController.new,
    );
