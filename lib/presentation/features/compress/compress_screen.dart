import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/feature_colors.dart';
import '../../../domain/entities/compression_level.dart';
import '../../../domain/entities/pdf_file.dart';
import '../../shared_widgets/download_file.dart';
import '../../shared_widgets/feature_screen_header.dart';
import '../../shared_widgets/picker_card.dart';
import 'compress_controller.dart';

const Color _color = FeatureColors.compressIcon;

class CompressScreen extends ConsumerWidget {
  const CompressScreen({super.key});

  Future<void> _pickFile(WidgetRef ref) async {
    final List<PlatformFile> picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
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
              const FeatureScreenHeader(
                icon: Icons.compress,
                color: _color,
                title: 'Compress PDF',
                description:
                    "Shrink a PDF's file size for easier sharing, with "
                    'three quality levels to choose from.',
                steps: ['Select PDF', 'Pick level', 'Compress', 'Save'],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PickerCard(
                      icon: Icons.upload_file,
                      color: _color,
                      label: state.sourceFile?.name ?? 'Select a PDF',
                      hint: state.sourceFile == null
                          ? 'Tap to browse your files'
                          : state.originalSizeBytes != null
                          ? 'Original size: '
                                '${_formatSize(state.originalSizeBytes!)} — '
                                'tap to change file'
                          : 'Tap to change file',
                      onTap: () => _pickFile(ref),
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
                        segments: const [
                          ButtonSegment(
                            value: CompressionLevel.low,
                            label: Text('Low'),
                          ),
                          ButtonSegment(
                            value: CompressionLevel.medium,
                            label: Text('Medium'),
                          ),
                          ButtonSegment(
                            value: CompressionLevel.high,
                            label: Text('High'),
                          ),
                        ],
                        selected: {state.level},
                        onSelectionChanged: (selection) =>
                            controller.setLevel(selection.first),
                      ),
                      if (state.level == CompressionLevel.high) ...[
                        const SizedBox(height: 8),
                        Text(
                          'High rebuilds every page as an image — best size '
                          'reduction for scans/photos, but the result loses '
                          'selectable/searchable text. On text-heavy PDFs '
                          'where that would backfire, it automatically '
                          'falls back so the result is never bigger than '
                          'the original.',
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
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
                        label: const Text('Compress'),
                        onPressed: state.isCompressing
                            ? null
                            : controller.compress,
                      ),
                    ],
                    if (state.error != null) ...[
                      const SizedBox(height: 12),
                      Text(state.error!, style: TextStyle(color: scheme.error)),
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
                                    '${state.result!.reductionPercent.toStringAsFixed(1)}'
                                    '% smaller',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Before: '
                              '${_formatSize(state.result!.originalSizeBytes)}'
                              '  →  After: '
                              '${_formatSize(state.result!.compressedSizeBytes)}',
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
                                    label: const Text('Share'),
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
                                    label: const Text('Download'),
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
