import 'dart:math';

import 'package:flutter/painting.dart' show Color, HSVColor;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ads/ads_service.dart';
import '../../../core/error_message.dart';
import '../../../core/providers.dart';
import '../../../domain/entities/pdf_file.dart';
import '../../../domain/entities/pdf_page_image.dart';
import '../../../domain/entities/pdf_redact_area.dart';
import '../../../domain/entities/pdf_text_word.dart';
import '../../../domain/usecases/redact_pdf_usecase.dart';

final redactPdfUseCaseProvider = Provider(
  (ref) => RedactPdfUseCase(ref.watch(pdfRepositoryProvider)),
);

/// Where [RedactState.nextColor] starts, and the saturation/value every
/// hue picked off the spectrum bar keeps (only *hue* is user-adjustable -
/// see `_ColorSpectrumBar` in the screen) - a mid-bright, fully-saturated
/// blue.
const HSVColor _defaultHsv = HSVColor.fromAHSV(1, 210, 0.85, 0.85);

/// One tap (a single word) or one drag (a range of adjacent words) - each
/// gets its own color, either [RedactState.nextColor] as last left on the
/// spectrum bar or the next auto-advanced default. [wordIndices] are
/// indices into [RedactState.words].
class RedactSelection {
  final Color color;
  final Set<int> wordIndices;
  const RedactSelection({required this.color, required this.wordIndices});
}

class RedactState {
  final PdfFile? sourceFile;
  final bool isLoading;
  final bool isSaving;
  final List<PdfPageImage> pages;
  final List<PdfTextWord> words;
  final int currentPageIndex;
  final List<RedactSelection> selections;
  // What the *next* selection becomes - either wherever the user last left
  // the spectrum bar, or the last auto-advanced default (see
  // RedactController.commitSelection).
  final Color nextColor;
  final double barOpacity; // 0..1 - see PdfRedactArea's doc comment on why
  final String? resultPath;
  final String? error;

  RedactState({
    this.sourceFile,
    this.isLoading = false,
    this.isSaving = false,
    this.pages = const [],
    this.words = const [],
    this.currentPageIndex = 0,
    this.selections = const [],
    Color? nextColor,
    this.barOpacity = 1.0,
    this.resultPath,
    this.error,
  }) : nextColor = nextColor ?? _defaultHsv.toColor();

  /// The selection (if any) that currently holds [wordIndex] - at most one
  /// ever will, since [RedactController.commitSelection] always claims a
  /// word away from its previous selection before adding it to a new one.
  RedactSelection? selectionOf(int wordIndex) {
    for (final s in selections) {
      if (s.wordIndices.contains(wordIndex)) return s;
    }
    return null;
  }

