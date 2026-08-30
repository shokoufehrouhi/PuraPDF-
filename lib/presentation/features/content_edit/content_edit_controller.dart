import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ads/ads_service.dart';
import '../../../core/error_message.dart';
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
///
/// [isCheckmark] marks the "Add checkmark" quick stamp specifically: [bytes]
/// still holds a rendered PNG for the on-screen drag handle, but on save
/// that bitmap is discarded in favor of drawing the mark as native vector
/// content (see [PdfCheckmarkStamp]'s doc comment for why a bitmap
/// round-trip isn't worth it for a two-stroke mark). [checkmarkColor*] carry
/// the same RGB the on-screen [bytes] preview was drawn with, so the saved
/// vector stroke matches it instead of falling back to
/// [PdfCheckmarkStamp]'s own default color - null for a non-checkmark image.
class PendingImage {
  final int pageIndex;
  final Uint8List bytes;
  final double leftFrac;
  final double topFrac;
  final double widthFrac;
  final double heightFrac;
  final bool isCheckmark;
  final int? checkmarkColorRed;
  final int? checkmarkColorGreen;
  final int? checkmarkColorBlue;

  const PendingImage({
    required this.pageIndex,
    required this.bytes,
    required this.leftFrac,
    required this.topFrac,
    required this.widthFrac,
    required this.heightFrac,
    this.isCheckmark = false,
    this.checkmarkColorRed,
    this.checkmarkColorGreen,
    this.checkmarkColorBlue,
  });

  PendingImage copyWith({double? leftFrac, double? topFrac}) => PendingImage(
    pageIndex: pageIndex,
    bytes: bytes,
    leftFrac: leftFrac ?? this.leftFrac,
    topFrac: topFrac ?? this.topFrac,
    widthFrac: widthFrac,
    heightFrac: heightFrac,
    isCheckmark: isCheckmark,
    checkmarkColorRed: checkmarkColorRed,
    checkmarkColorGreen: checkmarkColorGreen,
    checkmarkColorBlue: checkmarkColorBlue,
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
      state = state.copyWith(isLoading: false, error: friendlyErrorMessage(e));
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

  /// The default box (roughly centered, half the page wide) suits a photo
  /// dropped in from the gallery. A small fixed mark like a checkmark
  /// stamp wants a small square instead - callers pass their own fractions
  /// for that case rather than stretching the default box over it.
  void addImage(
    Uint8List bytes, {
    double leftFrac = 0.25,
    double topFrac = 0.35,
    double widthFrac = 0.5,
    double heightFrac = 0.25,
    bool isCheckmark = false,
    int? checkmarkColorRed,
    int? checkmarkColorGreen,
    int? checkmarkColorBlue,
  }) {
    state = state.copyWith(
      pendingImages: [
        ...state.pendingImages,
        PendingImage(
          pageIndex: state.currentPageIndex,
          bytes: bytes,
          leftFrac: leftFrac,
          topFrac: topFrac,
          widthFrac: widthFrac,
          heightFrac: heightFrac,
          isCheckmark: isCheckmark,
          checkmarkColorRed: checkmarkColorRed,
          checkmarkColorGreen: checkmarkColorGreen,
          checkmarkColorBlue: checkmarkColorBlue,
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
      state = state.copyWith(error: 'errorMakeAChangeBeforeSaving');
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
            final double left = img.leftFrac * page.pointsWidth;
            final double top = img.topFrac * page.pointsHeight;
            final double width = img.widthFrac * page.pointsWidth;
            final double height = img.heightFrac * page.pointsHeight;
            return img.isCheckmark
                ? PdfCheckmarkStamp(
                    pageIndex: img.pageIndex,
                    left: left,
                    top: top,
                    width: width,
                    height: height,
                    colorRed: img.checkmarkColorRed ?? 22,
                    colorGreen: img.checkmarkColorGreen ?? 163,
                    colorBlue: img.checkmarkColorBlue ?? 74,
                  )
                : PdfImageInsert(
                    pageIndex: img.pageIndex,
                    imageBytes: img.bytes,
                    left: left,
                    top: top,
                    width: width,
                    height: height,
                  );
          }(),
      ];

      final useCase = ref.read(editPdfContentUseCaseProvider);
      final path = await useCase(file.path, edits);
      state = state.copyWith(isSaving: false, resultPath: path);
    } catch (e) {
      state = state.copyWith(isSaving: false, error: friendlyErrorMessage(e));
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
