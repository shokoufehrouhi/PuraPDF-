import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/feature_colors.dart';
import '../../../domain/entities/pdf_file.dart';
import '../../shared_widgets/download_file.dart';
import '../../shared_widgets/feature_screen_header.dart';
import '../../shared_widgets/picker_card.dart';
import '../../shared_widgets/start_over_button.dart';
import 'split_controller.dart';

const Color _color = FeatureColors.splitIcon;

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
                icon: Icons.call_split,
                color: _color,
                title: 'Split PDF',
                description:
                    'Break a PDF into separate files — by page or by '
                    'custom ranges.',
                steps: ['Select PDF', 'Choose pages', 'Split', 'Save'],
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
                          : state.pageCount != null
                          ? '${state.pageCount} pages — tap to change file'
                          : 'Tap to change file',
                      onTap: () => _pickFile(ref),
                    ),
                    if (state.sourceFile != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: SwitchListTile(
                          title: const Text('Split into one file per page'),
                          value: state.everyPage,
                          activeThumbColor: _color,
                          onChanged: controller.setEveryPage,
                        ),
                      ),
                      if (!state.everyPage) ...[
                        const SizedBox(height: 12),
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'Page ranges',
                            hintText: 'e.g. 1-3, 5, 7-9',
                          ),
                          onChanged: controller.setRangesInput,
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (state.resultPaths.isNotEmpty)
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
                          icon: state.isSplitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.call_split),
                          label: const Text('Split'),
                          onPressed: state.isSplitting
                              ? null
                              : controller.split,
                        ),
                    ],
                    if (state.error != null) ...[
                      const SizedBox(height: 12),
                      Text(state.error!, style: TextStyle(color: scheme.error)),
                    ],
                    if (state.resultPaths.isNotEmpty) ...[
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
                                    '${state.resultPaths.length} file(s) '
                                    'created',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...state.resultPaths.map(
                              (p) => Card(
                                margin: const EdgeInsets.only(top: 4),
                                child: ListTile(
                                  leading: const Icon(Icons.picture_as_pdf),
                                  title: Text(
                                    p.split('/').last,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: _color,
                                      side: BorderSide(
                                        color: _color.withValues(alpha: 0.5),
                                      ),
                                    ),
                                    icon: const Icon(Icons.folder_zip),
                                    label: const Text('Share ZIP'),
                                    onPressed: () async {
                                      final zipPath = await controller
                                          .zipResults();
                                      if (context.mounted) {
                                        await SharePlus.instance.share(
                                          ShareParams(files: [XFile(zipPath)]),
                                        );
                                      }
                                    },
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
                                    label: const Text('Download ZIP'),
                                    onPressed: () async {
                                      final zipPath = await controller
                                          .zipResults();
                                      if (context.mounted) {
                                        await downloadFile(context, zipPath);
                                      }
                                    },
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