  RedactState copyWith({
    PdfFile? sourceFile,
    bool? isLoading,
    bool? isSaving,
    List<PdfPageImage>? pages,
    List<PdfTextWord>? words,
    int? currentPageIndex,
    List<RedactSelection>? selections,
    Color? nextColor,
    double? barOpacity,
    String? resultPath,
    String? error,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return RedactState(
      sourceFile: sourceFile ?? this.sourceFile,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      pages: pages ?? this.pages,
      words: words ?? this.words,
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
      selections: selections ?? this.selections,
      nextColor: nextColor ?? this.nextColor,
      barOpacity: barOpacity ?? this.barOpacity,
      resultPath: clearResult ? null : (resultPath ?? this.resultPath),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class RedactController extends Notifier<RedactState> {
  @override
  RedactState build() => RedactState();

  Future<void> setSourceFile(PdfFile file) async {
    state = RedactState(sourceFile: file, isLoading: true);
    try {
      final repo = ref.read(pdfRepositoryProvider);
      final results = await Future.wait([
        repo.renderPageImages(file.path),
        repo.extractTextWords(file.path),
      ]);
      state = state.copyWith(
        isLoading: false,
        pages: results[0] as List<PdfPageImage>,
        words: results[1] as List<PdfTextWord>,
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

  /// A plain tap passes a single-word set; a drag passes every word index
  /// the gesture passed over. Becomes one new selection using whatever
  /// color the spectrum bar is currently showing ([RedactState.nextColor]).
  /// That color then stays put for every following selection too, until the
  /// user drags the spectrum bar to a different one themselves - no
  /// auto-advancing here, so "pick a tone once, mark several things with
  /// it" works the way it visually looks like it should. A gesture that
  /// *starts* on an already-marked word removes that whole selection
  /// instead - see [removeSelection], called by the screen itself before
  /// this ever gets reached in that case.
  void commitSelection(Set<int> wordIndices) {
    if (wordIndices.isEmpty) return;

    // Claim these words away from whatever selection (if any) already held
    // them, dropping any selection that's now empty.
    final List<RedactSelection> claimed = [
      for (final s in state.selections)
        if (s.wordIndices.difference(wordIndices).isNotEmpty)
          RedactSelection(
            color: s.color,
            wordIndices: s.wordIndices.difference(wordIndices),
          ),
    ];
    state = state.copyWith(
      selections: [
        ...claimed,
        RedactSelection(color: state.nextColor, wordIndices: wordIndices),
      ],
      clearResult: true,
    );
  }

  /// Removes one whole selection (by reference - `RedactSelection` has no
  /// separate id, but the screen always hands back the exact instance from
  /// [RedactState.selectionOf], so default identity equality is enough).
  void removeSelection(RedactSelection selection) {
    state = state.copyWith(
      selections: [
        for (final s in state.selections)
          if (s != selection) s,
      ],
      clearResult: true,
    );
  }

  /// Manual override from dragging the spectrum bar - the color the *next*
  /// selection will use (until this or the auto-advance in
  /// [commitSelection] changes it again).
  void setNextColor(Color color) {
    state = state.copyWith(nextColor: color);
  }

  void setBarOpacity(double opacity) {
    state = state.copyWith(
      barOpacity: opacity.clamp(0, 1),
      clearResult: true,
    );
  }

  Future<void> redact() async {
    final file = state.sourceFile;
    if (file == null) return;
    if (state.selections.isEmpty) {
      state = state.copyWith(error: 'errorMarkAtLeastOneLineToRedact');
      return;
    }

    await AdsService.instance.interstitial.showBeforeOperation();
    state = state.copyWith(
      isSaving: true,
      clearError: true,
      clearResult: true,
    );
    try {
      final List<PdfRedactArea> areas = [];
      for (final RedactSelection selection in state.selections) {
        // A selection spanning more than one line becomes more than one
        // area (one bounding rect per line it touches), all sharing this
        // selection's color.
        final Map<int, List<PdfTextWord>> byLine = {};
        for (final int i in selection.wordIndices) {
          final PdfTextWord w = state.words[i];
          byLine.putIfAbsent(w.lineIndex, () => []).add(w);
        }
        final int colorR = (selection.color.r * 255.0).round().clamp(0, 255);
        final int colorG = (selection.color.g * 255.0).round().clamp(0, 255);
        final int colorB = (selection.color.b * 255.0).round().clamp(0, 255);
        for (final List<PdfTextWord> lineWords in byLine.values) {
          double left = lineWords.first.left;
          double top = lineWords.first.top;
          double right = lineWords.first.left + lineWords.first.width;
          double bottom = lineWords.first.top + lineWords.first.height;
          for (final PdfTextWord w in lineWords.skip(1)) {
            if (w.left < left) left = w.left;
            if (w.top < top) top = w.top;
            if (w.left + w.width > right) right = w.left + w.width;
            if (w.top + w.height > bottom) bottom = w.top + w.height;
          }
          areas.add(
            PdfRedactArea(
              pageIndex: lineWords.first.pageIndex,
              left: left,
              top: top,
              width: right - left,
              height: bottom - top,
              colorR: colorR,
              colorG: colorG,
              colorB: colorB,
              opacity: state.barOpacity,
            ),
          );
        }
      }

      final useCase = ref.read(redactPdfUseCaseProvider);
      final path = await useCase(file.path, areas);
      state = state.copyWith(isSaving: false, resultPath: path);
    } catch (e) {
      state = state.copyWith(isSaving: false, error: friendlyErrorMessage(e));
    }
  }

  void reset() {
    state = RedactState();
  }
}

// autoDispose: state resets when the screen is popped, so returning to
// Redact later starts fresh instead of showing the previous result (same
// reasoning as ContentEditController).
final redactControllerProvider =
    NotifierProvider.autoDispose<RedactController, RedactState>(
      RedactController.new,
    );
