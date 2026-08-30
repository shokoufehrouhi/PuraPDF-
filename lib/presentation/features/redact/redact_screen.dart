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
                            // Tapping only (toggling a mark), never dragging,
                            // so the InteractiveViewer-vs-nested-drag conflict
                            // Edit PDF has to work around doesn't apply here -
                            // zoom can just stay on unconditionally.
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
                                return InteractiveViewer(
                                  constrained: false,
                                  minScale: 1.0,
                                  maxScale: 4.0,
                                  child: _PageCanvas(
                                    width: fitWidth,
                                    state: state,
                                    onTapLine: controller.toggleLine,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                          child: _BarStylePicker(
                            color: state.barColor,
                            opacity: state.barOpacity,
                            onColorChanged: controller.setBarColor,
                            onOpacityChanged: controller.setBarOpacity,
                          ),
                        ),
                        if (state.markedLines.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                            child: Text(
                              l10n.redactMarkedCount(state.markedLines.length),
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
                              state.markedLines.isEmpty
                                  ? l10n.errorMarkAtLeastOneLineToRedact
                                  : l10n.redactButtonLabel(
                                      state.markedLines.length,
                                    ),
                            ),
                            onPressed:
                                state.isSaving || state.markedLines.isEmpty
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

/// A redaction bar color choice - same swatch-row pattern as the
/// Signature feature's ink color picker.
class _ColorOption {
  final String label;
  final Color color;
  const _ColorOption(this.label, this.color);
}

const List<_ColorOption> _barColorOptions = [
  _ColorOption('Black', Colors.black),
  _ColorOption('Red', Color(0xFFDC2626)),
  _ColorOption('Blue', Color(0xFF2563EB)),
  _ColorOption('Gray', Color(0xFF64748B)),
];

/// Color + opacity controls for the redaction bar - purely a *look*
/// choice (see [PdfRedactArea]'s doc comment): the underlying text is
/// gone from the content stream no matter what this is set to, so a
/// lower opacity only affects whether something drawn underneath (a
/// background image, say) shows through the bar.
class _BarStylePicker extends StatelessWidget {
  final Color color;
  final double opacity;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<double> onOpacityChanged;

  const _BarStylePicker({
    required this.color,
    required this.opacity,
    required this.onColorChanged,
    required this.onOpacityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (final option in _barColorOptions)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () => onColorChanged(option.color),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: option.color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color == option.color
                            ? _color
                            : scheme.outlineVariant,
                        width: color == option.color ? 3 : 1,
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: Row(
                children: [
                  Icon(
                    Icons.opacity,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                  Expanded(
                    child: Slider(
                      value: opacity,
                      min: 0.3,
                      max: 1.0,
                      activeColor: _color,
                      onChanged: onOpacityChanged,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Renders the current page at its natural aspect ratio, with a tappable
/// box over each extracted text line that toggles into/out of the "marked
/// for redaction" set.
class _PageCanvas extends StatelessWidget {
  final double width;
  final RedactState state;
  final void Function(int lineIndex) onTapLine;

  const _PageCanvas({
    required this.width,
    required this.state,
    required this.onTapLine,
  });

  @override
  Widget build(BuildContext context) {
    final page = state.pages[state.currentPageIndex];
    final List<({int index, PdfTextLine line})> lines = [
      for (int i = 0; i < state.textLines.length; i++)
        if (state.textLines[i].pageIndex == state.currentPageIndex)
          (index: i, line: state.textLines[i]),
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
                marked: state.markedLines.contains(entry.index),
                barColor: state.barColor,
                barOpacity: state.barOpacity,
                onTap: () => onTapLine(entry.index),
              ),
            ),
        ],
      ),
    );
  }
}

class _LineOverlay extends StatelessWidget {
  final bool marked;
  final Color barColor;
  final double barOpacity;
  final VoidCallback onTap;

  const _LineOverlay({
    required this.marked,
    required this.barColor,
    required this.barOpacity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      // Fill matches the chosen bar color/opacity once marked - previews
      // the actual redaction bar this line will become, not just a
      // selection hint.
      child: Container(
        decoration: BoxDecoration(
          color: marked
              ? barColor.withValues(alpha: barOpacity)
              : _color.withValues(alpha: 0.0),
          border: Border.all(
            color: _color.withValues(alpha: marked ? 0.9 : 0.28),
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
