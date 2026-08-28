import 'dart:async';

import 'package:doclens/doclens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ads/ads_service.dart';
import '../../../core/providers.dart';
import '../../../domain/usecases/scan_documents_usecase.dart';

final scanDocumentsUseCaseProvider = Provider(
  (ref) => ScanDocumentsUseCase(ref.watch(pdfRepositoryProvider)),
);

class ScannerState {
  final List<String> pages;
  final bool isScanning;
  final bool isCreatingPdf;
  final String? resultPath;
  final String? error;

  const ScannerState({
    this.pages = const [],
    this.isScanning = false,
    this.isCreatingPdf = false,
    this.resultPath,
    this.error,
  });

  ScannerState copyWith({
    List<String>? pages,
    bool? isScanning,
    bool? isCreatingPdf,
    String? resultPath,
    String? error,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return ScannerState(
      pages: pages ?? this.pages,
      isScanning: isScanning ?? this.isScanning,
      isCreatingPdf: isCreatingPdf ?? this.isCreatingPdf,
      resultPath: clearResult ? null : (resultPath ?? this.resultPath),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ScannerController extends Notifier<ScannerState> {
  @override
  ScannerState build() => const ScannerState();

  /// Hands off to the OS's own document scanner (VisionKit on iOS, ML Kit's
  /// document scanner on Android) — live edge detection, auto-capture,
  /// multi-page, perspective correction all happen natively. Newly scanned
  /// pages are appended, so scanning again adds more pages instead of
  /// replacing the batch.
  Future<void> scan() async {
    state = state.copyWith(
      isScanning: true,
      clearError: true,
      clearResult: true,
    );
    try {
      final List<String>? scanned = await DoclensPlatform.instance
          .scanWithNativeUI(allowGalleryImport: true);
      state = state.copyWith(
        isScanning: false,
        pages: scanned == null ? state.pages : [...state.pages, ...scanned],
      );
    } catch (e) {
      state = state.copyWith(isScanning: false, error: e.toString());
    }
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

  Future<void> createPdf() async {
    if (state.pages.isEmpty) {
      state = state.copyWith(error: 'Scan at least one page first.');
      return;
    }
    state = state.copyWith(
      isCreatingPdf: true,
      clearError: true,
      clearResult: true,
    );
    try {
      final useCase = ref.read(scanDocumentsUseCaseProvider);
      final path = await useCase(state.pages);
      state = state.copyWith(isCreatingPdf: false, resultPath: path);
      unawaited(AdsService.instance.interstitial.recordOperationAndMaybeShow());
    } catch (e) {
      state = state.copyWith(isCreatingPdf: false, error: e.toString());
    }
  }

  void reset() {
    state = const ScannerState();
  }
}

// autoDispose: state resets when the screen is popped, so returning to
// Scan later starts fresh instead of showing the previous result.
final scannerControllerProvider =
    NotifierProvider.autoDispose<ScannerController, ScannerState>(
      ScannerController.new,
    );
