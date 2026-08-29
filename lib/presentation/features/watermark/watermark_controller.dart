import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ads/ads_service.dart';
import '../../../core/error_message.dart';
import '../../../core/providers.dart';
import '../../../domain/entities/pdf_file.dart';
import '../../../domain/entities/watermark_options.dart';
import '../../../domain/usecases/watermark_pdf_usecase.dart';

final watermarkPdfUseCaseProvider = Provider(
  (ref) => WatermarkPdfUseCase(ref.watch(pdfRepositoryProvider)),
);

/// A watermark color swatch offered in the UI, paired with a label.
class WatermarkColorOption {
  final String label;
  final int r;
  final int g;
  final int b;

  const WatermarkColorOption(this.label, this.r, this.g, this.b);
}

const WatermarkColorOption _defaultWatermarkColor = WatermarkColorOption(
  'Gray',
  128,
  128,
  128,
);

const List<WatermarkColorOption> watermarkColorOptions = [
  _defaultWatermarkColor,
  WatermarkColorOption('Red', 220, 38, 38),
  WatermarkColorOption('Blue', 37, 99, 235),
  WatermarkColorOption('Black', 0, 0, 0),
];

class WatermarkState {
  final PdfFile? sourceFile;
  final String text;
  final double opacity;
  final double fontSize;
  final WatermarkColorOption color;
  final bool isProcessing;
  final String? resultPath;
  final String? error;

  const WatermarkState({
    this.sourceFile,
    this.text = '',
    this.opacity = 0.3,
    this.fontSize = 60,
    this.color = _defaultWatermarkColor,
    this.isProcessing = false,
    this.resultPath,
    this.error,
  });

  WatermarkState copyWith({
    PdfFile? sourceFile,
    String? text,
    double? opacity,
    double? fontSize,
    WatermarkColorOption? color,
    bool? isProcessing,
    String? resultPath,
    String? error,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return WatermarkState(
      sourceFile: sourceFile ?? this.sourceFile,
      text: text ?? this.text,
      opacity: opacity ?? this.opacity,
      fontSize: fontSize ?? this.fontSize,
      color: color ?? this.color,
      isProcessing: isProcessing ?? this.isProcessing,
      resultPath: clearResult ? null : (resultPath ?? this.resultPath),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class WatermarkController extends Notifier<WatermarkState> {
  @override
  WatermarkState build() => const WatermarkState();

  void setSourceFile(PdfFile file) {
    state = state.copyWith(
      sourceFile: file,
      clearResult: true,
      clearError: true,
    );
  }

  void setText(String value) {
    state = state.copyWith(text: value, clearError: true);
  }

  void setOpacity(double value) {
    state = state.copyWith(opacity: value);
  }

  void setFontSize(double value) {
    state = state.copyWith(fontSize: value);
  }

  void setColor(WatermarkColorOption color) {
    state = state.copyWith(color: color);
  }

  Future<void> submit() async {
    final file = state.sourceFile;
    if (file == null) {
      state = state.copyWith(error: 'errorSelectPdfFirst');
      return;
    }
    if (state.text.trim().isEmpty) {
      state = state.copyWith(error: 'errorEnterWatermarkText');
      return;
    }

    await AdsService.instance.interstitial.showBeforeOperation();
    state = state.copyWith(
      isProcessing: true,
      clearError: true,
      clearResult: true,
    );
    try {
      final useCase = ref.read(watermarkPdfUseCaseProvider);
      final path = await useCase(
        file.path,
        WatermarkOptions(
          text: state.text,
          opacity: state.opacity,
          fontSize: state.fontSize,
          colorR: state.color.r,
          colorG: state.color.g,
          colorB: state.color.b,
        ),
      );
      state = state.copyWith(isProcessing: false, resultPath: path);
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: friendlyErrorMessage(e));
    }
  }

  void reset() {
    state = const WatermarkState();
  }
}

final watermarkControllerProvider =
    NotifierProvider.autoDispose<WatermarkController, WatermarkState>(
      WatermarkController.new,
    );
