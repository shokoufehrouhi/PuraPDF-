import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ads/ads_service.dart';
import '../../../core/providers.dart';
import '../../../domain/entities/compress_result.dart';
import '../../../domain/entities/compression_level.dart';
import '../../../domain/entities/pdf_file.dart';
import '../../../domain/usecases/compress_pdf_usecase.dart';

final compressPdfUseCaseProvider = Provider(
  (ref) => CompressPdfUseCase(ref.watch(pdfRepositoryProvider)),
);

class CompressState {
  final PdfFile? sourceFile;
  final int? originalSizeBytes;
  final CompressionLevel level;
  final bool isCompressing;
  final CompressResult? result;
  final String? error;

  const CompressState({
    this.sourceFile,
    this.originalSizeBytes,
    this.level = CompressionLevel.medium,
    this.isCompressing = false,
    this.result,
    this.error,
  });

  CompressState copyWith({
    PdfFile? sourceFile,
    int? originalSizeBytes,
    CompressionLevel? level,
    bool? isCompressing,
    CompressResult? result,
    String? error,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return CompressState(
      sourceFile: sourceFile ?? this.sourceFile,
      originalSizeBytes: originalSizeBytes ?? this.originalSizeBytes,
      level: level ?? this.level,
      isCompressing: isCompressing ?? this.isCompressing,
      result: clearResult ? null : (result ?? this.result),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class CompressController extends Notifier<CompressState> {
  @override
  CompressState build() => const CompressState();

  Future<void> setSourceFile(PdfFile file) async {
    final size = await File(file.path).length();
    state = CompressState(sourceFile: file, originalSizeBytes: size);
  }

  void setLevel(CompressionLevel level) {
    state = state.copyWith(level: level, clearResult: true);
  }

  Future<void> compress() async {
    final file = state.sourceFile;
    if (file == null) {
      state = state.copyWith(error: 'Avval ye PDF entekhab kon.');
      return;
    }
    state = state.copyWith(
      isCompressing: true,
      clearError: true,
      clearResult: true,
    );
    try {
      final useCase = ref.read(compressPdfUseCaseProvider);
      final result = await useCase(file.path, state.level);
      state = state.copyWith(isCompressing: false, result: result);
      unawaited(AdsService.instance.interstitial.recordOperationAndMaybeShow());
    } catch (e) {
      state = state.copyWith(isCompressing: false, error: e.toString());
    }
  }

  void reset() {
    state = const CompressState();
  }
}

final compressControllerProvider =
    NotifierProvider<CompressController, CompressState>(CompressController.new);
