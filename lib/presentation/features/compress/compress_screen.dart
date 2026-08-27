import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../domain/entities/compression_level.dart';
import '../../../domain/entities/pdf_file.dart';
import '../../shared_widgets/download_file.dart';
import 'compress_controller.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Compress PDF')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: Text(state.sourceFile?.name ?? 'Select a PDF'),
              onPressed: () => _pickFile(ref),
            ),
            if (state.originalSizeBytes != null) ...[
              const SizedBox(height: 8),
              Text('Original size: ${_formatSize(state.originalSizeBytes!)}'),
            ],
            if (state.sourceFile != null) ...[
              const SizedBox(height: 16),
              SegmentedButton<CompressionLevel>(
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
                  'selectable/searchable text. On text-heavy PDFs where '
                  'that would backfire, it automatically falls back so '
                  'the result is never bigger than the original.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: state.isCompressing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.compress),
                label: const Text('Compress'),
                onPressed: state.isCompressing ? null : controller.compress,
              ),
            ],
            if (state.error != null) ...[
              const SizedBox(height: 12),
              Text(
                state.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (state.result != null) ...[
              const SizedBox(height: 20),
              Text(
                'Before: ${_formatSize(state.result!.originalSizeBytes)}  →  '
                'After: ${_formatSize(state.result!.compressedSizeBytes)}',
              ),
              const SizedBox(height: 4),
              Text(
                '${state.result!.reductionPercent.toStringAsFixed(1)}% smaller',
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                    onPressed: () => SharePlus.instance.share(
                      ShareParams(files: [XFile(state.result!.outputPath)]),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text('Download'),
                    onPressed: () =>
                        downloadFile(context, state.result!.outputPath),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
