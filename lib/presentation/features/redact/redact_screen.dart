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
                            child: ClipRect(
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
                                    key: ValueKey(state.currentPageIndex),
                                    width: fitWidth,
                                    state: state,
                                    onCommitSelection:
                                        controller.commitSelection,
                                    onRemoveSelection:
                                        controller.removeSelection,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _NextColorSwatch(color: state.nextColor),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _ColorSpectrumBar(
                                      value: state.nextColor,
                                      onChanged: controller.setNextColor,
                                    ),
                                  ),
                                ],
                              ),
                              _OpacitySlider(
                                opacity: state.barOpacity,
                                onChanged: controller.setBarOpacity,
                              ),
                            ],
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

/// Opacity control - shared by every selection's bar (see
/// [PdfRedactArea]'s doc comment on why a non-1.0 value here is just a
/// look, not a privacy, choice).
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

/// A swatch previewing which color the *next* selection will get (see
/// [RedactState.nextColor]) - otherwise there's no way to know in advance
/// what shade a new tap/drag is about to become.
class _NextColorSwatch extends StatelessWidget {
  final Color color;

  const _NextColorSwatch({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
    );
  }
}

/// A horizontal hue-spectrum bar - drag (or tap) along it to set
/// [RedactState.nextColor]'s hue directly, live-updating the swatch next
/// to it so it's clear what color is under your finger while you drag,
/// instead of only finding out after marking something.
class _ColorSpectrumBar extends StatelessWidget {
  final Color value;
  final ValueChanged<Color> onChanged;

  const _ColorSpectrumBar({required this.value, required this.onChanged});

  static const List<Color> _hueStops = [
    Color(0xFFFF0000),
    Color(0xFFFFFF00),
    Color(0xFF00FF00),
    Color(0xFF00FFFF),
    Color(0xFF0000FF),
    Color(0xFFFF00FF),
    Color(0xFFFF0000),
  ];

  void _updateFromLocalX(double localX, double barWidth) {
    final double hue = (localX / barWidth).clamp(0.0, 1.0) * 360.0;
    final HSVColor hsv = HSVColor.fromColor(value);
    onChanged(hsv.withHue(hue == 360 ? 0 : hue).toColor());
  }

  static const double _trackHeight = 10;
  static const double _thumbSize = 28;

