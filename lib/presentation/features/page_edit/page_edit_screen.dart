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
import 'page_edit_controller.dart';

const Color _color = FeatureColors.pageEditIcon;

class PageEditScreen extends ConsumerWidget {
  const PageEditScreen({super.key});

  Future<void> _pickFile(WidgetRef ref) async {
    final List<PlatformFile> picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (picked.isEmpty || picked.first.path == null) return;
    final file = PdfFile(path: picked.first.path!, name: picked.first.name);
    await ref.read(pageEditControllerProvider.notifier).setSourceFile(file);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pageEditControllerProvider);
    final controller = ref.read(pageEditControllerProvider.notifier);
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const FeatureScreenHeader(
              icon: Icons.crop_rotate,
              color: _color,
              title: 'Edit Pages',
              description:
                  'Rotate, reorder, or remove pages from a PDF — the rest '
                  'of the document stays untouched.',
              steps: ['Select PDF', 'Edit pages', 'Save', 'Download'],
            ),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  state.error!,
                  style: TextStyle(color: scheme.error),
                ),
              ),
            Expanded(
              child: state.sourceFile == null
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: PickerCard(
                          icon: Icons.upload_file,
                          color: _color,
                          label: 'Select a PDF',
                          hint: 'Tap to browse your files',
                          onTap: () => _pickFile(ref),
                        ),
                      ),
                    )
                  : state.isLoadingPages
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${state.pages.length} page'
                                  '${state.pages.length == 1 ? '' : 's'} '
                                  '— drag to reorder',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => _pickFile(ref),
                                icon: const Icon(
                                  Icons.swap_horiz,
                                  size: 18,
                                ),
                                label: const Text('Change file'),
                                style: TextButton.styleFrom(
                                  foregroundColor: _color,
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 0),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ReorderableListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                            ),
                            itemCount: state.pages.length,
                            onReorderItem: controller.reorderItem,
                            itemBuilder: (context, index) {
                              final PageEditItem page = state.pages[index];
                              return Card(
                                // originalIndex alone is already a stable,
                                // unique-per-page id (see PageEditItem) -
                                // mixing in the list index too would make
                                // Flutter treat every dragged item as a
                                // brand new widget and break the reorder
                                // animation.
                                key: ValueKey(page.originalIndex),
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          8,
                                        ),
                                        child: RotatedBox(
                                          quarterTurns: page.rotation ~/ 90,
                                          child: Image.memory(
                                            page.thumbnail,
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        left: 0,
                                        top: 0,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _color,
                                            borderRadius:
                                                const BorderRadius.only(
                                                  topLeft: Radius.circular(8),
                                                  bottomRight:
                                                      Radius.circular(8),
                                                ),
                                          ),
                                          child: Text(
                                            '${index + 1}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  title: Text('Page ${index + 1}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.rotate_right),
                                        tooltip: 'Rotate',
                                        onPressed: () =>
                                            controller.rotateAt(index),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close),
                                        tooltip: 'Remove page',
                                        onPressed: () =>
                                            controller.removeAt(index),
                                      ),
                                      const Icon(Icons.drag_handle),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
            if (state.resultPath != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: _ResultCard(path: state.resultPath!),
              ),
            if (state.sourceFile != null && !state.isLoadingPages)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: state.resultPath != null
                      ? StartOverButton(
                          color: _color,
                          onPressed: controller.reset,
                        )
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _color,
                              foregroundColor: Colors.white,
                            ),
                            icon: state.isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: Text(
                              state.pages.isEmpty
                                  ? 'At least one page must remain'
                                  : 'Save changes',
                            ),
                            onPressed: state.isSaving || state.pages.isEmpty
                                ? null
                                : controller.save,
                          ),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String path;

  const _ResultCard({required this.path});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle, color: _color),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'PDF saved successfully',
                  style: TextStyle(fontWeight: FontWeight.w700),
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
                  label: const Text('Share'),
                  onPressed: () => SharePlus.instance.share(
                    ShareParams(files: [XFile(path)]),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _color,
                    side: BorderSide(color: _color.withValues(alpha: 0.5)),
                  ),
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Download'),
                  onPressed: () => downloadFile(context, path),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
