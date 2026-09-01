import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

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

  /// Drops a plain checkmark on the page - for forms that draw their own
  /// blank checkbox squares as page content rather than a real AcroForm
  /// field (so there's no widget for Fill & Sign to tick), this is the
  /// quickest way to mark one without leaving the app to find an image.
  Future<void> _addCheckmark(WidgetRef ref) async {
    final Uint8List bytes = await _renderCheckmarkPng();
    final state = ref.read(contentEditControllerProvider);
    final page = state.pages[state.currentPageIndex];
    // A fixed fraction of page width alone would come out non-square on a
    // non-A4-shaped page, since width/height fractions scale against
    // different page dimensions - scale height by the page's own aspect
    // ratio so the mark reads as a small square regardless of page shape.
    // Guards a zero/degenerate pointsHeight (a malformed source PDF) from
    // producing an Infinity/NaN fraction that would carry through to save.
    const double widthFrac = 0.07;
    final double heightFrac = page.pointsHeight > 0
        ? widthFrac * page.pointsWidth / page.pointsHeight
        : widthFrac;
    ref
        .read(contentEditControllerProvider.notifier)
        .addImage(
          bytes,
          leftFrac: 0.5 - widthFrac / 2,
          topFrac: 0.5 - heightFrac / 2,
          widthFrac: widthFrac,
          heightFrac: heightFrac,
          isCheckmark: true,
          // Matches _renderCheckmarkPng's own stroke color (_color) so the
          // saved vector stamp doesn't silently diverge from the on-screen
          // preview - see PendingImage's doc comment.
          checkmarkColorRed: (_color.r * 255).round(),
          checkmarkColorGreen: (_color.g * 255).round(),
          checkmarkColorBlue: (_color.b * 255).round(),
        );
  }

  Future<Uint8List> _renderCheckmarkPng() async {
    const double size = 64;
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(
      recorder,
      const Rect.fromLTWH(0, 0, size, size),
    );
    final Paint paint = Paint()
      ..color = _color
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final Path path = Path()
      ..moveTo(size * 0.16, size * 0.54)
      ..lineTo(size * 0.42, size * 0.80)
      ..lineTo(size * 0.86, size * 0.22);
    canvas.drawPath(path, paint);
    final ui.Image image = await recorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return byteData!.buffer.asUint8List();
  }

  /// Prompts for a line of text, then hands it to [ContentEditController.
  /// startAddText] to await a tap on the page saying where it goes - the
  /// "type something where there was nothing before" counterpart to
  /// [_editLine] (which only ever targets an already-detected line, so it's
  /// useless on an image-only/scanned page).
  Future<void> _addText(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final l10n = AppLocalizations.of(context);
    final String? text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addTextToPage),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: null,
          decoration: InputDecoration(hintText: l10n.lineText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _color),
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (text != null && text.trim().isNotEmpty) {
      ref.read(contentEditControllerProvider.notifier).startAddText(text);
    }
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
            if (state.pendingTextEntry != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.touch_app, color: _color, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.tapPageToPlaceText,
                          style: TextStyle(color: _color),
                        ),
                      ),
                      TextButton(
                        onPressed: controller.cancelAddText,
                        child: Text(l10n.cancel),
                      ),
                    ],
                  ),
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
                            // see which line you're about to tap, drag a
                            // pending image/text box into place, or resize
                            // a text box. See _ZoomablePageCanvas's doc
                            // comment for why zoom and drag can coexist here
                            // despite InteractiveViewer's own gesture
                            // normally starving a nested drag.
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
                                return _ZoomablePageCanvas(
                                  key: ValueKey(state.currentPageIndex),
                                  width: fitWidth,
                                  height: fitHeight,
                                  state: state,
                                  onTapLine: (lineIndex, text) => _editLine(
                                    context,
                                    ref,
                                    lineIndex,
                                    text,
                                  ),
                                  onMoveImage: controller.moveImage,
                                  onRemoveImage: controller.removeImage,
                                  onMoveText: controller.moveText,
                                  onRemoveText: controller.removeText,
                                  onResizeText: controller.resizeText,
                                  onTapPage: (leftFrac, topFrac) {
                                    if (state.pendingTextEntry != null) {
                                      controller.placeText(
                                        leftFrac,
                                        topFrac,
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                          child: Column(
                            children: [
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
                                      icon: const Icon(Icons.text_fields),
                                      label: Text(
                                        l10n.addTextToPage,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      onPressed: () => _addText(context, ref),
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
                                      icon: const Icon(
                                        Icons.check_box_outlined,
                                      ),
                                      label: Text(
                                        l10n.addCheckmarkToPage,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      onPressed: () => _addCheckmark(ref),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: _color,
                                    side: BorderSide(
                                      color: _color.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.add_photo_alternate_outlined,
                                  ),
                                  label: Text(
                                    l10n.addImageToPage,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onPressed: () => _pickImage(context, ref),
                                ),
                              ),
                            ],
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

/// Renders the current page pinch-zoomable via [InteractiveViewer], with a
/// draggable overlay (pending image/text boxes, including the text resize
/// handle) that stays visually locked to the zoomed page without actually
/// living inside [InteractiveViewer]'s own widget subtree.
///
/// That split exists because of a real gesture-arena conflict:
/// [InteractiveViewer]'s [GestureDetector] is [HitTestBehavior.opaque] with
/// a `ScaleGestureRecognizer` that wins the arena for *any* pointer
/// movement under it, single-finger included - confirmed with a widget
/// test. Plain taps still reach a nested [GestureDetector] fine (a tap
/// needs no movement to resolve, so it never enters that contest), but a
/// nested `onPanUpdate` drag never fires at all if it's a *descendant* of
/// InteractiveViewer - not even with `panEnabled: false` (that only makes
/// InteractiveViewer's own reaction to the gesture a no-op, it still wins
/// the arena and starves the child).
///
/// The fix: keep the draggable overlays as *siblings* of InteractiveViewer
/// instead of descendants, so their [GestureDetector]s never enter its
/// arena at all, and manually replay the same transform onto them via a
/// shared [TransformationController] so they still visually track the zoom
/// and pan 1:1. A [Stack] only hit-tests where a child is actually
/// positioned - the empty space between overlay boxes falls straight
/// through to the [InteractiveViewer] sibling underneath for pan/zoom/tap,
/// exactly like the overlays weren't there.
class _ZoomablePageCanvas extends StatefulWidget {
  final double width;
  final double height;
  final ContentEditState state;
  final void Function(int lineIndex, String text) onTapLine;
  final void Function(int pendingIndex, double leftFrac, double topFrac)
  onMoveImage;
  final void Function(int pendingIndex) onRemoveImage;
  final void Function(int pendingIndex, double leftFrac, double topFrac)
  onMoveText;
  final void Function(int pendingIndex) onRemoveText;
  /// [totalScale] multiplies the text box's current width/height once, on
  /// resize-handle release - see the controller's resizeText().
  final void Function(int pendingIndex, double totalScale) onResizeText;
  /// Fires on a plain tap anywhere on the page background (not swallowed by
  /// a line/image/text overlay sitting on top of it) with the tap position
  /// as fractions of the page - the "where do you want it" half of placing
  /// a new [PendingText]. The caller decides whether a placement is
  /// actually in progress; this always fires regardless.
  final void Function(double leftFrac, double topFrac) onTapPage;

  const _ZoomablePageCanvas({
    super.key,
    required this.width,
    required this.height,
    required this.state,
    required this.onTapLine,
    required this.onMoveImage,
    required this.onRemoveImage,
    required this.onMoveText,
    required this.onRemoveText,
    required this.onResizeText,
    required this.onTapPage,
  });

  @override
  State<_ZoomablePageCanvas> createState() => _ZoomablePageCanvasState();
}

class _ZoomablePageCanvasState extends State<_ZoomablePageCanvas> {
  final TransformationController _transformController =
      TransformationController();

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final page = state.pages[state.currentPageIndex];
    final double dispWidth = widget.width;
    final double dispHeight = widget.height;

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
    final List<({int index, PendingText text})> texts = [
      for (int i = 0; i < state.pendingTexts.length; i++)
        if (state.pendingTexts[i].pageIndex == state.currentPageIndex)
          (index: i, text: state.pendingTexts[i]),
    ];

    return SizedBox(
      width: dispWidth,
      height: dispHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // constrained:false: InteractiveViewer's own constrained:true
          // auto-fit measures the child against loose/unbounded
          // constraints, which left this width math seeing bogus
          // constraints and every overlay landing off the page. Doing the
          // fit-to-viewport math by hand in the caller (BoxFit.contain
          // style) against the real bounded size sidesteps that.
          InteractiveViewer(
            transformationController: _transformController,
            constrained: false,
            minScale: 1.0,
            maxScale: 4.0,
            child: SizedBox(
              width: dispWidth,
              height: dispHeight,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (details) => widget.onTapPage(
                        (details.localPosition.dx / dispWidth).clamp(0, 1),
                        (details.localPosition.dy / dispHeight).clamp(0, 1),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(page.bytes, fit: BoxFit.fill),
                      ),
                    ),
                  ),
                  for (final entry in lines)
                    Positioned(
                      left: entry.line.left / page.pointsWidth * dispWidth,
                      top: entry.line.top / page.pointsHeight * dispHeight,
                      width: entry.line.width / page.pointsWidth * dispWidth,
                      height:
                          entry.line.height / page.pointsHeight * dispHeight,
                      child: _LineOverlay(
                        edited: state.textEdits.containsKey(entry.index),
                        onTap: () => widget.onTapLine(
                          entry.index,
                          state.textEdits[entry.index] ?? entry.line.text,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // The draggable overlay layer - a sibling of InteractiveViewer,
          // not a descendant (see class doc comment), kept in visual sync
          // via the same TransformationController it shares above.
          AnimatedBuilder(
            animation: _transformController,
            builder: (context, _) => Transform(
              transform: _transformController.value,
              child: SizedBox(
                width: dispWidth,
                height: dispHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (final entry in images)
                      Positioned(
                        left: entry.image.leftFrac * dispWidth,
                        top: entry.image.topFrac * dispHeight,
                        width: entry.image.widthFrac * dispWidth,
                        height: entry.image.heightFrac * dispHeight,
                        child: _PendingImageOverlay(
                          image: entry.image,
                          // Fires once, on release, with the *total* delta
                          // for the whole gesture - see the class doc
                          // comment for why this isn't called continuously
                          // per pixel like a plain onPanUpdate would.
                          onDragEnd: (totalDelta) => widget.onMoveImage(
                            entry.index,
                            entry.image.leftFrac + totalDelta.dx / dispWidth,
                            entry.image.topFrac + totalDelta.dy / dispHeight,
                          ),
                          onRemove: () => widget.onRemoveImage(entry.index),
                        ),
                      ),
                    for (final entry in texts)
                      Positioned(
                        left: entry.text.leftFrac * dispWidth,
                        top: entry.text.topFrac * dispHeight,
                        width: entry.text.widthFrac * dispWidth,
                        height: entry.text.heightFrac * dispHeight,
                        child: _PendingTextOverlay(
                          text: entry.text,
                          baseWidthPx: entry.text.widthFrac * dispWidth,
                          baseHeightPx: entry.text.heightFrac * dispHeight,
                          onDragEnd: (totalDelta) => widget.onMoveText(
                            entry.index,
                            entry.text.leftFrac + totalDelta.dx / dispWidth,
                            entry.text.topFrac + totalDelta.dy / dispHeight,
                          ),
                          onResizeEnd: (totalScale) =>
                              widget.onResizeText(entry.index, totalScale),
                          onRemove: () => widget.onRemoveText(entry.index),
                        ),
                      ),
                  ],
                ),
              ),
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

/// Draggable box for a pending image. The drag itself is tracked as *local*
/// widget state ([_liveDelta]) and only painted via a cheap
/// [Transform.translate] while the finger is down - [onDragEnd] fires once,
/// at release, with the gesture's total delta. Reporting every intermediate
/// pixel to [onDragEnd] instead (the original design) meant every single
/// [onPanUpdate] tick pushed a new [ContentEditState] through Riverpod,
/// which rebuilds the *entire* [ContentEditScreen] - including redecoding
/// the current page's full-resolution [Image.memory] - on every one of
/// those ticks. That's real per-frame work competing with the drag itself,
/// and is exactly what made a "smooth" drag feel like it was lagging behind
/// the finger (confirmed by the user reporting it, not just a guess).
class _PendingImageOverlay extends StatefulWidget {
  final PendingImage image;
  final void Function(Offset totalDelta) onDragEnd;
  final VoidCallback onRemove;

  const _PendingImageOverlay({
    required this.image,
    required this.onDragEnd,
    required this.onRemove,
  });

  @override
  State<_PendingImageOverlay> createState() => _PendingImageOverlayState();
}

class _PendingImageOverlayState extends State<_PendingImageOverlay> {
  Offset _liveDelta = Offset.zero;

  void _commitDrag() {
    final Offset delta = _liveDelta;
    setState(() => _liveDelta = Offset.zero);
    if (delta != Offset.zero) widget.onDragEnd(delta);
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: _liveDelta,
      child: GestureDetector(
        onPanUpdate: (details) =>
            setState(() => _liveDelta += details.delta),
        onPanEnd: (_) => _commitDrag(),
        onPanCancel: () => setState(() => _liveDelta = Offset.zero),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: _color, width: 1.5),
                ),
                child: Image.memory(widget.image.bytes, fit: BoxFit.fill),
              ),
            ),
            Positioned(
              right: -10,
              top: -10,
              child: GestureDetector(
                onTap: widget.onRemove,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Colors.black87,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 14,
                    color: Colors.white,
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

/// Draggable + resizable box for a pending text stamp. Both gestures track
/// *local* widget state while the finger is down (a translate offset for
/// drag, a scale factor for resize) and only report the total to the
/// controller once, on release - see [_PendingImageOverlay]'s doc comment
/// for why (the same per-tick full-screen-rebuild cost applies here, and
/// resize has the same aspect-lock requirement either way - see the
/// controller's resizeText() - so composing it as a running multiplicative
/// scale here keeps the live preview and the final commit using the exact
/// same math, not two parallel implementations that could drift apart).
class _PendingTextOverlay extends StatefulWidget {
  final PendingText text;
  /// The box's current committed size in on-screen pixels (i.e. before any
  /// in-progress local resize) - the baseline [_liveScale] multiplies for
  /// the live preview, and the baseline this widget's own resize-delta math
  /// treats "how much did this drag grow the box, relatively" against.
  final double baseWidthPx;
  final double baseHeightPx;
  final void Function(Offset totalDelta) onDragEnd;
  final void Function(double totalScale) onResizeEnd;
  final VoidCallback onRemove;

  const _PendingTextOverlay({
    required this.text,
    required this.baseWidthPx,
    required this.baseHeightPx,
    required this.onDragEnd,
    required this.onResizeEnd,
    required this.onRemove,
  });

  @override
  State<_PendingTextOverlay> createState() => _PendingTextOverlayState();
}

class _PendingTextOverlayState extends State<_PendingTextOverlay> {
  Offset _liveDelta = Offset.zero;
  double _liveScale = 1.0;

  void _commitDrag() {
    final Offset delta = _liveDelta;
    setState(() => _liveDelta = Offset.zero);
    if (delta != Offset.zero) widget.onDragEnd(delta);
  }

  void _updateResize(Offset delta) {
    final double curWidthPx = widget.baseWidthPx * _liveScale;
    final double curHeightPx = widget.baseHeightPx * _liveScale;
    if (curWidthPx <= 0 || curHeightPx <= 0) return;
    // Same "average relative growth on each axis" formula the controller's
    // resizeText() uses - kept here too so the live preview scales exactly
    // like the eventual committed result will, not just approximately.
    final double relativeGrowth =
        (delta.dx / curWidthPx + delta.dy / curHeightPx) / 2;
    setState(
      () => _liveScale = (_liveScale * (1 + relativeGrowth)).clamp(0.2, 6.0),
    );
  }

  void _commitResize() {
    final double scale = _liveScale;
    setState(() => _liveScale = 1.0);
    if (scale != 1.0) widget.onResizeEnd(scale);
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: _liveDelta,
      child: Transform.scale(
        scale: _liveScale,
        alignment: Alignment.topLeft,
        child: GestureDetector(
          onPanUpdate: (details) =>
              setState(() => _liveDelta += details.delta),
          onPanEnd: (_) => _commitDrag(),
          onPanCancel: () => setState(() => _liveDelta = Offset.zero),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: _color, width: 1.5),
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                  // fit: contain (not scaleDown) so the preview text
                  // actually grows as the box is resized larger, not just
                  // shrinks to fit - the saved PDF's real font size is
                  // derived from this same box height (see save()'s
                  // fontSize calc), so this is a true WYSIWYG preview of
                  // the resize, not just a display convenience.
                  child: FittedBox(
                    fit: BoxFit.contain,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.text.text,
                      maxLines: 1,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -10,
                top: -10,
                child: GestureDetector(
                  onTap: widget.onRemove,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: Colors.black87,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              // Bottom-right resize handle - drag to grow/shrink the box,
              // which in turn changes the saved font size (see save()'s
              // fontSize calc). A separate GestureDetector from the box's
              // own drag handler above, so a touch starting exactly on this
              // small corner target resizes instead of moves.
              Positioned(
                right: -10,
                bottom: -10,
                child: GestureDetector(
                  onPanUpdate: (details) => _updateResize(details.delta),
                  onPanEnd: (_) => _commitResize(),
                  onPanCancel: () => setState(() => _liveScale = 1.0),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: _color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.open_in_full,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
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
