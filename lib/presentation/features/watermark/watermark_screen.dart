import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/error_message.dart';
import '../../../core/theme/feature_colors.dart';
import '../../../domain/entities/pdf_file.dart';
import '../../../l10n/app_localizations.dart';
import '../../shared_widgets/download_file.dart';
import '../../shared_widgets/feature_screen_header.dart';
import '../../shared_widgets/picker_card.dart';
import '../../shared_widgets/picking_overlay.dart';
import '../../shared_widgets/start_over_button.dart';
import 'watermark_controller.dart';

const Color _color = FeatureColors.watermarkIcon;

class WatermarkScreen extends ConsumerWidget {
  const WatermarkScreen({super.key});

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
    ref.read(watermarkControllerProvider.notifier).setSourceFile(file);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(watermarkControllerProvider);
    final controller = ref.read(watermarkControllerProvider.notifier);
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FeatureScreenHeader(
                icon: Icons.branding_watermark_outlined,
                color: _color,
                title: l10n.watermarkTitle,
                description: l10n.watermarkDescription,
                steps: [
                  l10n.watermarkStepSelect,
                  l10n.watermarkStepText,
                  l10n.watermarkStepStamp,
                  l10n.watermarkStepSave,
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PickerCard(
                      icon: Icons.upload_file,
                      color: _color,
                      label: state.sourceFile?.name ?? l10n.selectAPdf,
                      hint: state.sourceFile == null
                          ? l10n.tapToBrowseFiles
                          : l10n.tapToChangeFile,
                      onTap: () => _pickFile(context, ref),
                    ),
                    if (state.sourceFile != null) ...[
                      const SizedBox(height: 16),
                      TextField(
                        onChanged: controller.setText,
                        decoration: InputDecoration(
                          labelText: l10n.watermarkText,
                          hintText: l10n.watermarkTextHint,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.color,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          for (final option in watermarkColorOptions)
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: GestureDetector(
                                onTap: () => controller.setColor(option),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Color.fromARGB(
                                      255,
                                      option.r,
                                      option.g,
                                      option.b,
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: state.color == option
                                          ? _color
                                          : scheme.outlineVariant,
                                      width: state.color == option ? 3 : 1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.opacityPercent((state.opacity * 100).round()),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      Slider(
                        value: state.opacity,
                        min: 0.1,
                        max: 0.8,
                        activeColor: _color,
                        onChanged: controller.setOpacity,
                      ),
                      Text(
                        l10n.sizeValue(state.fontSize.round()),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      Slider(
                        value: state.fontSize,
                        min: 20,
                        max: 200,
                        activeColor: _color,
                        onChanged: controller.setFontSize,
                      ),
                      const SizedBox(height: 8),
                      if (state.resultPath != null)
                        StartOverButton(
                          color: _color,
                          onPressed: controller.reset,
                        )
                      else
                        ElevatedButton.icon(
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
                              : const Icon(Icons.branding_watermark_outlined),
                          label: Text(l10n.watermarkButton),
                          onPressed: state.isProcessing
                              ? null
                              : controller.submit,
                        ),
                    ],
                    if (state.error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        localizedError(context, state.error!),
                        style: TextStyle(color: scheme.error),
                      ),
                    ],
                    if (state.resultPath != null) ...[
                      const SizedBox(height: 20),
                      Container(
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
                                    l10n.watermarkAdded,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
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
                                      ShareParams(
                                        files: [XFile(state.resultPath!)],
                                      ),
                                    ),
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
                                    icon: const Icon(Icons.download_outlined),
                                    label: Text(l10n.download),
                                    onPressed: () =>
                                        downloadFile(context, state.resultPath!),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
