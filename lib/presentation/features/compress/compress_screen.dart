import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/error_message.dart';
import '../../../core/theme/feature_colors.dart';
import '../../../domain/entities/compression_level.dart';
import '../../../domain/entities/pdf_file.dart';
import '../../../l10n/app_localizations.dart';
import '../../shared_widgets/direction_label.dart';
import '../../shared_widgets/download_file.dart';
import '../../shared_widgets/feature_screen_header.dart';
import '../../shared_widgets/picker_card.dart';
import '../../shared_widgets/picking_overlay.dart';
import '../../shared_widgets/start_over_button.dart';
import 'compress_controller.dart';

const Color _color = FeatureColors.compressIcon;

class CompressScreen extends ConsumerWidget {
  const CompressScreen({super.key});

  Future<void> _pickFile(BuildContext context, WidgetRef ref) async {
    final List<PlatformFile> picked = await withPickingOverlay(
      context,
      () => FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      ),
    );
    if (picked.isEmpty || picked.first.path == null) return;
    final file = PdfFile(path: picked.first.path!, name: picked.first.name);
    await ref.read(compressControllerProvider.notifier).setSourceFile(file);
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(compressControllerProvider);
    final controller = ref.read(compressControllerProvider.notifier);
    final ColorScheme scheme = Theme.of(context).colorScheme;
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
                icon: Icons.compress,
                color: _color,
                title: l10n.compressTitle,
                description: l10n.compressDescription,
                steps: [
                  l10n.compressStepSelect,
                  l10n.compressStepLevel,
                  l10n.compressStepCompress,
                  l10n.compressStepSave,
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PickerCard(
                      icon: Icons.upload_file,
                      color: _color,
                      label: state.sourceFile?.name ?? l10n.selectAPdf,
                      hint: state.sourceFile == null
                          ? l10n.tapToBrowseFiles
                          : state.originalSizeBytes != null
                          ? l10n.compressOriginalSizeHint(
                              _formatSize(state.originalSizeBytes!),
                            )
                          : l10n.tapToChangeFile,
                      onTap: () => _pickFile(context, ref),
                    ),
                    if (state.sourceFile != null) ...[
                      const SizedBox(height: 16),
                      SegmentedButton<CompressionLevel>(
                        style: SegmentedButton.styleFrom(
                          selectedBackgroundColor: _color.withValues(
                            alpha: 0.18,
                          ),
                          selectedForegroundColor: _color,
                        ),
                        segments: [
                          ButtonSegment(
                            value: CompressionLevel.low,
                            label: Text(l10n.compressLow),
                          ),
                          ButtonSegment(
                            value: CompressionLevel.medium,
                            label: Text(l10n.compressMedium),
                          ),
                          ButtonSegment(
                            value: CompressionLevel.high,
                            label: Text(l10n.compressHigh),
                          ),
                        ],
                        selected: {state.level},
                        onSelectionChanged: (selection) =>
                            controller.setLevel(selection.first),
                      ),
                      if (state.level == CompressionLevel.high) ...[
                        const SizedBox(height: 8),
                        Text(
                          l10n.compressHighWarning,
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (state.result != null)
                        StartOverButton(
                          color: _color,
                          onPressed: controller.reset,
                        )
                      else
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _color,
                            foregroundColor: Colors.white,
                          ),
                          icon: state.isCompressing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.compress),
                          label: Text(l10n.compressButton),
                          onPressed: state.isCompressing
                              ? null
                              : controller.compress,
                        ),
                    ],
                    if (state.error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        localizedError(context, state.error!),
                        style: TextStyle(color: scheme.error),
                      ),
                    ],
                    if (state.result != null) ...[
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
                                    l10n.compressReductionPercent(
                                      state.result!.reductionPercent
                                          .toStringAsFixed(1),
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            DirectionLabel(
                              from:
                                  '${l10n.beforeLabel}: ${_formatSize(state.result!.originalSizeBytes)}',
                              to:
                                  '${l10n.afterLabel}: ${_formatSize(state.result!.compressedSizeBytes)}',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: scheme.onSurfaceVariant,
                              ),
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
                                        files: [
                                          XFile(state.result!.outputPath),
                                        ],
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
                                    onPressed: () => downloadFile(
                                      context,
                                      state.result!.outputPath,
                                    ),
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
