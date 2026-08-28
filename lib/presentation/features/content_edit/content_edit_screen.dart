import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/feature_colors.dart';
import '../../../domain/entities/pdf_file.dart';
import '../../../domain/entities/pdf_text_line.dart';
import '../../shared_widgets/download_file.dart';
import '../../shared_widgets/feature_screen_header.dart';
import '../../shared_widgets/picker_card.dart';
import '../../shared_widgets/start_over_button.dart';
import 'content_edit_controller.dart';

const Color _color = FeatureColors.contentEditIcon;

class ContentEditScreen extends ConsumerWidget {
  const ContentEditScreen({super.key});

  Future<void> _pickFile(WidgetRef ref) async {
    final List<PlatformFile> picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (picked.isEmpty || picked.first.path == null) return;
    final file = PdfFile(path: picked.first.path!, name: picked.first.name);
    await ref.read(contentEditControllerProvider.notifier).setSourceFile(file);
  }

  Future<void> _pickImage(WidgetRef ref) async {
    final List<PlatformFile> picked = await FilePicker.pickFiles(
      type: FileType.image,
    );
    if (picked.isEmpty || picked.first.path == null) return;
    final bytes = await File(picked.first.path!).readAsBytes();
    ref.read(contentEditControllerProvider.notifier).addImage(bytes);
  }

  Future<void> _editLine(
    BuildContext context,
    WidgetRef ref,
    int lineIndex,
    String currentText,
  ) async {
    final controller = TextEditingController(text: currentText);
    final String? action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit line'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: null,
          decoration: const InputDecoration(hintText: 'Line text'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('delete'),
            child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _color),
            onPressed: () => Navigator.of(context).pop('save'),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (action == 'delete') {
      ref.read(contentEditControllerProvider.notifier).editLine(lineIndex, '');
    } else if (action == 'save') {
      ref
          .read(contentEditControllerProvider.notifier)
          .editLine(lineIndex, controller.text);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(contentEditControllerProvider);
    final controller = ref.read(contentEditControllerProvider.notifier);
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
              icon: Icons.text_fields,
              color: _color,
              title: 'Edit PDF',
              description:
                  'Tap a line to fix or remove it, or drop in an image — '
                  'edits cover the original spot rather than reflowing '
                  'the page.',
              steps: ['Select PDF', 'Tap to edit', 'Add image', 'Save'],
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
                  : state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.pages.isEmpty
                  ? const Center(child: Text('This PDF has no pages.'))
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed: state.currentPageIndex > 0
                                    ? () => controller.setPage(
                                        state.currentPageIndex - 1,
                                      )
                                    : null,
                              ),
                              Expanded(
                                child: Text(
                                  'Page ${state.currentPageIndex + 1} of '
                                  '${state.pages.length}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed:
                                    state.currentPageIndex <
                                        state.pages.length - 1
                                    ? () => controller.setPage(
                                        state.currentPageIndex + 1,
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                            ),
                            child: _PageCanvas(
                              state: state,
                              onTapLine: (lineIndex, text) =>
                                  _editLine(context, ref, lineIndex, text),
                              onMoveImage: controller.moveImage,
                              onRemoveImage: controller.removeImage,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _color,
                              side: BorderSide(
                                color: _color.withValues(alpha: 0.5),
                              ),
                            ),
                            icon: const Icon(Icons.add_photo_alternate_outlined),
                            label: const Text('Add image to this page'),
                            onPressed: () => _pickImage(ref),
                          ),
                        ),
                      ],
                    ),
            ),
            if (state.resultPath != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: _ResultCard(path: state.resultPath!),
              ),
            if (state.sourceFile != null &&
                !state.isLoading &&
                state.pages.isNotEmpty)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
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
                              state.hasEdits
                                  ? 'Save changes'
                                  : 'Make a change to save',
                            ),
                            onPressed: state.isSaving || !state.hasEdits
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

/// Renders the current page at its natural aspect ratio, with a tappable
/// box over each extracted text line and a draggable box for each pending
/// image insert — all positioned as fractions of the page so this doesn't
/// need to know the underlying render resolution.
class _PageCanvas extends StatelessWidget {
  final ContentEditState state;
  final void Function(int lineIndex, String text) onTapLine;
  final void Function(int pendingIndex, double leftFrac, double topFrac)
  onMoveImage;
  final void Function(int pendingIndex) onRemoveImage;

  const _PageCanvas({
    required this.state,
    required this.onTapLine,
    required this.onMoveImage,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    final page = state.pages[state.currentPageIndex];
    final List<({int index, PdfTextLine line})> lines = [
      for (int i = 0; i < state.textLines.length; i++)
        if (state.textLines[i].pageIndex == state.currentPageIndex)
          (index: i, line: state.textLines[i]),
    ];
    final List<({int index, PendingImage image})> images = [
      for (int i = 0; i < state.pendingImages.length; i++)
        if (state.pendingImages[i].pageIndex == state.currentPageIndex)
          (index: i, image: state.pendingImages[i]),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final double dispWidth = constraints.maxWidth;
        final double dispHeight =
            dispWidth * page.pointsHeight / page.pointsWidth;

        return SizedBox(
          width: dispWidth,
          height: dispHeight,
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(page.bytes, fit: BoxFit.fill),
                ),
              ),
              for (final entry in lines)
                Positioned(
                  left: entry.line.left / page.pointsWidth * dispWidth,
                  top: entry.line.top / page.pointsHeight * dispHeight,
                  width: entry.line.width / page.pointsWidth * dispWidth,
                  height: entry.line.height / page.pointsHeight * dispHeight,
                  child: _LineOverlay(
                    edited: state.textEdits.containsKey(entry.index),
                    onTap: () => onTapLine(
                      entry.index,
                      state.textEdits[entry.index] ?? entry.line.text,
                    ),
                  ),
                ),
              for (final entry in images)
                Positioned(
                  left: entry.image.leftFrac * dispWidth,
                  top: entry.image.topFrac * dispHeight,
                  width: entry.image.widthFrac * dispWidth,
                  height: entry.image.heightFrac * dispHeight,
                  child: _PendingImageOverlay(
                    image: entry.image,
                    onDrag: (delta) => onMoveImage(
                      entry.index,
                      entry.image.leftFrac + delta.dx / dispWidth,
                      entry.image.topFrac + delta.dy / dispHeight,
                    ),
                    onRemove: () => onRemoveImage(entry.index),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _LineOverlay extends StatelessWidget {
  final bool edited;
  final VoidCallback onTap;

  const _LineOverlay({required this.edited, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _color.withValues(alpha: edited ? 0.22 : 0.0),
          border: Border.all(
            color: _color.withValues(alpha: edited ? 0.9 : 0.28),
            width: edited ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

class _PendingImageOverlay extends StatelessWidget {
  final PendingImage image;
  final void Function(Offset delta) onDrag;
  final VoidCallback onRemove;

  const _PendingImageOverlay({
    required this.image,
    required this.onDrag,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) => onDrag(details.delta),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: _color, width: 1.5),
              ),
              child: Image.memory(image.bytes, fit: BoxFit.fill),
            ),
          ),
          Positioned(
            right: -10,
            top: -10,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Colors.black87,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
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
