import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/pdf_repository_impl.dart';
import '../domain/repositories/pdf_repository.dart';

/// Shared DI root: every feature controller reads [PdfRepository] through
/// this single provider so there is one instance and one place to swap the
/// implementation (e.g. for tests).
final pdfRepositoryProvider = Provider<PdfRepository>(
  (ref) => PdfRepositoryImpl(),
);
