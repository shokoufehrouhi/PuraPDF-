import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/error_message.dart';
import '../../../core/theme/feature_colors.dart';
import '../../../domain/entities/pdf_file.dart';
import '../../../l10n/app_localizations.dart';
import '../../shared_widgets/direction_label.dart';
import '../../shared_widgets/download_file.dart';
import '../../shared_widgets/feature_screen_header.dart';
import '../../shared_widgets/picker_card.dart';
import '../../shared_widgets/start_over_button.dart';
import 'pdf_word_controller.dart';

const Color _color = FeatureColors.pdfWordIcon;

class PdfWordScreen extends ConsumerWidget {
  const PdfWordScreen({super.key});

  Future<void> _pickFile(WidgetRef ref, PdfWordDirection direction) async {
    final List<PlatformFile> picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        direction == PdfWordDirection.pdfToWord ? 'pdf' : 'docx',
      ],
    );
    if (picked.isEmpty || picked.first.path == null) return;
    final file = PdfFile(path: picked.first.path!, name: picked.first.name);
    ref.read(pdfWordControllerProvider.notifier).setSourceFile(file);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pdfWordControllerProvider);
    final controller = ref.read(pdfWordControllerProvider.notifier);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isPdfToWord = state.direction == PdfWordDirection.pdfToWord;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FeatureScreenHeader(
                icon: Icons.description_outlined,
                color: _color,
                title: l10n.pdfWordTitle,
                description: isPdfToWord
                    ? l10n.pdfToWordDescription
                    : l10n.wordToPdfDescription,
                fixedDescriptionLines: 3,
                steps: [
                  l10n.pdfWordStepSelect,
                  l10n.pdfWordStepConvert,
                  l10n.pdfWordStepSave,
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SegmentedButton<PdfWordDirection>(
                      style: SegmentedButton.styleFrom(
                        selectedBackgroundColor: _color.withValues(
                          alpha: 0.18,
                        ),
                        selectedForegroundColor: _color,
                      ),
                      segments: [
                        ButtonSegment(
                          value: PdfWordDirection.pdfToWord,
                          label: DirectionLabel(from: 'PDF', to: l10n.wordWord),
                        ),
                        ButtonSegment(
                          value: PdfWordDirection.wordToPdf,
                          label: DirectionLabel(from: l10n.wordWord, to: 'PDF'),
                        ),
                      ],
                      selected: {state.direction},
                      onSelectionChanged: (s) =>
                          controller.setDirection(s.first),
                    ),
                    const SizedBox(height: 16),
                    PickerCard(
                      icon: Icons.upload_file,
                      color: _color,
                      label: state.sourceFile?.name ??
                          (isPdfToWord
                              ? l10n.selectAPdf
                              : l10n.selectAWordFile),
                      hint: state.sourceFile == null
                          ? l10n.tapToBrowseFiles
                          : l10n.tapToChangeFile,
                      onTap: () => _pickFile(ref, state.direction),
                    ),
                    const SizedBox(height: 16),
                    if (state.resultPath != null)
                      StartOverButton(color: _color, onPressed: controller.reset)
                    else
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _color,
                          foregroundColor: Colors.white,
                        ),
                        icon: state.isProcessing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.sync_alt),
                        label: Text(l10n.pdfWordStepConvert),
                        onPressed: state.isProcessing
                            ? null
                            : controller.convert,
                      ),
                    if (state.error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        localizedError(context, state.error!),
                        style: TextStyle(color: scheme.error),
                      ),
                    ],
                    if (state.resultPath != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _color.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.check_circle, color: _color),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    isPdfToWord
                                        ? l10n.docCreatedSuccess
                                        : l10n.pdfCreatedSuccess,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _color,
                                      foregroundColor: Colors.white,
                                    ),
                                    icon: const Icon(Icons.ios_share),
                                    label: Text(l10n.share),
                                    onPressed: () => SharePlus.instance.share(
                                      ShareParams(
                                        files: [XFile(state.resultPath!)],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: _color,
                                      side: BorderSide(
                                        color: _color.withValues(alpha: 0.5),
                                      ),
                                    ),
                                    icon: const Icon(Icons.download_outlined),
                                    label: Text(l10n.download),
                                    onPressed: () =>
                                        downloadFile(context, state.resultPath!),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
