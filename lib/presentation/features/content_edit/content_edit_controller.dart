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

/// A brand-new text box the user has dropped onto a page but hasn't saved
/// yet — for typing fresh content onto a page that has nothing there to
/// edit (an image-only/scanned page has no lines for [editLine] to target).
/// Position/size are fractions (0..1) of the page, same convention as
/// [PendingImage], for the same reason (dragging the on-screen canvas
/// shouldn't need to know the render scale).
class PendingText {
  final int pageIndex;
  final String text;
  final double leftFrac;
  final double topFrac;
  final double widthFrac;
  final double heightFrac;

  const PendingText({
    required this.pageIndex,
    required this.text,
    required this.leftFrac,
    required this.topFrac,
    required this.widthFrac,
    required this.heightFrac,
  });

  PendingText copyWith({
    double? leftFrac,
    double? topFrac,
    double? widthFrac,
    double? heightFrac,
  }) => PendingText(
    pageIndex: pageIndex,
    text: text,
    leftFrac: leftFrac ?? this.leftFrac,
    topFrac: topFrac ?? this.topFrac,
    widthFrac: widthFrac ?? this.widthFrac,
    heightFrac: heightFrac ?? this.heightFrac,
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
  final List<PendingText> pendingTexts;
  /// Text typed into the "Add text" dialog, awaiting a tap on the page to
  /// say where it goes - null when there's no placement in progress. Not
  /// counted in [hasEdits] since nothing has actually been added yet.
  final String? pendingTextEntry;
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
    this.pendingTexts = const [],
    this.pendingTextEntry,
    this.resultPath,
    this.error,
  });

  bool get hasEdits =>
      textEdits.isNotEmpty ||
      pendingImages.isNotEmpty ||
      pendingTexts.isNotEmpty;

  ContentEditState copyWith({
    PdfFile? sourceFile,
    bool? isLoading,
    bool? isSaving,
    List<PdfPageImage>? pages,
    List<PdfTextLine>? textLines,
    int? currentPageIndex,
    Map<int, String>? textEdits,
    List<PendingImage>? pendingImages,
    List<PendingText>? pendingTexts,
    String? pendingTextEntry,
    String? resultPath,
    String? error,
    bool clearResult = false,
    bool clearError = false,
    bool clearPendingTextEntry = false,
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
      pendingTexts: pendingTexts ?? this.pendingTexts,
      pendingTextEntry: clearPendingTextEntry
          ? null
          : (pendingTextEntry ?? this.pendingTextEntry),
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

  /// The font size (in PDF points) fresh text is drawn at when first
  /// placed - the user can then resize the box (see [resizeText]), which
  /// derives the actual saved font size from the box's current height (see
  /// [save]) rather than this fixed starting point.
  static const double _textFontSizePt = 16;

  /// [heightFrac] a [PendingText] box is initially given, as a multiple of
  /// its font size in points - kept as one constant so [placeText]'s initial
  /// sizing and [save]'s reverse (height -> font size) calc can't drift
  /// apart.
  static const double _textHeightToFontSizeRatio = 1.5;

  static const double _minTextWidthFrac = 0.03;
  static const double _minTextHeightFrac = 0.015;

  /// Stashes [text] as awaiting placement - the next tap on the page (see
  /// [placeText]) decides where it lands. Doesn't touch [pendingTexts]
  /// itself, so nothing is actually added (and [hasEdits] stays false) until
  /// the user picks a spot.
  void startAddText(String text) {
    state = state.copyWith(pendingTextEntry: text);
  }

  void cancelAddText() {
    state = state.copyWith(clearPendingTextEntry: true);
  }

  /// Drops [pendingTextEntry] onto the current page centered on the tapped
  /// point ([tapLeftFrac], [tapTopFrac] - fractions of the page, same as
  /// every other position here). The box is sized to fit the text itself at
  /// [_textFontSizePt] (width from [text]'s length, same estimate the
  /// repository's own safety padding uses) rather than a fixed band, so it
  /// starts close to its final size instead of needing a resize.
  void placeText(double tapLeftFrac, double tapTopFrac) {
    final String? text = state.pendingTextEntry;
    if (text == null || text.isEmpty) return;
    final page = state.pages[state.currentPageIndex];

    final double widthFrac = page.pointsWidth > 0
        ? (_textFontSizePt * 0.65 * text.length / page.pointsWidth).clamp(
            0.06,
            0.95,
          )
        : 0.3;
    final double heightFrac = page.pointsHeight > 0
        ? (_textFontSizePt * _textHeightToFontSizeRatio / page.pointsHeight)
              .clamp(0.02, 0.3)
        : 0.05;

    final double maxLeft = 1 - widthFrac;
    final double maxTop = 1 - heightFrac;
    final double leftFrac = (tapLeftFrac - widthFrac / 2).clamp(
      0,
      maxLeft < 0 ? 0 : maxLeft,
    );
    final double topFrac = (tapTopFrac - heightFrac / 2).clamp(
      0,
      maxTop < 0 ? 0 : maxTop,
    );

    state = state.copyWith(
      pendingTexts: [
        ...state.pendingTexts,
        PendingText(
          pageIndex: state.currentPageIndex,
          text: text,
          leftFrac: leftFrac,
          topFrac: topFrac,
          widthFrac: widthFrac,
          heightFrac: heightFrac,
        ),
      ],
      clearPendingTextEntry: true,
      clearResult: true,
    );
  }

  void moveText(int pendingIndex, double leftFrac, double topFrac) {
    final updated = [...state.pendingTexts];
    final txt = updated[pendingIndex];
    final double maxLeft = 1 - txt.widthFrac;
    final double maxTop = 1 - txt.heightFrac;
    updated[pendingIndex] = txt.copyWith(
      leftFrac: leftFrac.clamp(0, maxLeft < 0 ? 0 : maxLeft),
      topFrac: topFrac.clamp(0, maxTop < 0 ? 0 : maxTop),
    );
    state = state.copyWith(pendingTexts: updated);
  }

  void removeText(int pendingIndex) {
    final updated = [...state.pendingTexts]..removeAt(pendingIndex);
    state = state.copyWith(pendingTexts: updated);
  }

  /// Grows/shrinks a [PendingText] box by [scale] (e.g. `1.2` = 20% bigger)
  /// from releasing its resize handle - the screen already tracks the drag
  /// as a live local preview and reports the *total* multiplier once, on
  /// release (see [_PendingTextOverlay]'s doc comment for why: reporting
  /// every intermediate pixel here would push a new [ContentEditState]
  /// through Riverpod on every single frame of the drag, which rebuilds the
  /// entire screen and was the actual cause of a laggy-feeling drag, not a
  /// coordinate bug). [save] derives the actual saved font size from the
  /// resulting box height, so this is what makes "bigger box" actually mean
  /// "bigger text" in the output PDF, not just the on-screen preview.
  ///
  /// Width and height are scaled by the *same* factor rather than each
  /// getting its own independent adjustment - a single-line text box is
  /// almost always much wider than it is tall, so growing both dimensions
  /// by the same raw pixel amount grows the (small) height by a much bigger
  /// *percentage* than the (large) width. Since the on-screen preview draws
  /// the text with [BoxFit.contain] (see [_PendingTextOverlay]), which
  /// scales by the *smaller* of the two ratios, that mismatch left the box
  /// visibly stretching while the text inside barely grew - the box's
  /// aspect ratio drifting away from the text's own is exactly what caps
  /// the visible size. Scaling both dimensions by one shared factor keeps
  /// the box's aspect locked to wherever it started (matched to the text's
  /// natural shape by [placeText]), so growing it always grows the
  /// rendered text too.
  void resizeText(int pendingIndex, double scale) {
    final updated = [...state.pendingTexts];
    final txt = updated[pendingIndex];

    final double maxWidthFrac = 1 - txt.leftFrac;
    final double maxHeightFrac = 1 - txt.topFrac;
    final double newWidthFrac = (txt.widthFrac * scale).clamp(
      _minTextWidthFrac,
      maxWidthFrac < _minTextWidthFrac ? _minTextWidthFrac : maxWidthFrac,
    );
    final double newHeightFrac = (txt.heightFrac * scale).clamp(
      _minTextHeightFrac,
      maxHeightFrac < _minTextHeightFrac ? _minTextHeightFrac : maxHeightFrac,
    );
    updated[pendingIndex] = txt.copyWith(
      widthFrac: newWidthFrac,
      heightFrac: newHeightFrac,
    );
    state = state.copyWith(pendingTexts: updated);
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
        for (final txt in state.pendingTexts)
          () {
            final page = state.pages[txt.pageIndex];
            final double heightPt = txt.heightFrac * page.pointsHeight;
            // Reverse of placeText()'s initial heightFrac calc, so a box the
            // user resized via the drag handle actually saves at a matching
            // bigger/smaller font - not the fixed size it started at.
            // Clamped to stay sane at the box-size extremes resizeText()
            // still allows (e.g. dragged down to the minimum height).
            final double fontSize = (heightPt / _textHeightToFontSizeRatio)
                .clamp(4.0, 400.0);
            return PdfTextStamp(
              pageIndex: txt.pageIndex,
              left: txt.leftFrac * page.pointsWidth,
              top: txt.topFrac * page.pointsHeight,
              width: txt.widthFrac * page.pointsWidth,
              height: txt.heightFrac * page.pointsHeight,
              text: txt.text,
              fontSize: fontSize,
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
