import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ads/ads_service.dart';
import '../../../core/error_message.dart';
import '../../../core/providers.dart';
import '../../../domain/entities/pdf_file.dart';
import '../../../domain/entities/pdf_form_field.dart';
import '../../../domain/entities/pdf_form_fill.dart';
import '../../../domain/entities/pdf_page_image.dart';
import '../../../domain/usecases/fill_sign_pdf_usecase.dart';

final fillSignPdfUseCaseProvider = Provider(
  (ref) => FillSignPdfUseCase(ref.watch(pdfRepositoryProvider)),
);

class FillSignState {
  final PdfFile? sourceFile;
  final bool isLoading;
  final bool isSaving;
  final List<PdfPageImage> pages;
  final List<PdfFormField> fields;
  final int currentPageIndex;
  // Keyed by PdfFormField.fieldIndex - only fields the user has actually
  // touched this session end up in here (see FillSignController.submit's
  // doc comment on why untouched fields don't need an entry).
  final Map<int, PdfFormFill> edits;
  final String? resultPath;
  final String? error;

  const FillSignState({
    this.sourceFile,
    this.isLoading = false,
    this.isSaving = false,
    this.pages = const [],
    this.fields = const [],
    this.currentPageIndex = 0,
    this.edits = const {},
    this.resultPath,
    this.error,
  });

  /// Current text for a text field - whatever the user last typed this
  /// session, falling back to what the PDF loaded with.
  String textFor(PdfFormField field) => edits[field.fieldIndex]?.text ?? field.initialText;

  /// Current checked state for a checkbox - same fallback as [textFor].
  bool checkedFor(PdfFormField field) =>
      edits[field.fieldIndex]?.checked ?? field.initialChecked;

  FillSignState copyWith({
    PdfFile? sourceFile,
    bool? isLoading,
    bool? isSaving,
    List<PdfPageImage>? pages,
    List<PdfFormField>? fields,
    int? currentPageIndex,
    Map<int, PdfFormFill>? edits,
    String? resultPath,
    String? error,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return FillSignState(
      sourceFile: sourceFile ?? this.sourceFile,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      pages: pages ?? this.pages,
      fields: fields ?? this.fields,
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
      edits: edits ?? this.edits,
      resultPath: clearResult ? null : (resultPath ?? this.resultPath),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class FillSignController extends Notifier<FillSignState> {
  @override
  FillSignState build() => const FillSignState();

  Future<void> setSourceFile(PdfFile file) async {
    state = FillSignState(sourceFile: file, isLoading: true);
    try {
      final repo = ref.read(pdfRepositoryProvider);
      final results = await Future.wait([
        repo.renderPageImages(file.path),
        repo.extractFormFields(file.path),
      ]);
      state = state.copyWith(
        isLoading: false,
        pages: results[0] as List<PdfPageImage>,
        fields: results[1] as List<PdfFormField>,
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

  void setFieldText(int fieldIndex, String text) {
    state = state.copyWith(
      edits: {
        ...state.edits,
        fieldIndex: PdfFormFill(fieldIndex: fieldIndex, text: text),
      },
      clearResult: true,
    );
  }

  void toggleCheckbox(PdfFormField field) {
    final bool next = !state.checkedFor(field);
    state = state.copyWith(
      edits: {
        ...state.edits,
        field.fieldIndex: PdfFormFill(
          fieldIndex: field.fieldIndex,
          checked: next,
        ),
      },
      clearResult: true,
    );
  }

  Future<void> submit() async {
    final file = state.sourceFile;
    if (file == null) return;
    if (state.edits.isEmpty) {
      state = state.copyWith(error: 'errorFillAtLeastOneFieldFirst');
      return;
    }

    await AdsService.instance.interstitial.showBeforeOperation();
    state = state.copyWith(
      isSaving: true,
      clearError: true,
      clearResult: true,
    );
    try {
      final useCase = ref.read(fillSignPdfUseCaseProvider);
      final path = await useCase(file.path, state.edits.values.toList());
      state = state.copyWith(isSaving: false, resultPath: path);
    } catch (e) {
      state = state.copyWith(isSaving: false, error: friendlyErrorMessage(e));
    }
  }

  void reset() {
    state = const FillSignState();
  }
}

// autoDispose: state resets when the screen is popped, same reasoning as
// RedactController/SignatureController.
final fillSignControllerProvider =
    NotifierProvider.autoDispose<FillSignController, FillSignState>(
      FillSignController.new,
    );