  @override
  Widget build(BuildContext context) {
    final double hue = HSVColor.fromColor(value).hue;
    return LayoutBuilder(
      builder: (context, constraints) {
        final double barWidth = constraints.maxWidth;
        final double thumbLeft = (hue / 360 * barWidth - _thumbSize / 2)
            .clamp(0.0, barWidth - _thumbSize);
        return GestureDetector(
          onPanDown: (d) => _updateFromLocalX(d.localPosition.dx, barWidth),
          onPanUpdate: (d) => _updateFromLocalX(d.localPosition.dx, barWidth),
          child: SizedBox(
            width: barWidth,
            height: _thumbSize,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: _trackHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(_trackHeight / 2),
                    gradient: const LinearGradient(colors: _hueStops),
                  ),
                ),
                // A white disc with a ring in the *currently selected*
                // color (not just the hue at this thumb position - same
                // thing while dragging, but this also reflects saturation/
                // value if those ever become adjustable later) - the
                // usual look for this kind of hue-slider handle.
                Positioned(
                  left: thumbLeft,
                  child: Container(
                    width: _thumbSize,
                    height: _thumbSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: value, width: 3),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Renders the current page at its natural aspect ratio. A single
/// `onScale*` gesture handles three things at once, branching on
/// `details.pointerCount`:
/// - **Two+ fingers**: pinch-zoom/pan the page (a hand-rolled equivalent of
///   `InteractiveViewer` - that widget's own `ScaleGestureRecognizer` wins
///   the gesture arena for *any* pointer movement, single-finger included,
///   so it can't sit alongside the single-finger drag below; using one
///   `onScale*` recognizer for both, differentiated by pointer count, is
///   the way to get real pinch-zoom back without that conflict).
/// - **One finger starting on empty space or an unmarked word**: drag-select
///   - hit-tests every word box the pointer passes over, committing the
///   touched set as one new selection on release.
/// - **One finger starting on an already-marked word**: removes that whole
///   selection on release, ignoring any further movement - a plain way to
///   undo a mistaken mark without a separate delete button.
class _PageCanvas extends StatefulWidget {
  final double width;
  final RedactState state;
  final void Function(Set<int> wordIndices) onCommitSelection;
  final void Function(RedactSelection selection) onRemoveSelection;

  const _PageCanvas({
    super.key,
    required this.width,
    required this.state,
    required this.onCommitSelection,
    required this.onRemoveSelection,
  });

  @override
  State<_PageCanvas> createState() => _PageCanvasState();
}

class _PageCanvasState extends State<_PageCanvas> {
  Set<int> _dragIndices = {};
  RedactSelection? _removingSelection;

  double _scale = 1.0;
  Offset _panOffset = Offset.zero;
  double _scaleStart = 1.0;
  Offset _panOffsetStart = Offset.zero;
  Offset _focalStart = Offset.zero;
  bool _isZooming = false;

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

  /// Merges a set of word indices into one bounding [Rect] per line they
  /// touch on the current page - the same per-line grouping
  /// [RedactController.redact] uses to build the actual redact areas, done
  /// here purely for display so a multi-word selection reads as one solid
  /// bar instead of visibly-seamed boxes per word.
  List<Rect> _mergedRects(
    Iterable<int> indices,
    List<({int index, PdfTextWord word, Rect displayRect})> words,
  ) {
    final Map<int, Rect> byLine = {};
    for (final int i in indices) {
      final entry = words.where((w) => w.index == i);
      if (entry.isEmpty) continue;
      final Rect r = entry.first.displayRect;
      final int lineIndex = entry.first.word.lineIndex;
      byLine[lineIndex] = byLine.containsKey(lineIndex)
          ? byLine[lineIndex]!.expandToInclude(r)
          : r;
    }
    return byLine.values.toList();
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

  /// Whether [position] lands inside an *already-marked* selection - checked
  /// against the same merged (per-line, gap-bridging) rects the bar is
  /// actually painted with, not the individual per-word rects [_hitTest]
  /// uses. A merged bar visually reads as one solid rectangle, including the
  /// small gaps between adjacent words it spans; hit-testing only the raw
  /// word boxes would miss a tap that lands in one of those gaps, making
  /// "start a drag on a mark to remove it" fail exactly where it visually
  /// looks like it should work.
  RedactSelection? _hitTestSelection(
    List<({int index, PdfTextWord word, Rect displayRect})> words,
    Offset position,
  ) {
    for (final RedactSelection selection in widget.state.selections) {
      for (final Rect r in _mergedRects(selection.wordIndices, words)) {
        if (r.contains(position)) return selection;
      }
    }
    return null;
  }

  void _onScaleStart(
    List<({int index, PdfTextWord word, Rect displayRect})> words,
    ScaleStartDetails details,
  ) {
    if (details.pointerCount > 1) {
      _isZooming = true;
      _scaleStart = _scale;
      _panOffsetStart = _panOffset;
      // details.focalPoint (unlike localFocalPoint) is in *global* screen
      // coordinates, unaffected by the Transform this gesture itself
      // drives - avoids a feedback loop between reading the focal point
      // and the transform changing because of it.
      _focalStart = details.focalPoint;
      return;
    }
    _isZooming = false;
    final RedactSelection? existing = _hitTestSelection(
      words,
      details.localFocalPoint,
    );
    final int? hit = existing == null
        ? _hitTest(words, details.localFocalPoint)
        : null;
    setState(() {
      if (existing != null) {
        _removingSelection = existing;
        _dragIndices = {};
      } else {
        _removingSelection = null;
        _dragIndices = hit == null ? {} : {hit};
      }
    });
  }

  void _onScaleUpdate(
    List<({int index, PdfTextWord word, Rect displayRect})> words,
    ScaleUpdateDetails details,
  ) {
    if (details.pointerCount > 1 || _isZooming) {
      setState(() {
        _isZooming = true;
        _scale = (_scaleStart * details.scale).clamp(1.0, 4.0);
        _panOffset = _panOffsetStart + (details.focalPoint - _focalStart);
      });
      return;
    }
    if (_removingSelection != null) return; // fixed target, ignore movement
    final int? hit = _hitTest(words, details.localFocalPoint);
    if (hit != null && !_dragIndices.contains(hit)) {
      setState(() => _dragIndices = {..._dragIndices, hit});
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    if (_isZooming) {
      _isZooming = false;
      return;
    }
    if (_removingSelection != null) {
      widget.onRemoveSelection(_removingSelection!);
      setState(() => _removingSelection = null);
      return;
    }
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
    final Color previewColor = widget.state.nextColor;

    return Transform(
      transform: Matrix4.identity()
        ..translateByDouble(_panOffset.dx, _panOffset.dy, 0, 1)
        ..scaleByDouble(_scale, _scale, 1, 1),
      child: GestureDetector(
        onScaleStart: (details) => _onScaleStart(words, details),
        onScaleUpdate: (details) => _onScaleUpdate(words, details),
        onScaleEnd: _onScaleEnd,
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
              // Committed selections - one merged bar per line each
              // touches, colored per selection.
              for (final RedactSelection selection in widget.state.selections)
                for (final Rect r in _mergedRects(
                  selection.wordIndices,
                  words,
                ))
                  Positioned.fromRect(
                    rect: r,
                    child: _RedactBar(
                      color: selection.color,
                      opacity: widget.state.barOpacity,
                      isSelectedForRemoval:
                          identical(selection, _removingSelection),
                    ),
                  ),
              // In-progress drag preview, before it's committed.
              if (_dragIndices.isNotEmpty)
                for (final Rect r in _mergedRects(_dragIndices, words))
                  Positioned.fromRect(
                    rect: r,
                    child: _RedactBar(
                      color: previewColor,
                      opacity: 0.4,
                      isSelectedForRemoval: false,
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RedactBar extends StatelessWidget {
  final Color color;
  final double opacity;
  final bool isSelectedForRemoval;

  const _RedactBar({
    required this.color,
    required this.opacity,
    required this.isSelectedForRemoval,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      // Hit-testing happens at the canvas level (see _PageCanvasState) -
      // this box is purely visual.
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: opacity),
          border: isSelectedForRemoval
              ? Border.all(color: Colors.white, width: 2)
              : null,
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
