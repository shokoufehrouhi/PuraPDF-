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
import 'signature_controller.dart';
import 'signature_pad_sheet.dart';

const Color _color = FeatureColors.signatureIcon;

class SignatureScreen extends ConsumerWidget {
  const SignatureScreen({super.key});

  Future<void> _pickFile(WidgetRef ref) async {
    final List<PlatformFile> picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (picked.isEmpty || picked.first.path == null) return;
    final file = PdfFile(path: picked.first.path!, name: picked.first.name);
    await ref.read(signatureControllerProvider.notifier).setSourceFile(file);
  }

  Future<void> _createSignature(BuildContext context, WidgetRef ref) async {
    final bytes = await showSignaturePad(context);
    if (bytes != null) {
      ref.read(signatureControllerProvider.notifier).setSignature(bytes);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(signatureControllerProvider);
    final controller = ref.read(signatureControllerProvider.notifier);
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
              icon: Icons.draw_outlined,
              color: _color,
              title: 'Digital Signature',
              description:
                  'Draw or type a signature, place it on any page, and '
                  'save.',
              steps: ['Select PDF', 'Sign', 'Place', 'Save'],
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
                              onMoveSignature: controller.moveSignature,
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
                            icon: Icon(
                              state.signatureBytes == null
                                  ? Icons.draw_outlined
                                  : Icons.edit_outlined,
                            ),
                            label: Text(
                              state.signatureBytes == null
                                  ? 'Add Signature'
                                  : 'Change Signature',
                            ),
                            onPressed: () => _createSignature(context, ref),
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
                !state.isLoadingPages &&
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
                            icon: state.isProcessing
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
                              state.signatureBytes == null
                                  ? 'Add a signature first'
                                  : 'Save signed PDF',
                            ),
                            onPressed:
                                state.isProcessing ||
                                    state.signatureBytes == null
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

/// Renders the current page at its natural aspect ratio, with a draggable
/// box for the signature (if one has been created) — positioned as
/// fractions of the page so this doesn't need to know the render
/// resolution.
class _PageCanvas extends StatelessWidget {
  final SignatureState state;
  final void Function(double leftFrac, double topFrac) onMoveSignature;

  const _PageCanvas({required this.state, required this.onMoveSignature});

  @override
  Widget build(BuildContext context) {
    final page = state.pages[state.currentPageIndex];

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
              if (state.signatureBytes != null)
                Positioned(
                  left: state.leftFrac * dispWidth,
                  top: state.topFrac * dispHeight,
                  width: state.widthFrac * dispWidth,
                  height: state.heightFrac * dispHeight,
                  child: GestureDetector(
                    onPanUpdate: (details) => onMoveSignature(
                      state.leftFrac + details.delta.dx / dispWidth,
                      state.topFrac + details.delta.dy / dispHeight,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: _color, width: 1.5),
                      ),
                      child: Image.memory(
                        state.signatureBytes!,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
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
                  'PDF signed successfully',
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
