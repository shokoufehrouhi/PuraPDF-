import 'package:flutter/material.dart';

import '../../domain/entities/pdf_file.dart';
import '../../presentation/features/compress/compress_controller.dart';
import '../../presentation/features/compress/compress_screen.dart';
import '../../presentation/features/content_edit/content_edit_controller.dart';
import '../../presentation/features/content_edit/content_edit_screen.dart';
import '../../presentation/features/encrypt/encrypt_controller.dart';
import '../../presentation/features/encrypt/encrypt_screen.dart';
import '../../presentation/features/fill_sign/fill_sign_controller.dart';
import '../../presentation/features/fill_sign/fill_sign_screen.dart';
import '../../presentation/features/image_pdf/image_pdf_controller.dart';
import '../../presentation/features/image_pdf/image_pdf_screen.dart';
import '../../presentation/features/merge/merge_controller.dart';
import '../../presentation/features/merge/merge_screen.dart';
import '../../presentation/features/page_edit/page_edit_controller.dart';
import '../../presentation/features/page_edit/page_edit_screen.dart';
import '../../presentation/features/pdf_word/pdf_word_controller.dart';
import '../../presentation/features/pdf_word/pdf_word_screen.dart';
import '../../presentation/features/redact/redact_controller.dart';
import '../../presentation/features/redact/redact_screen.dart';
import '../../presentation/features/signature/signature_controller.dart';
import '../../presentation/features/signature/signature_screen.dart';
import '../../presentation/features/split/split_controller.dart';
import '../../presentation/features/split/split_screen.dart';
import '../../presentation/features/watermark/watermark_controller.dart';
import '../../presentation/features/watermark/watermark_screen.dart';
import '../../presentation/shared_widgets/preloaded_route.dart';

/// Builds the screen a share-extension tool id opens to, pre-loaded with
/// the shared file - one entry per `id` in
/// `ios/ShareExtension/ShareViewController.swift`'s `pdfTools`/`imageTools`
/// lists (kept in sync by hand; nothing enforces the two lists matching
/// beyond this comment, since one's Swift and the other's Dart).
typedef _ScreenBuilder = Widget Function(PdfFile file);

final Map<String, _ScreenBuilder> _builders = {
  'compress': (file) => PreloadedRoute(
    child: const CompressScreen(),
    preload: (ref) =>
        ref.read(compressControllerProvider.notifier).setSourceFile(file),
  ),
  'split': (file) => PreloadedRoute(
    child: const SplitScreen(),
    preload: (ref) =>
        ref.read(splitControllerProvider.notifier).setSourceFile(file),
  ),
  'merge': (file) => PreloadedRoute(
    child: const MergeScreen(),
    preload: (ref) =>
        ref.read(mergeControllerProvider.notifier).addFiles([file]),
  ),
  'edit': (file) => PreloadedRoute(
    child: const ContentEditScreen(),
    preload: (ref) =>
        ref.read(contentEditControllerProvider.notifier).setSourceFile(file),
  ),
  'redact': (file) => PreloadedRoute(
    child: const RedactScreen(),
    preload: (ref) =>
        ref.read(redactControllerProvider.notifier).setSourceFile(file),
  ),
  'watermark': (file) => PreloadedRoute(
    child: const WatermarkScreen(),
    preload: (ref) =>
        ref.read(watermarkControllerProvider.notifier).setSourceFile(file),
  ),
  'password': (file) => PreloadedRoute(
    child: const EncryptScreen(),
    preload: (ref) =>
        ref.read(encryptControllerProvider.notifier).setSourceFile(file),
  ),
  'signature': (file) => PreloadedRoute(
    child: const SignatureScreen(),
    preload: (ref) =>
        ref.read(signatureControllerProvider.notifier).setSourceFile(file),
  ),
  'fillsign': (file) => PreloadedRoute(
    child: const FillSignScreen(),
    preload: (ref) =>
        ref.read(fillSignControllerProvider.notifier).setSourceFile(file),
  ),
  'pageedit': (file) => PreloadedRoute(
    child: const PageEditScreen(),
    preload: (ref) =>
        ref.read(pageEditControllerProvider.notifier).setSourceFile(file),
  ),
  'pdfword': (file) => PreloadedRoute(
    child: const PdfWordScreen(),
    preload: (ref) =>
        ref.read(pdfWordControllerProvider.notifier).setSourceFile(file),
  ),
  'imagepdf': (file) => PreloadedRoute(
    child: const ImagePdfScreen(),
    preload: (ref) =>
        ref.read(imagePdfControllerProvider.notifier).addImages([file]),
  ),
};

/// Pushes the screen for [tool] (see `_builders`) pre-loaded with the file
/// at [path]. An unrecognized [tool] (the two hand-kept-in-sync lists
/// drifting apart, most likely) is silently ignored rather than crashing -
/// there's no good in-app way to surface "the share extension sent
/// something this build doesn't know about" to the user.
void openSharedFile(
  BuildContext context, {
  required String path,
  required String tool,
}) {
  final builder = _builders[tool];
  if (builder == null) return;
  final file = PdfFile(path: path, name: path.split('/').last);
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => builder(file)));
}
