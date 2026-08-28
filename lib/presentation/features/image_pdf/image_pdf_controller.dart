import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ads/ads_service.dart';
import '../../../core/providers.dart';
import '../../../domain/entities/image_output_format.dart';
import '../../../domain/entities/pdf_file.dart';
import '../../../domain/usecases/images_to_pdf_usecase.dart';
import '../../../domain/usecases/pdf_to_images_usecase.dart';

enum ConversionDirection { imagesToPdf, pdfToImages }

final imagesToPdfUseCaseProvider = Provider(
  (ref) => ImagesToPdfUseCase(ref.watch(pdfRepositoryProvider)),
);

final pdfToImagesUseCaseProvider = Provider(
  (ref) => PdfToImagesUseCase(ref.watch(pdfRepositoryProvider)),
);

class ImagePdfState {
  final ConversionDirection direction;
  final List<PdfFile> images;
  final PdfFile? sourcePdf;
  final ImageOutputFormat outputFormat;
  final bool isProcessing;
  final String? resultPdfPath;
  final List<String> resultImagePaths;
  final String? error;

  const ImagePdfState({
    this.direction = ConversionDirection.imagesToPdf,
    this.images = const [],
    this.sourcePdf,
    this.outputFormat = ImageOutputFormat.jpg,
    this.isProcessing = false,
    this.resultPdfPath,
    this.resultImagePaths = const [],
    this.error,
  });

  ImagePdfState copyWith({
    ConversionDirection? direction,
    List<PdfFile>? images,
    PdfFile? sourcePdf,
    ImageOutputFormat? outputFormat,
    bool? isProcessing,
    String? resultPdfPath,
    List<String>? resultImagePaths,
    String? error,
    bool clearResults = false,
    bool clearError = false,
  }) {
    return ImagePdfState(
      direction: direction ?? this.direction,
      images: images ?? this.images,
      sourcePdf: sourcePdf ?? this.sourcePdf,
      outputFormat: outputFormat ?? this.outputFormat,
      isProcessing: isProcessing ?? this.isProcessing,
      resultPdfPath: clearResults
          ? null
          : (resultPdfPath ?? this.resultPdfPath),
      resultImagePaths: clearResults
          ? const []
          : (resultImagePaths ?? this.resultImagePaths),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ImagePdfController extends Notifier<ImagePdfState> {
  @override
  ImagePdfState build() => const ImagePdfState();

  void setDirection(ConversionDirection direction) {
    state = ImagePdfState(direction: direction);
  }

  void addImages(List<PdfFile> files) {
    state = state.copyWith(
      images: [...state.images, ...files],
      clearResults: true,
      clearError: true,
    );
  }

  void removeImageAt(int index) {
    final updated = [...state.images]..removeAt(index);
    state = state.copyWith(images: updated);
  }

  void setSourcePdf(PdfFile file) {
    state = state.copyWith(
      sourcePdf: file,
      clearResults: true,
      clearError: true,
    );
  }

  void setOutputFormat(ImageOutputFormat format) {
    state = state.copyWith(outputFormat: format, clearResults: true);
  }

  Future<void> convert() async {
    state = state.copyWith(
      isProcessing: true,
      clearError: true,
      clearResults: true,
    );
    try {
      if (state.direction == ConversionDirection.imagesToPdf) {
        if (state.images.isEmpty) {
          state = state.copyWith(
            isProcessing: false,
            error: 'Hadde aghal ye aks entekhab kon.',
          );
          return;
        }
        final useCase = ref.read(imagesToPdfUseCaseProvider);
        final path = await useCase(state.images.map((f) => f.path).toList());
        state = state.copyWith(isProcessing: false, resultPdfPath: path);
        unawaited(
          AdsService.instance.interstitial.recordOperationAndMaybeShow(),
        );
      } else {
        final source = state.sourcePdf;
        if (source == null) {
          state = state.copyWith(
            isProcessing: false,
            error: 'Avval ye PDF entekhab kon.',
          );
          return;
        }
        final useCase = ref.read(pdfToImagesUseCaseProvider);
        final paths = await useCase(source.path, format: state.outputFormat);
        state = state.copyWith(isProcessing: false, resultImagePaths: paths);
        unawaited(
          AdsService.instance.interstitial.recordOperationAndMaybeShow(),
        );
      }
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
    }
  }

  /// Clears everything except which direction (Images→PDF / PDF→Images)
  /// was selected — that's a mode choice, not data from the last run.
  void reset() {
    state = ImagePdfState(direction: state.direction);
  }

  /// Bundles the PDF→Images conversion's output images into one ZIP.
  Future<String> zipResults() {
    final repo = ref.read(pdfRepositoryProvider);
    return repo.zipFiles(
      state.resultImagePaths,
      'purapdf_images_${DateTime.now().millisecondsSinceEpoch}.zip',
    );
  }
}

// autoDispose: state resets when the screen is popped, so returning to
// Image <-> PDF later starts fresh instead of showing the previous result.
final imagePdfControllerProvider =
    NotifierProvider.autoDispose<ImagePdfController, ImagePdfState>(
      ImagePdfController.new,
    );
