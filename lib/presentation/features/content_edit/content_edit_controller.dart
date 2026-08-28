import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ads/ads_service.dart';
import '../../../core/providers.dart';
import '../../../domain/entities/pdf_content_edit.dart';
import '../../../domain/entities/pdf_file.dart';
import '../../../domain/entities/pdf_page_image.dart';
import '../../../domain/entities/pdf_text_line.dart';
import '../../../domain/usecases/edit_pdf_content_usecase.dart';

final editPdfContentUseCaseProvider = Provider(
  (ref) => EditPdfContentUseCase(ref.watch(pdfRepositoryProvider)),
);

/// An image the user has dropped onto a page but hasn't saved yet.
/// Position/size are fractions (0..1) of the page, not PDF points, so
/// dragging it around the on-screen canvas doesn't need to know the
/// render scale.
class PendingImage {
  final int pageIndex;
  final Uint8List bytes;
  final double leftFrac;
  final double topFrac;
  final double widthFrac;
  final double heightFrac;

  const PendingImage({
    required this.pageIndex,
    required this.bytes,
    required this.leftFrac,
    required this.topFrac,
    required this.widthFrac,
    required this.heightFrac,
  });

  PendingImage copyWith({double? leftFrac, double? topFrac}) => PendingImage(
    pageIndex: pageIndex,
    bytes: bytes,
    leftFrac: leftFrac ?? this.leftFrac,
    topFrac: topFrac ?? this.topFrac,
    widthFrac: widthFrac,
    heightFrac: heightFrac,
  );
}

class ContentEditState {
  final PdfFile? sourceFile;
  final bool isLoading;
  final bool isSaving;
  final List<PdfPageImage> pages;
  final List<PdfTextLine> textLines;
  final int currentPageIndex;
  final Map<int, String> textEdits;
  final List<PendingImage> pendingImages;
  final String? resultPath;
  final String? error;

  const ContentEditState({
    this.sourceFile,
    this.isLoading = false,
    this.isSaving = false,
    this.pages = const [],
    this.textLines = const [],
    this.currentPageIndex = 0,
    this.textEdits = const {},
    this.pendingImages = const [],
    this.resultPath,
    this.error,
  });

  bool get hasEdits => textEdits.isNotEmpty || pendingImages.isNotEmpty;

  ContentEditState copyWith({
    PdfFile? sourceFile,
    bool? isLoading,
    bool? isSaving,
    List<PdfPageImage>? pages,
    List<PdfTextLine>? textLines,
    int? currentPageIndex,
    Map<int, String>? textEdits,
    List<PendingImage>? pendingImages,
    String? resultPath,
    String? error,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return ContentEditState(
      sourceFile: sourceFile ?? this.sourceFile,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      pages: pages ?? this.pages,
      textLines: textLines ?? this.textLines,
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
      textEdits: textEdits ?? this.textEdits,
      pendingImages: pendingImages ?? this.pendingImages,
      resultPath: clearResult ? null : (resultPath ?? this.resultPath),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ContentEditController extends Notifier<ContentEditState> {
  @override
  ContentEditState build() => const ContentEditState();

  Future<void> setSourceFile(PdfFile file) async {
    state = ContentEditState(sourceFile: file, isLoading: true);
    try {
      final repo = ref.read(pdfRepositoryProvider);
      final results = await Future.wait([
        repo.renderPageImages(file.path),
        repo.extractTextLines(file.path),
      ]);
      state = state.copyWith(
        isLoading: false,
        pages: results[0] as List<PdfPageImage>,
        textLines: results[1] as List<PdfTextLine>,
        currentPageIndex: 0,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setPage(int index) {
    final int clamped = index.clamp(0, max(0, state.pages.length - 1));
    state = state.copyWith(currentPageIndex: clamped);
  }

  /// [newText] empty means "delete this line".
  void editLine(int lineIndex, String newText) {
    state = state.copyWith(
      textEdits: {...state.textEdits, lineIndex: newText},
      clearResult: true,
    );
  }

  void revertLine(int lineIndex) {
    final updated = {...state.textEdits}..remove(lineIndex);
    state = state.copyWith(textEdits: updated);
  }

  void addImage(Uint8List bytes) {
    state = state.copyWith(
      pendingImages: [
        ...state.pendingImages,
        PendingImage(
          pageIndex: state.currentPageIndex,
          bytes: bytes,
          leftFrac: 0.25,
          topFrac: 0.35,
          widthFrac: 0.5,
          heightFrac: 0.25,
        ),
      ],
      clearResult: true,
    );
  }

  void moveImage(int pendingIndex, double leftFrac, double topFrac) {
    final updated = [...state.pendingImages];
    final img = updated[pendingIndex];
    final double maxLeft = 1 - img.widthFrac;
    final double maxTop = 1 - img.heightFrac;
    updated[pendingIndex] = img.copyWith(
      leftFrac: leftFrac.clamp(0, maxLeft < 0 ? 0 : maxLeft),
      topFrac: topFrac.clamp(0, maxTop < 0 ? 0 : maxTop),
    );
    state = state.copyWith(pendingImages: updated);
  }

  void removeImage(int pendingIndex) {
    final updated = [...state.pendingImages]..removeAt(pendingIndex);
    state = state.copyWith(pendingImages: updated);
  }

  Future<void> save() async {
    final file = state.sourceFile;
    if (file == null) return;
    if (!state.hasEdits) {
      state = state.copyWith(error: 'Make at least one change before saving.');
      return;
    }

    await AdsService.instance.interstitial.showBeforeOperation();
    state = state.copyWith(
      isSaving: true,
      clearError: true,
      clearResult: true,
    );
    try {
      final List<PdfContentEdit> edits = [
        for (final entry in state.textEdits.entries)
          () {
            final line = state.textLines[entry.key];
            return PdfTextReplace(
              pageIndex: line.pageIndex,
              left: line.left,
              top: line.top,
              width: line.width,
              height: line.height,
              fontName: line.fontName,
              fontSize: line.fontSize,
              newText: entry.value,
            );
          }(),
        for (final img in state.pendingImages)
          () {
            final page = state.pages[img.pageIndex];
            return PdfImageInsert(
              pageIndex: img.pageIndex,
              imageBytes: img.bytes,
              left: img.leftFrac * page.pointsWidth,
              top: img.topFrac * page.pointsHeight,
              width: img.widthFrac * page.pointsWidth,
              height: img.heightFrac * page.pointsHeight,
            );
          }(),
      ];

      final useCase = ref.read(editPdfContentUseCaseProvider);
      final path = await useCase(file.path, edits);
      state = state.copyWith(isSaving: false, resultPath: path);
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
    }
  }

  void reset() {
    state = const ContentEditState();
  }
}

// autoDispose: state resets when the screen is popped, so returning to
// Edit PDF later starts fresh instead of showing the previous result.
final contentEditControllerProvider =
    NotifierProvider.autoDispose<ContentEditController, ContentEditState>(
      ContentEditController.new,
    );
