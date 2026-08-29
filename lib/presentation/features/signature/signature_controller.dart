import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ads/ads_service.dart';
import '../../../core/error_message.dart';
import '../../../core/providers.dart';
import '../../../domain/entities/pdf_content_edit.dart';
import '../../../domain/entities/pdf_file.dart';
import '../../../domain/entities/pdf_page_image.dart';
import '../../../domain/usecases/sign_pdf_usecase.dart';

final signPdfUseCaseProvider = Provider(
  (ref) => SignPdfUseCase(ref.watch(pdfRepositoryProvider)),
);

class SignatureState {
  final PdfFile? sourceFile;
  final List<PdfPageImage> pages;
  final int currentPageIndex;
  final bool isLoadingPages;
  final Uint8List? signatureBytes;
  final double leftFrac;
  final double topFrac;
  final double widthFrac;
  final double heightFrac;
  final bool isProcessing;
  final String? resultPath;
  final String? error;

  const SignatureState({
    this.sourceFile,
    this.pages = const [],
    this.currentPageIndex = 0,
    this.isLoadingPages = false,
    this.signatureBytes,
    // A signature reads best wide and short, parked near the bottom —
    // roughly where a real signature line sits on a document.
    this.leftFrac = 0.3,
    this.topFrac = 0.72,
    this.widthFrac = 0.4,
    this.heightFrac = 0.12,
    this.isProcessing = false,
    this.resultPath,
    this.error,
  });

  SignatureState copyWith({
    PdfFile? sourceFile,
    List<PdfPageImage>? pages,
    int? currentPageIndex,
    bool? isLoadingPages,
    Uint8List? signatureBytes,
    double? leftFrac,
    double? topFrac,
    double? widthFrac,
    double? heightFrac,
    bool? isProcessing,
    String? resultPath,
    String? error,
    bool clearSignature = false,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return SignatureState(
      sourceFile: sourceFile ?? this.sourceFile,
      pages: pages ?? this.pages,
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
      isLoadingPages: isLoadingPages ?? this.isLoadingPages,
      signatureBytes: clearSignature
          ? null
          : (signatureBytes ?? this.signatureBytes),
      leftFrac: leftFrac ?? this.leftFrac,
      topFrac: topFrac ?? this.topFrac,
      widthFrac: widthFrac ?? this.widthFrac,
      heightFrac: heightFrac ?? this.heightFrac,
      isProcessing: isProcessing ?? this.isProcessing,
      resultPath: clearResult ? null : (resultPath ?? this.resultPath),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class SignatureController extends Notifier<SignatureState> {
  @override
  SignatureState build() => const SignatureState();

  Future<void> setSourceFile(PdfFile file) async {
    state = SignatureState(sourceFile: file, isLoadingPages: true);
    try {
      final repo = ref.read(pdfRepositoryProvider);
      final pages = await repo.renderPageImages(file.path);
      state = state.copyWith(isLoadingPages: false, pages: pages);
    } catch (e) {
      state = state.copyWith(
        isLoadingPages: false,
        error: friendlyErrorMessage(e),
      );
    }
  }

  void setPage(int index) {
    final int clamped = index.clamp(0, max(0, state.pages.length - 1));
    state = state.copyWith(currentPageIndex: clamped);
  }

  void setSignature(Uint8List bytes) {
    state = state.copyWith(
      signatureBytes: bytes,
      leftFrac: 0.3,
      topFrac: 0.72,
      widthFrac: 0.4,
      heightFrac: 0.12,
      clearResult: true,
    );
  }

  void removeSignature() {
    state = state.copyWith(clearSignature: true);
  }

  void moveSignature(double leftFrac, double topFrac) {
    final double maxLeft = 1 - state.widthFrac;
    final double maxTop = 1 - state.heightFrac;
    state = state.copyWith(
      leftFrac: leftFrac.clamp(0, maxLeft < 0 ? 0 : maxLeft),
      topFrac: topFrac.clamp(0, maxTop < 0 ? 0 : maxTop),
    );
  }

  Future<void> submit() async {
    final file = state.sourceFile;
    final Uint8List? signature = state.signatureBytes;
    if (file == null || state.pages.isEmpty) return;
    if (signature == null) {
      state = state.copyWith(error: 'errorAddSignatureFirst');
      return;
    }

    await AdsService.instance.interstitial.showBeforeOperation();
    state = state.copyWith(
      isProcessing: true,
      clearError: true,
      clearResult: true,
    );
    try {
      final page = state.pages[state.currentPageIndex];
      final useCase = ref.read(signPdfUseCaseProvider);
      final path = await useCase(
        file.path,
        PdfImageInsert(
          pageIndex: state.currentPageIndex,
          imageBytes: signature,
          left: state.leftFrac * page.pointsWidth,
          top: state.topFrac * page.pointsHeight,
          width: state.widthFrac * page.pointsWidth,
          height: state.heightFrac * page.pointsHeight,
        ),
      );
      state = state.copyWith(isProcessing: false, resultPath: path);
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: friendlyErrorMessage(e));
    }
  }

  void reset() {
    state = const SignatureState();
  }
}

final signatureControllerProvider =
    NotifierProvider.autoDispose<SignatureController, SignatureState>(
      SignatureController.new,
    );
