import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/error_message.dart';
import '../../../core/theme/feature_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../shared_widgets/download_file.dart';
import '../../shared_widgets/feature_screen_header.dart';
import '../../shared_widgets/picker_card.dart';
import '../../shared_widgets/start_over_button.dart';
import 'scanner_controller.dart';

const Color _color = FeatureColors.scannerIcon;

class ScannerScreen extends ConsumerWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scannerControllerProvider);
    final controller = ref.read(scannerControllerProvider.notifier);
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
              icon: Icons.document_scanner_outlined,
              color: _color,
              title: l10n.scanTitle,
              description: l10n.scanDescription,
              steps: [
                l10n.scanStepScan,
                l10n.scanStepReorder,
                l10n.scanStepCreatePdf,
                l10n.scanStepSave,
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
              child: state.pages.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: PickerCard(
                          icon: Icons.camera_alt_outlined,
                          color: _color,
                          label: l10n.scanADocument,
                          hint: state.isScanning
                              ? l10n.openingCamera
                              : l10n.scanHint,
                          onTap: state.isScanning ? () {} : controller.scan,
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  l10n.scanPageCount(state.pages.length),
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: state.isScanning
                                    ? null
                                    : controller.scan,
                                icon: const Icon(
                                  Icons.camera_alt_outlined,
                                  size: 18,
                                ),
                                label: Text(l10n.scanMore),
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
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: state.pages.length,
                            onReorderItem: controller.reorderItem,
                            itemBuilder: (context, index) {
                              final String path = state.pages[index];
                              return Card(
                                // Not index-based - scanned pages keep the
                                // same generated path across a reorder, and
                                // keying by index too would make Flutter
                                // treat every dragged item as a brand new
                                // widget and break the reorder animation.
                                key: ValueKey(path),
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          File(path),
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
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
                                                  bottomRight: Radius.circular(
                                                    8,
                                                  ),
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
                                  title: Text(l10n.pageNumberLabel(index + 1)),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.close),
                                        tooltip: l10n.remove,
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
            if (state.pages.isNotEmpty && state.resultPath == null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 20, 4),
                child: SwitchListTile(
                  value: state.runOcr,
                  onChanged: controller.setRunOcr,
                  activeThumbColor: _color,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    l10n.scanOcrToggleLabel,
                    style: const TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    l10n.scanOcrToggleHint,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: state.resultPath != null
                    ? StartOverButton(color: _color, onPressed: controller.reset)
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _color,
                            foregroundColor: Colors.white,
                          ),
                          icon: state.isCreatingPdf
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.picture_as_pdf),
                          label: Text(
                            state.pages.isEmpty
                                ? l10n.errorScanAtLeastOnePage
                                : l10n.createPdfButtonReady(
                                    state.pages.length,
                                  ),
                          ),
                          onPressed: state.isCreatingPdf || state.pages.isEmpty
                              ? null
                              : controller.createPdf,
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
                  l10n.pdfCreatedSuccess,
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
