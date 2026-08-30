import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/error_message.dart';
import '../../../core/theme/feature_colors.dart';
import '../../../domain/entities/pdf_file.dart';
import '../../../domain/entities/pdf_form_field.dart';
import '../../../l10n/app_localizations.dart';
import '../../shared_widgets/download_file.dart';
import '../../shared_widgets/feature_screen_header.dart';
import '../../shared_widgets/picker_card.dart';
import '../../shared_widgets/picking_overlay.dart';
import '../../shared_widgets/start_over_button.dart';
import 'fill_sign_controller.dart';

const Color _color = FeatureColors.fillSignIcon;

class FillSignScreen extends ConsumerWidget {
  const FillSignScreen({super.key});

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
    await ref.read(fillSignControllerProvider.notifier).setSourceFile(file);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fillSignControllerProvider);
    final controller = ref.read(fillSignControllerProvider.notifier);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final int filledCount = state.edits.length;

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
              icon: Icons.edit_document,
              color: _color,
              title: l10n.featureFillSignTitle,
              description: l10n.fillSignDescription,
              steps: [
                l10n.fillSignStepSelect,
                l10n.fillSignStepFill,
                l10n.fillSignStepConfirm,
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
                  : state.fields.isEmpty
                  ? Center(child: Text(l10n.thisPdfHasNoFormFields))
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
                                  return InteractiveViewer(
                                    maxScale: 4,
                                    child: _PageCanvas(
                                      key: ValueKey(state.currentPageIndex),
                                      width: fitWidth,
                                      state: state,
                                      onFieldText: controller.setFieldText,
                                      onToggleCheckbox:
                                          controller.toggleCheckbox,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        if (filledCount > 0)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                            child: Text(
                              l10n.fillSignButtonLabel(filledCount),
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
                state.pages.isNotEmpty &&
                state.fields.isNotEmpty)
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
                                : const Icon(Icons.edit_document),
                            label: Text(
                              filledCount == 0
                                  ? l10n.errorFillAtLeastOneFieldFirst
                                  : l10n.fillSignButtonLabel(filledCount),
                            ),
                            onPressed: state.isSaving || filledCount == 0
                                ? null
                                : controller.submit,
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

/// Renders the current page and overlays every AcroForm field found on it -
/// a text box becomes an inline `TextField`, a checkbox a tappable box,
/// anything else (radio/combo/list/signature/button - see
/// [PdfFormFieldKind.unsupported]'s doc comment) a plain non-interactive
/// outline. No custom gesture handling needed here (unlike Redact's
/// `_PageCanvas`) - there's no drag-select on this screen, just taps inside
/// ordinary widgets, so the parent's plain `InteractiveViewer` can own
/// pinch-zoom with no gesture-arena conflict.
class _PageCanvas extends StatelessWidget {
  final double width;
  final FillSignState state;
  final void Function(int fieldIndex, String text) onFieldText;
  final void Function(PdfFormField field) onToggleCheckbox;

  const _PageCanvas({
    super.key,
    required this.width,
    required this.state,
    required this.onFieldText,
    required this.onToggleCheckbox,
  });

  @override
  Widget build(BuildContext context) {
    final page = state.pages[state.currentPageIndex];
    final double dispWidth = width;
    final double dispHeight = dispWidth * page.pointsHeight / page.pointsWidth;
    final List<PdfFormField> fieldsOnPage = [
      for (final f in state.fields)
        if (f.pageIndex == state.currentPageIndex) f,
    ];

    Rect displayRect(PdfFormField f) => Rect.fromLTWH(
      f.left / page.pointsWidth * dispWidth,
      f.top / page.pointsHeight * dispHeight,
      f.width / page.pointsWidth * dispWidth,
      f.height / page.pointsHeight * dispHeight,
    );

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
          for (final PdfFormField field in fieldsOnPage)
            Positioned.fromRect(
              key: ValueKey(field.fieldIndex),
              rect: displayRect(field),
              child: switch (field.kind) {
                PdfFormFieldKind.text => _TextFieldOverlay(
                  key: ValueKey(field.fieldIndex),
                  field: field,
                  initialValue: state.textFor(field),
                  onChanged: (text) => onFieldText(field.fieldIndex, text),
                ),
                PdfFormFieldKind.checkbox => _CheckboxOverlay(
                  checked: state.checkedFor(field),
                  onTap: () => onToggleCheckbox(field),
                ),
                PdfFormFieldKind.unsupported => const _UnsupportedOverlay(),
              },
            ),
        ],
      ),
    );
  }
}

/// A `StatefulWidget` (not stateless) so its `TextEditingController` is
/// created once and survives rebuilds - a fresh controller on every parent
/// rebuild (which `onChanged` itself triggers, via Riverpod state) would
/// reset the cursor/selection on every keystroke. Keyed per `fieldIndex` by
/// the caller, so switching pages (a real widget swap) still gets a clean
/// controller instead of reusing one for the wrong field.
class _TextFieldOverlay extends StatefulWidget {
  final PdfFormField field;
  final String initialValue;
  final ValueChanged<String> onChanged;

  const _TextFieldOverlay({
    super.key,
    required this.field,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<_TextFieldOverlay> createState() => _TextFieldOverlayState();
}

class _TextFieldOverlayState extends State<_TextFieldOverlay> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.08),
        border: Border.all(color: _color.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(3),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        maxLines: widget.field.multiline ? null : 1,
        maxLength: widget.field.maxLength > 0 ? widget.field.maxLength : null,
        style: const TextStyle(fontSize: 12),
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
          counterText: '',
        ),
      ),
    );
  }
}

class _CheckboxOverlay extends StatelessWidget {
  final bool checked;
  final VoidCallback onTap;

  const _CheckboxOverlay({required this.checked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: checked ? _color.withValues(alpha: 0.18) : Colors.white,
          border: Border.all(color: _color, width: 1.5),
          borderRadius: BorderRadius.circular(3),
        ),
        child: checked
            ? const Icon(Icons.check, color: _color, size: 16)
            : null,
      ),
    );
  }
}

/// A field kind Fill & Sign can't edit yet (see
/// [PdfFormFieldKind.unsupported]'s doc comment) - shown so the user
/// understands why part of a busy form doesn't respond to taps, instead of
/// it silently doing nothing.
class _UnsupportedOverlay extends StatelessWidget {
  const _UnsupportedOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.6),
            width: 1,
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
