import 'dart:math';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ads/ads_service.dart';
import '../../../core/error_message.dart';
import '../../../core/providers.dart';
import '../../../domain/entities/pdf_file.dart';
import '../../../domain/entities/pdf_page_image.dart';
import '../../../domain/entities/pdf_redact_area.dart';
import '../../../domain/entities/pdf_text_line.dart';
import '../../../domain/usecases/redact_pdf_usecase.dart';

final redactPdfUseCaseProvider = Provider(
  (ref) => RedactPdfUseCase(ref.watch(pdfRepositoryProvider)),
);

class RedactState {
  final PdfFile? sourceFile;
  final bool isLoading;
  final bool isSaving;
  final List<PdfPageImage> pages;
  final List<PdfTextLine> textLines;
  final int currentPageIndex;
  final Set<int> markedLines;
  final Color barColor;
  final double barOpacity; // 0..1 - see PdfRedactArea's doc comment on why
  final String? resultPath;
  final String? error;

  const RedactState({
    this.sourceFile,
    this.isLoading = false,
    this.isSaving = false,
    this.pages = const [],
    this.textLines = const [],
    this.currentPageIndex = 0,
    this.markedLines = const {},
    this.barColor = const Color(0xFF000000),
    this.barOpacity = 1.0,
    this.resultPath,
    this.error,
  });

  RedactState copyWith({
    PdfFile? sourceFile,
    bool? isLoading,
    bool? isSaving,
    List<PdfPageImage>? pages,
    List<PdfTextLine>? textLines,
    int? currentPageIndex,
    Set<int>? markedLines,
    Color? barColor,
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
      textLines: textLines ?? this.textLines,
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
      markedLines: markedLines ?? this.markedLines,
      barColor: barColor ?? this.barColor,
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

  void toggleLine(int lineIndex) {
    final Set<int> updated = {...state.markedLines};
    if (!updated.remove(lineIndex)) updated.add(lineIndex);
    state = state.copyWith(markedLines: updated, clearResult: true);
  }

  void setBarColor(Color color) {
    state = state.copyWith(barColor: color, clearResult: true);
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
    if (state.markedLines.isEmpty) {
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
      final List<PdfRedactArea> areas = [
        for (final int i in state.markedLines)
          PdfRedactArea(
            pageIndex: state.textLines[i].pageIndex,
            left: state.textLines[i].left,
            top: state.textLines[i].top,
            width: state.textLines[i].width,
            height: state.textLines[i].height,
            colorR: (state.barColor.r * 255.0).round().clamp(0, 255),
            colorG: (state.barColor.g * 255.0).round().clamp(0, 255),
            colorB: (state.barColor.b * 255.0).round().clamp(0, 255),
            opacity: state.barOpacity,
          ),
      ];

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
