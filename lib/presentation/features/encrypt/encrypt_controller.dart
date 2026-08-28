import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ads/ads_service.dart';
import '../../../core/providers.dart';
import '../../../domain/entities/pdf_file.dart';
import '../../../domain/usecases/decrypt_pdf_usecase.dart';
import '../../../domain/usecases/encrypt_pdf_usecase.dart';

final encryptPdfUseCaseProvider = Provider(
  (ref) => EncryptPdfUseCase(ref.watch(pdfRepositoryProvider)),
);

final decryptPdfUseCaseProvider = Provider(
  (ref) => DecryptPdfUseCase(ref.watch(pdfRepositoryProvider)),
);

enum PasswordAction { add, remove }

class EncryptState {
  final PasswordAction action;
  final PdfFile? sourceFile;
  final String password;
  final String confirmPassword;
  final bool obscurePassword;
  final bool isProcessing;
  final String? resultPath;
  final String? error;

  const EncryptState({
    this.action = PasswordAction.add,
    this.sourceFile,
    this.password = '',
    this.confirmPassword = '',
    this.obscurePassword = true,
    this.isProcessing = false,
    this.resultPath,
    this.error,
  });

  EncryptState copyWith({
    PasswordAction? action,
    PdfFile? sourceFile,
    String? password,
    String? confirmPassword,
    bool? obscurePassword,
    bool? isProcessing,
    String? resultPath,
    String? error,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return EncryptState(
      action: action ?? this.action,
      sourceFile: sourceFile ?? this.sourceFile,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      isProcessing: isProcessing ?? this.isProcessing,
      resultPath: clearResult ? null : (resultPath ?? this.resultPath),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class EncryptController extends Notifier<EncryptState> {
  @override
  EncryptState build() => const EncryptState();

  void setAction(PasswordAction action) {
    state = EncryptState(action: action);
  }

  void setSourceFile(PdfFile file) {
    state = state.copyWith(
      sourceFile: file,
      clearResult: true,
      clearError: true,
    );
  }

  void setPassword(String value) {
    state = state.copyWith(password: value, clearError: true);
  }

  void setConfirmPassword(String value) {
    state = state.copyWith(confirmPassword: value, clearError: true);
  }

  void toggleObscure() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  Future<void> submit() async {
    final file = state.sourceFile;
    if (file == null) {
      state = state.copyWith(error: 'Select a PDF first.');
      return;
    }
    if (state.password.isEmpty) {
      state = state.copyWith(error: 'Enter a password.');
      return;
    }
    if (state.action == PasswordAction.add &&
        state.password != state.confirmPassword) {
      state = state.copyWith(error: 'Passwords don\'t match.');
      return;
    }

    state = state.copyWith(
      isProcessing: true,
      clearError: true,
      clearResult: true,
    );
    try {
      final String path;
      if (state.action == PasswordAction.add) {
        final useCase = ref.read(encryptPdfUseCaseProvider);
        path = await useCase(file.path, state.password);
      } else {
        final useCase = ref.read(decryptPdfUseCaseProvider);
        path = await useCase(file.path, state.password);
      }
      state = state.copyWith(isProcessing: false, resultPath: path);
      unawaited(AdsService.instance.interstitial.recordOperationAndMaybeShow());
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
    }
  }

  void reset() {
    state = const EncryptState();
  }
}

final encryptControllerProvider =
    NotifierProvider.autoDispose<EncryptController, EncryptState>(
      EncryptController.new,
    );
