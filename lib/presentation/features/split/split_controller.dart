import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ads/ads_service.dart';
import '../../../core/providers.dart';
import '../../../domain/entities/page_range.dart';
import '../../../domain/entities/pdf_file.dart';
import '../../../domain/usecases/split_pdf_usecase.dart';

final splitPdfUseCaseProvider = Provider(
  (ref) => SplitPdfUseCase(ref.watch(pdfRepositoryProvider)),
);

/// Parses text like "1-3, 5, 7-9" into [PageRange]s. Throws
/// [FormatException] on malformed input.
List<PageRange> parsePageRanges(String input) {
  final parts = input
      .split(',')
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty);
  if (parts.isEmpty) {
    throw const FormatException('No ranges provided.');
  }
  return parts.map((part) {
    final segments = part.split('-').map((s) => s.trim()).toList();
    if (segments.length == 1) {
      final page = int.tryParse(segments[0]);
      if (page == null) throw FormatException('Invalid page: $part');
      return PageRange(page, page);
    } else if (segments.length == 2) {
      final start = int.tryParse(segments[0]);
      final end = int.tryParse(segments[1]);
      if (start == null || end == null) {
        throw FormatException('Invalid range: $part');
      }
      return PageRange(start, end);
    }
    throw FormatException('Invalid range: $part');
  }).toList();
}

class SplitState {
  final PdfFile? sourceFile;
  final int? pageCount;
  final bool everyPage;
  final String rangesInput;
  final bool isSplitting;
  final List<String> resultPaths;
  final String? error;

  const SplitState({
    this.sourceFile,
    this.pageCount,
    this.everyPage = false,
    this.rangesInput = '',
    this.isSplitting = false,
    this.resultPaths = const [],
    this.error,
  });

  SplitState copyWith({
    PdfFile? sourceFile,
    int? pageCount,
    bool? everyPage,
    String? rangesInput,
    bool? isSplitting,
    List<String>? resultPaths,
    String? error,
    bool clearError = false,
  }) {
    return SplitState(
      sourceFile: sourceFile ?? this.sourceFile,
      pageCount: pageCount ?? this.pageCount,
      everyPage: everyPage ?? this.everyPage,
      rangesInput: rangesInput ?? this.rangesInput,
      isSplitting: isSplitting ?? this.isSplitting,
      resultPaths: resultPaths ?? this.resultPaths,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class SplitController extends Notifier<SplitState> {
  @override
  SplitState build() => const SplitState();

  Future<void> setSourceFile(PdfFile file) async {
    state = SplitState(sourceFile: file);
    try {
      final repo = ref.read(pdfRepositoryProvider);
      final count = await repo.getPageCount(file.path);
      state = state.copyWith(pageCount: count);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void setEveryPage(bool value) {
    state = state.copyWith(everyPage: value, clearError: true);
  }

  void setRangesInput(String value) {
    state = state.copyWith(rangesInput: value, clearError: true);
  }

  Future<void> split() async {
    final file = state.sourceFile;
    if (file == null) {
      state = state.copyWith(error: 'Avval ye PDF entekhab kon.');
      return;
    }

    List<PageRange> ranges;
    if (state.everyPage) {
      final count = state.pageCount ?? 0;
      ranges = List.generate(count, (i) => PageRange(i + 1, i + 1));
    } else {
      try {
        ranges = parsePageRanges(state.rangesInput);
      } on FormatException catch (e) {
        state = state.copyWith(error: e.message);
        return;
      }
    }

    await AdsService.instance.interstitial.showBeforeOperation();
    state = state.copyWith(
      isSplitting: true,
      clearError: true,
      resultPaths: [],
    );
    try {
      final useCase = ref.read(splitPdfUseCaseProvider);
      final paths = await useCase(file.path, ranges);
      state = state.copyWith(isSplitting: false, resultPaths: paths);
    } catch (e) {
      state = state.copyWith(isSplitting: false, error: e.toString());
    }
  }

  Future<String> zipResults() {
    final repo = ref.read(pdfRepositoryProvider);
    return repo.zipFiles(
      state.resultPaths,
      'purapdf_split_${DateTime.now().millisecondsSinceEpoch}.zip',
    );
  }

  void reset() {
    state = const SplitState();
  }
}

// autoDispose: state resets when the screen is popped, so returning to
// Split later starts fresh instead of showing the previous result.
final splitControllerProvider =
    NotifierProvider.autoDispose<SplitController, SplitState>(
      SplitController.new,
    );
