import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/error_message.dart';
import '../../../core/theme/feature_colors.dart';
import '../../../domain/entities/pdf_file.dart';
import '../../../domain/entities/pdf_text_word.dart';
import '../../../l10n/app_localizations.dart';
import '../../shared_widgets/download_file.dart';
import '../../shared_widgets/feature_screen_header.dart';
import '../../shared_widgets/picker_card.dart';
import '../../shared_widgets/picking_overlay.dart';
import '../../shared_widgets/start_over_button.dart';
import 'redact_controller.dart';

const Color _color = FeatureColors.redactIcon;

class RedactScreen extends ConsumerWidget {
  const RedactScreen({super.key});

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
    await ref.read(redactControllerProvider.notifier).setSourceFile(file);
  }

  Future<void> _confirmAndRedact(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.redactConfirmTitle),
        content: Text(l10n.redactConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _color),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.redactConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(redactControllerProvider.notifier).redact();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(redactControllerProvider);
    final controller = ref.read(redactControllerProvider.notifier);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final int selectedWordCount = [
      for (final s in state.selections) ...s.wordIndices,
    ].length;

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
              icon: Icons.visibility_off_outlined,
              color: _color,
              title: l10n.featureRedactTitle,
              description: l10n.redactDescription,
              steps: [
                l10n.redactStepSelect,
                l10n.redactStepMark,
                l10n.redactStepConfirm,
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
                            // Word selection needs a real drag gesture (a
                            // range is "press on one word, drag across
                            // more"), which conflicts with
                            // InteractiveViewer's own ScaleGestureRecognizer
                            // the same way Edit PDF's image-drag does - so
                            // this screen never turns pinch-zoom on at all,
                            // rather than only conditionally like Edit PDF.
                            child: SingleChildScrollView(
                              child: LayoutBuilder(
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
                                  return _PageCanvas(
                                    width: fitWidth,
                                    state: state,
                                    onCommitSelection:
                                        controller.commitSelection,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                          child: _OpacitySlider(
                            opacity: state.barOpacity,
                            onChanged: controller.setBarOpacity,
                          ),
                        ),
                        if (selectedWordCount > 0)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                            child: Text(
                              l10n.redactMarkedCount(selectedWordCount),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _color,
                              ),
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
                                : const Icon(Icons.visibility_off_outlined),
                            label: Text(
                              selectedWordCount == 0
                                  ? l10n.errorMarkAtLeastOneLineToRedact
                                  : l10n.redactButtonLabel(selectedWordCount),
                            ),
                            onPressed: state.isSaving || selectedWordCount == 0
                                ? null
                                : () => _confirmAndRedact(context, ref),
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

/// Just the opacity control now - color is auto-assigned per selection
/// (see [redactPalette]), no manual picker in this pass.
class _OpacitySlider extends StatelessWidget {
  final double opacity;
  final ValueChanged<double> onChanged;

  const _OpacitySlider({required this.opacity, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.opacity, size: 18, color: scheme.onSurfaceVariant),
        Expanded(
          child: Slider(
            value: opacity,
            min: 0.3,
            max: 1.0,
            activeColor: _color,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

/// Renders the current page at its natural aspect ratio, with a box over
/// each extracted word. A single canvas-level pan gesture handles both a
/// plain tap (press+release without moving off the starting word) and a
/// drag across a range - hit-testing which word boxes the pointer has
/// passed over as it moves, committing the touched set as one selection
/// on release. No per-word `GestureDetector` needed.
class _PageCanvas extends StatefulWidget {
  final double width;
  final RedactState state;
  final void Function(Set<int> wordIndices) onCommitSelection;

  const _PageCanvas({
    required this.width,
    required this.state,
    required this.onCommitSelection,
  });

  @override
  State<_PageCanvas> createState() => _PageCanvasState();
}

class _PageCanvasState extends State<_PageCanvas> {
  Set<int> _dragIndices = {};

  List<({int index, PdfTextWord word, Rect displayRect})> _wordsOnPage(
    double dispWidth,
    double dispHeight,
  ) {
    final page = widget.state.pages[widget.state.currentPageIndex];
    return [
      for (int i = 0; i < widget.state.words.length; i++)
        if (widget.state.words[i].pageIndex == widget.state.currentPageIndex)
          (
            index: i,
            word: widget.state.words[i],
            displayRect: Rect.fromLTWH(
              widget.state.words[i].left / page.pointsWidth * dispWidth,
              widget.state.words[i].top / page.pointsHeight * dispHeight,
              widget.state.words[i].width / page.pointsWidth * dispWidth,
              widget.state.words[i].height / page.pointsHeight * dispHeight,
            ),
          ),
    ];
  }

  int? _hitTest(
    List<({int index, PdfTextWord word, Rect displayRect})> words,
    Offset position,
  ) {
    for (final entry in words) {
      if (entry.displayRect.contains(position)) return entry.index;
    }
    return null;
  }

  void _onPanDown(
    List<({int index, PdfTextWord word, Rect displayRect})> words,
    DragDownDetails details,
  ) {
    final int? hit = _hitTest(words, details.localPosition);
    setState(() => _dragIndices = hit == null ? {} : {hit});
  }

  void _onPanUpdate(
    List<({int index, PdfTextWord word, Rect displayRect})> words,
    DragUpdateDetails details,
  ) {
    final int? hit = _hitTest(words, details.localPosition);
    if (hit != null && !_dragIndices.contains(hit)) {
      setState(() => _dragIndices = {..._dragIndices, hit});
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_dragIndices.isNotEmpty) {
      widget.onCommitSelection(_dragIndices);
    }
    setState(() => _dragIndices = {});
  }

  @override
  Widget build(BuildContext context) {
    final page = widget.state.pages[widget.state.currentPageIndex];
    final double dispWidth = widget.width;
    final double dispHeight =
        dispWidth * page.pointsHeight / page.pointsWidth;
    final words = _wordsOnPage(dispWidth, dispHeight);
    final Color previewColor =
        redactPalette[widget.state.nextColorIndex % redactPalette.length];

    return GestureDetector(
      onPanDown: (details) => _onPanDown(words, details),
      onPanUpdate: (details) => _onPanUpdate(words, details),
      onPanEnd: _onPanEnd,
      child: SizedBox(
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
            for (final entry in words)
              Positioned.fromRect(
                rect: entry.displayRect,
                child: _WordOverlay(
                  committedColor: widget.state.selectionOf(
                    entry.index,
                  )?.color,
                  pending: _dragIndices.contains(entry.index),
                  previewColor: previewColor,
                  barOpacity: widget.state.barOpacity,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WordOverlay extends StatelessWidget {
  /// Non-null once this word belongs to a committed selection - its color.
  final Color? committedColor;
  /// True while a drag-in-progress has touched this word but not released
  /// yet (see [previewColor]).
  final bool pending;
  final Color previewColor;
  final double barOpacity;

  const _WordOverlay({
    required this.committedColor,
    required this.pending,
    required this.previewColor,
    required this.barOpacity,
  });

  @override
  Widget build(BuildContext context) {
    final Color? fill = committedColor != null
        ? committedColor!.withValues(alpha: barOpacity)
        : pending
        ? previewColor.withValues(alpha: 0.4)
        : null;
    final bool marked = committedColor != null || pending;
    return IgnorePointer(
      // Hit-testing happens at the canvas level (see _PageCanvasState) -
      // these boxes are purely visual.
      child: Container(
        decoration: BoxDecoration(
          color: fill ?? _color.withValues(alpha: 0.0),
          border: Border.all(
            color: _color.withValues(alpha: marked ? 0.9 : 0.22),
            width: marked ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(3),
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
