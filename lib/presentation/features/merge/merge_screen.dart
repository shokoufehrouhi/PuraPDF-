import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../domain/entities/pdf_file.dart';
import '../../shared_widgets/download_file.dart';
import 'merge_controller.dart';

class MergeScreen extends ConsumerWidget {
  const MergeScreen({super.key});

  Future<void> _pickFiles(WidgetRef ref) async {
    final List<PlatformFile> picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    final files = picked
        .where((f) => f.path != null)
        .map((f) => PdfFile(path: f.path!, name: f.name))
        .toList();
    if (files.isNotEmpty) {
      ref.read(mergeControllerProvider.notifier).addFiles(files);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mergeControllerProvider);
    final controller = ref.read(mergeControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Merge PDF')),
      body: Column(
        children: [
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                state.error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Expanded(
            child: state.files.isEmpty
                ? const Center(child: Text('Hich file-i entekhab nashode.'))
                : ReorderableListView.builder(
                    itemCount: state.files.length,
                    onReorderItem: controller.reorderItem,
                    itemBuilder: (context, index) {
                      final f = state.files[index];
                      return ListTile(
                        key: ValueKey('${f.path}_$index'),
                        leading: const Icon(Icons.picture_as_pdf),
                        title: Text(f.name),
                        trailing: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => controller.removeAt(index),
                        ),
                      );
                    },
                  ),
          ),
          if (state.resultPath != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  const Text('Merge movaffagh bood ✅'),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.share),
                        label: const Text('Share'),
                        onPressed: () => SharePlus.instance.share(
                          ShareParams(files: [XFile(state.resultPath!)]),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.download),
                        label: const Text('Download'),
                        onPressed: () =>
                            downloadFile(context, state.resultPath!),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add PDFs'),
                    onPressed: () => _pickFiles(ref),
                  ),
                  ElevatedButton.icon(
                    icon: state.isMerging
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.call_merge),
                    label: const Text('Merge'),
                    onPressed: state.isMerging ? null : controller.merge,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
