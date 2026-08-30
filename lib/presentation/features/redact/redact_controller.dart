import 'dart:math';
import 'dart:ui';

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

/// Auto-assigned, in this order, to each new selection - no manual color
/// picker (a deliberate scope call: one less tap per selection).
const List<Color> redactPalette = [
  Color(0xFF000000), // black
  Color(0xFFDC2626), // red
  Color(0xFF2563EB), // blue
  Color(0xFF64748B), // gray
  Color(0xFFEC4899), // pink
  Color(0xFFF97316), // orange
  Color(0xFF14B8A6), // turquoise
];

/// One tap (a single word) or one drag (a range of adjacent words) - each
/// gets its own color from [redactPalette]. [wordIndices] are indices into
/// [RedactState.words].
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
  // Counts every selection ever created (not selections.length, which
  // shrinks when one is removed) so color assignment always advances
  // through the palette instead of ever reusing a color still in use.
  final int nextColorIndex;
  final double barOpacity; // 0..1 - see PdfRedactArea's doc comment on why
  final String? resultPath;
  final String? error;

  const RedactState({
    this.sourceFile,
    this.isLoading = false,
    this.isSaving = false,
    this.pages = const [],
    this.words = const [],
    this.currentPageIndex = 0,
    this.selections = const [],
    this.nextColorIndex = 0,
    this.barOpacity = 1.0,
    this.resultPath,
    this.error,
  });

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
    int? nextColorIndex,
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
      nextColorIndex: nextColorIndex ?? this.nextColorIndex,
      barOpacity: barOpacity ?? this.barOpacity,
      resultPath: clearResult ? null : (resultPath ?? this.resultPath),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class RedactController extends Notifier<RedactState> {
  @override
  RedactState build() => const RedactState();

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
  /// the gesture passed over. Either way this becomes one new selection
  /// with the next palette color - *except* re-committing the exact same
  /// lone word a second time (a second tap on an already-selected single
  /// word) removes it instead, the plain toggle-off case.
  void commitSelection(Set<int> wordIndices) {
    if (wordIndices.isEmpty) return;

    if (wordIndices.length == 1) {
      final int only = wordIndices.first;
      final bool wasLoneSelection = state.selections.any(
        (s) => s.wordIndices.length == 1 && s.wordIndices.contains(only),
      );
      if (wasLoneSelection) {
        final List<RedactSelection> updated = [
          for (final s in state.selections)
            if (!(s.wordIndices.length == 1 && s.wordIndices.contains(only)))
              s,
        ];
        state = state.copyWith(selections: updated, clearResult: true);
        return;
      }
    }

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
    final Color color =
        redactPalette[state.nextColorIndex % redactPalette.length];
    state = state.copyWith(
      selections: [
        ...claimed,
        RedactSelection(color: color, wordIndices: wordIndices),
      ],
      nextColorIndex: state.nextColorIndex + 1,
      clearResult: true,
    );
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
    state = const RedactState();
  }
}

// autoDispose: state resets when the screen is popped, so returning to
// Redact later starts fresh instead of showing the previous result (same
// reasoning as ContentEditController).
final redactControllerProvider =
    NotifierProvider.autoDispose<RedactController, RedactState>(
      RedactController.new,
    );
