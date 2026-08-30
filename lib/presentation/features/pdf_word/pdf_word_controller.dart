import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ads/ads_service.dart';
import '../../../core/error_message.dart';
import '../../../core/providers.dart';
import '../../../domain/entities/pdf_file.dart';
import '../../../domain/usecases/pdf_to_word_usecase.dart';
import '../../../domain/usecases/word_to_pdf_usecase.dart';

enum PdfWordDirection { pdfToWord, wordToPdf }

final pdfToWordUseCaseProvider = Provider(
  (ref) => PdfToWordUseCase(ref.watch(pdfRepositoryProvider)),
);

final wordToPdfUseCaseProvider = Provider(
  (ref) => WordToPdfUseCase(ref.watch(pdfRepositoryProvider)),
);

class PdfWordState {
  final PdfWordDirection direction;
  final PdfFile? sourceFile;
  final bool isProcessing;
  final String? resultPath;
  final String? error;

  const PdfWordState({
    this.direction = PdfWordDirection.pdfToWord,
    this.sourceFile,
    this.isProcessing = false,
    this.resultPath,
    this.error,
  });

  PdfWordState copyWith({
    PdfWordDirection? direction,
    PdfFile? sourceFile,
    bool? isProcessing,
    String? resultPath,
    String? error,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return PdfWordState(
      direction: direction ?? this.direction,
      sourceFile: sourceFile ?? this.sourceFile,
      isProcessing: isProcessing ?? this.isProcessing,
      resultPath: clearResult ? null : (resultPath ?? this.resultPath),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class PdfWordController extends Notifier<PdfWordState> {
  @override
  PdfWordState build() => const PdfWordState();

  void setDirection(PdfWordDirection direction) {
    state = PdfWordState(direction: direction);
  }

  void setSourceFile(PdfFile file) {
    state = state.copyWith(
      sourceFile: file,
      clearResult: true,
      clearError: true,
    );
  }

  Future<void> convert() async {
    final source = state.sourceFile;
    if (source == null) {
      state = state.copyWith(
        error: state.direction == PdfWordDirection.pdfToWord
            ? 'errorSelectPdfFirst'
            : 'errorSelectWordFirst',
      );
      return;
    }
    state = state.copyWith(
      isProcessing: true,
      clearError: true,
      clearResult: true,
    );
    try {
      await AdsService.instance.interstitial.showBeforeOperation();
      final String path;
      if (state.direction == PdfWordDirection.pdfToWord) {
        path = await ref.read(pdfToWordUseCaseProvider)(source.path);
      } else {
        path = await ref.read(wordToPdfUseCaseProvider)(source.path);
      }
      state = state.copyWith(isProcessing: false, resultPath: path);
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: friendlyErrorMessage(e));
    }
  }

  /// Clears everything except which direction (PDF->Word / Word->PDF) was
  /// selected — that's a mode choice, not data from the last run.
  void reset() {
    state = PdfWordState(direction: state.direction);
  }
}

// autoDispose: state resets when the screen is popped, so returning to
// PDF <-> Word later starts fresh instead of showing the previous result.
final pdfWordControllerProvider =
    NotifierProvider.autoDispose<PdfWordController, PdfWordState>(
      PdfWordController.new,
    );
