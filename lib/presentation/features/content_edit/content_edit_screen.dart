import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/error_message.dart';
import '../../../core/theme/feature_colors.dart';
import '../../../domain/entities/pdf_file.dart';
import '../../../domain/entities/pdf_text_line.dart';
import '../../../l10n/app_localizations.dart';
import '../../shared_widgets/download_file.dart';
import '../../shared_widgets/feature_screen_header.dart';
import '../../shared_widgets/picker_card.dart';
import '../../shared_widgets/picking_overlay.dart';
import '../../shared_widgets/start_over_button.dart';
import 'content_edit_controller.dart';

const Color _color = FeatureColors.contentEditIcon;

class ContentEditScreen extends ConsumerWidget {
  const ContentEditScreen({super.key});

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
    await ref.read(contentEditControllerProvider.notifier).setSourceFile(file);
  }

  Future<void> _pickImage(BuildContext context, WidgetRef ref) async {
    final List<PlatformFile> picked = await withPickingOverlay(
      context,
      () => FilePicker.pickFiles(type: FileType.image),
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
    final l10n = AppLocalizations.of(context);
    final String? action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editLine),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: null,
          decoration: InputDecoration(hintText: l10n.lineText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('delete'),
            child: Text(l10n.delete, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _color),
            onPressed: () => Navigator.of(context).pop('save'),
            child: Text(l10n.save),
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
    final l10n = AppLocalizations.of(context);

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
            FeatureScreenHeader(
              icon: Icons.text_fields,
              color: _color,
              title: l10n.contentEditTitle,
              description: l10n.contentEditDescription,
              steps: [
                l10n.contentEditStepSelect,
                l10n.contentEditStepEdit,
                l10n.addImage,
                l10n.contentEditStepSave,
              ],
            ),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  localizedError(context, state.error!),
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
                          label: l10n.selectAPdf,
                          hint: l10n.tapToBrowseFiles,
                          onTap: () => _pickFile(context, ref),
                        ),
                      ),
                    )
                  : state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.pages.isEmpty
                  ? Center(child: Text(l10n.thisPdfHasNoPages))
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                tooltip: l10n.previousPage,
                                onPressed: state.currentPageIndex > 0
                                    ? () => controller.setPage(
                                        state.currentPageIndex - 1,
                                      )
                                    : null,
                              ),
                              Expanded(
                                child: Text(
                                  l10n.pageOfTotal(
                                    state.currentPageIndex + 1,
                                    state.pages.length,
                                  ),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                tooltip: l10n.nextPage,
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
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                            ),
                            // Pages can pack a lot of small text - pinch (or
                            // trackpad/ctrl-scroll) to zoom in and clearly
                            // see which line you're about to tap.
                            //
                            // InteractiveViewer's own GestureDetector is
                            // HitTestBehavior.opaque with a ScaleGestureRecognizer
                            // that wins the gesture arena for *any* pointer
                            // movement under it, single-finger included -
                            // confirmed with a widget test, plain taps still
                            // reach a nested GestureDetector fine (taps need
                            // no movement to resolve), but a nested
                            // onPanUpdate drag never fires at all, even with
                            // panEnabled:false (that only makes
                            // InteractiveViewer's own reaction to the
                            // gesture a no-op - it still wins the arena and
                            // starves the child). That would silently break
                            // dragging a pending image into place, so zoom
                            // only replaces the plain view while there's
                            // nothing to drag; with a pending image, fall
                            // back to the old scrollable (non-zoomable)
                            // rendering so that drag keeps working.
                            child: state.pendingImages.isEmpty
                                ? LayoutBuilder(
                                    builder: (context, constraints) {
                                      final page =
                                          state.pages[state.currentPageIndex];
                                      double fitWidth = constraints.maxWidth;
                                      double fitHeight =
                                          fitWidth *
                                          page.pointsHeight /
                                          page.pointsWidth;
                                      if (fitHeight > constraints.maxHeight) {
                                        fitHeight = constraints.maxHeight;
                                        fitWidth =
                                            fitHeight *
                                            page.pointsWidth /
                                            page.pointsHeight;
                                      }
                                      // constrained:false: InteractiveViewer's
                                      // own constrained:true auto-fit measures
                                      // the child against loose/unbounded
                                      // constraints, which left _PageCanvas's
                                      // width math seeing bogus constraints
                                      // and every overlay landing off the
                                      // page. Doing the fit-to-viewport math
                                      // by hand (BoxFit.contain-style)
                                      // against this Padding's real bounded
                                      // size sidesteps that.
                                      return InteractiveViewer(
                                        constrained: false,
                                        minScale: 1.0,
                                        maxScale: 4.0,
                                        child: _PageCanvas(
                                          width: fitWidth,
                                          state: state,
                                          onTapLine: (lineIndex, text) =>
                                              _editLine(
                                                context,
                                                ref,
                                                lineIndex,
                                                text,
                                              ),
                                          onMoveImage: controller.moveImage,
                                          onRemoveImage:
                                              controller.removeImage,
                                        ),
                                      );
                                    },
                                  )
                                : SingleChildScrollView(
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        return _PageCanvas(
                                          width: constraints.maxWidth,
                                          state: state,
                                          onTapLine: (lineIndex, text) =>
                                              _editLine(
                                                context,
                                                ref,
                                                lineIndex,
                                                text,
                                              ),
                                          onMoveImage: controller.moveImage,
                                          onRemoveImage:
                                              controller.removeImage,
                                        );
                                      },
                                    ),
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
                            label: Text(l10n.addImageToPage),
                            onPressed: () => _pickImage(context, ref),
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
                                  ? l10n.contentEditStepSave
                                  : l10n.errorMakeAChangeBeforeSaving,
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
  final double width;
  final ContentEditState state;
  final void Function(int lineIndex, String text) onTapLine;
  final void Function(int pendingIndex, double leftFrac, double topFrac)
  onMoveImage;
  final void Function(int pendingIndex) onRemoveImage;

  const _PageCanvas({
    required this.width,
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

    final double dispWidth = width;
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
    final l10n = AppLocalizations.of(context);
    return Container(
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
                  l10n.pdfSavedSuccess,
                  style: const TextStyle(fontWeight: FontWeight.w700),
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
                  label: Text(l10n.download),
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
