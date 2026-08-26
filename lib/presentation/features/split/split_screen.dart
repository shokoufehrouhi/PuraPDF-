import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../domain/entities/pdf_file.dart';
import 'split_controller.dart';

class SplitScreen extends ConsumerWidget {
  const SplitScreen({super.key});

  Future<void> _pickFile(WidgetRef ref) async {
    final List<PlatformFile> picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (picked.isEmpty || picked.first.path == null) return;
    final file = PdfFile(path: picked.first.path!, name: picked.first.name);
    await ref.read(splitControllerProvider.notifier).setSourceFile(file);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(splitControllerProvider);
    final controller = ref.read(splitControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Split PDF')),
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
            if (state.pageCount != null) ...[
              const SizedBox(height: 8),
              Text('${state.pageCount} pages'),
            ],
            const SizedBox(height: 16),
            if (state.sourceFile != null) ...[
              SwitchListTile(
                title: const Text('Split into one file per page'),
                value: state.everyPage,
                onChanged: controller.setEveryPage,
              ),
              if (!state.everyPage)
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Page ranges',
                    hintText: 'e.g. 1-3, 5, 7-9',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: controller.setRangesInput,
                ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: state.isSplitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.call_split),
                label: const Text('Split'),
                onPressed: state.isSplitting ? null : controller.split,
              ),
            ],
            if (state.error != null) ...[
              const SizedBox(height: 12),
              Text(state.error!, style: const TextStyle(color: Colors.red)),
            ],
            if (state.resultPaths.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('${state.resultPaths.length} file(s) created ✅'),
              const SizedBox(height: 8),
              ...state.resultPaths.map(
                (p) => ListTile(
                  leading: const Icon(Icons.picture_as_pdf),
                  title: Text(p.split('/').last),
                  trailing: IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () => SharePlus.instance.share(
                      ShareParams(files: [XFile(p)]),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.folder_zip),
                label: const Text('Share all as ZIP'),
                onPressed: () async {
                  final zipPath = await controller.zipResults();
                  if (context.mounted) {
                    await SharePlus.instance.share(
                      ShareParams(files: [XFile(zipPath)]),
                    );
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
