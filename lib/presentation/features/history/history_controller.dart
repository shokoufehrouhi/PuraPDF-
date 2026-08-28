import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../domain/entities/history_file.dart';
import '../../../domain/usecases/delete_history_file_usecase.dart';
import '../../../domain/usecases/list_history_usecase.dart';
import '../../../domain/usecases/rename_history_file_usecase.dart';

final listHistoryUseCaseProvider = Provider(
  (ref) => ListHistoryUseCase(ref.watch(pdfRepositoryProvider)),
);
final deleteHistoryFileUseCaseProvider = Provider(
  (ref) => DeleteHistoryFileUseCase(ref.watch(pdfRepositoryProvider)),
);
final renameHistoryFileUseCaseProvider = Provider(
  (ref) => RenameHistoryFileUseCase(ref.watch(pdfRepositoryProvider)),
);

class HistoryState {
  final List<HistoryFile> files;
  final String query;
  final bool isLoading;
  final String? error;

  const HistoryState({
    this.files = const [],
    this.query = '',
    this.isLoading = false,
    this.error,
  });

  List<HistoryFile> get filtered => query.trim().isEmpty
      ? files
      : files
            .where((f) => f.name.toLowerCase().contains(query.toLowerCase()))
            .toList();

  HistoryState copyWith({
    List<HistoryFile>? files,
    String? query,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return HistoryState(
      files: files ?? this.files,
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class HistoryController extends Notifier<HistoryState> {
  @override
  HistoryState build() => const HistoryState();

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final files = await ref.read(listHistoryUseCaseProvider)();
      state = state.copyWith(isLoading: false, files: files);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setQuery(String query) {
    state = state.copyWith(query: query);
  }

  Future<void> delete(String path) async {
    try {
      await ref.read(deleteHistoryFileUseCaseProvider)(path);
      state = state.copyWith(
        files: state.files.where((f) => f.path != path).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Deletes every file currently listed. Keeps whatever was already there
  /// on a partial failure (mid-loop error) rather than guessing at which
  /// ones actually got removed — a follow-up [refresh] will resync either
  /// way.
  Future<void> clearAll() async {
    if (state.files.isEmpty) return;
    final deleteFile = ref.read(deleteHistoryFileUseCaseProvider);
    try {
      for (final file in state.files) {
        await deleteFile(file.path);
      }
      state = state.copyWith(files: const []);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      await refresh();
    }
  }

  Future<void> rename(String path, String newName) async {
    try {
      final newPath = await ref.read(renameHistoryFileUseCaseProvider)(
        path,
        newName,
      );
      final updated = state.files
          .map(
            (f) => f.path == path
                ? HistoryFile(
                    path: newPath,
                    name: newPath.split('/').last,
                    sizeBytes: f.sizeBytes,
                    createdAt: f.createdAt,
                  )
                : f,
          )
          .toList();
      state = state.copyWith(files: updated);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final historyControllerProvider =
    NotifierProvider<HistoryController, HistoryState>(HistoryController.new);
