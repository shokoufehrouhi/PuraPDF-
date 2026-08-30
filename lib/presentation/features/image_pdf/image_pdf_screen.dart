import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/error_message.dart';
import '../../../core/theme/feature_colors.dart';
import '../../../domain/entities/image_output_format.dart';
import '../../../domain/entities/pdf_file.dart';
import '../../../l10n/app_localizations.dart';
import '../../shared_widgets/direction_label.dart';
import '../../shared_widgets/download_file.dart';
import '../../shared_widgets/feature_screen_header.dart';
import '../../shared_widgets/picker_card.dart';
import '../../shared_widgets/picking_overlay.dart';
import '../../shared_widgets/start_over_button.dart';
import 'image_pdf_controller.dart';

const Color _color = FeatureColors.imagePdfIcon;

class ImagePdfScreen extends ConsumerWidget {
  const ImagePdfScreen({super.key});

  Future<void> _pickImages(BuildContext context, WidgetRef ref) async {
    final List<PlatformFile> picked = await withPickingOverlay(
      context,
      () => FilePicker.pickFiles(type: FileType.image),
    );
    final files = picked
        .where((f) => f.path != null)
        .map((f) => PdfFile(path: f.path!, name: f.name))
        .toList();
    if (files.isNotEmpty) {
      ref.read(imagePdfControllerProvider.notifier).addImages(files);
    }
  }

  Future<void> _pickPdf(BuildContext context, WidgetRef ref) async {
    final List<PlatformFile> picked = await withPickingOverlay(
      context,
      () => FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      ),
    );
    if (picked.isEmpty || picked.first.path == null) return;
    final file = PdfFile(path: picked.first.path!, name: picked.first.name);
    ref.read(imagePdfControllerProvider.notifier).setSourcePdf(file);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(imagePdfControllerProvider);
    final controller = ref.read(imagePdfControllerProvider.notifier);
    final isImagesToPdf = state.direction == ConversionDirection.imagesToPdf;
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
              icon: Icons.image_outlined,
              color: _color,
              title: l10n.imagePdfTitle,
              description: isImagesToPdf
                  ? l10n.imagesToPdfDescription
                  : l10n.pdfToImagesDescription,
              fixedDescriptionLines: 3,
              steps: isImagesToPdf
                  ? [
                      l10n.imagePdfStepAddImages,
                      l10n.imagePdfStepConvert,
                      l10n.imagePdfStepSave,
                    ]
                  : [
                      l10n.imagePdfStepSelect,
                      l10n.imagePdfStepFormat,
                      l10n.imagePdfStepConvert,
                      l10n.imagePdfStepSave,
                    ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: SegmentedButton<ConversionDirection>(
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: _color.withValues(alpha: 0.18),
                  selectedForegroundColor: _color,
                ),
                segments: [
                  ButtonSegment(
                    value: ConversionDirection.imagesToPdf,
                    label: DirectionLabel(from: l10n.imagesWord, to: 'PDF'),
                  ),
                  ButtonSegment(
                    value: ConversionDirection.pdfToImages,
                    label: DirectionLabel(from: 'PDF', to: l10n.imagesWord),
                  ),
                ],
                selected: {state.direction},
                onSelectionChanged: (s) => controller.setDirection(s.first),
              ),
            ),
            Expanded(
              child: isImagesToPdf
                  ? _ImagesToPdfPane(
                      state: state,
                      controller: controller,
                      ref: ref,
                      pickImages: () => _pickImages(context, ref),
                    )
                  : _PdfToImagesPane(
                      state: state,
                      controller: controller,
                      pickPdf: () => _pickPdf(context, ref),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagesToPdfPane extends StatelessWidget {
  final ImagePdfState state;
  final ImagePdfController controller;
  final WidgetRef ref;
  final VoidCallback pickImages;

  const _ImagesToPdfPane({
    required this.state,
    required this.controller,
    required this.ref,
    required this.pickImages,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        Expanded(
          child: state.images.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: PickerCard(
                      icon: Icons.add_photo_alternate,
                      color: _color,
                      label: l10n.addImages,
                      hint: l10n.addImagesHint,
                      onTap: pickImages,
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
                              l10n.imagesSelectedCount(state.images.length),
                              style: TextStyle(
                                fontSize: 12.5,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: pickImages,
                            icon: const Icon(Icons.add, size: 18),
                            label: Text(l10n.addMore),
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
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: state.images.length,
                        itemBuilder: (context, index) {
                          final f = state.images[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Container(
                                width: 32,
                                height: 32,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _color.withValues(alpha: 0.18),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: _color,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              title: Text(
                                f.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.close),
                                tooltip: l10n.remove,
                                onPressed: () =>
                                    controller.removeImageAt(index),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ),
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              localizedError(context, state.error!),
              style: TextStyle(color: scheme.error),
            ),
          ),
        if (state.resultPdfPath != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Container(
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
                            ShareParams(files: [XFile(state.resultPdfPath!)]),
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
                              downloadFile(context, state.resultPdfPath!),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: state.resultPdfPath != null
                ? StartOverButton(color: _color, onPressed: controller.reset)
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
                          : const Icon(Icons.picture_as_pdf),
                      label: Text(
                        state.images.isEmpty
                            ? l10n.convertButtonEmpty
                            : l10n.convertButtonReady(state.images.length),
                      ),
                      onPressed: state.isProcessing || state.images.isEmpty
                          ? null
                          : controller.convert,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _PdfToImagesPane extends StatelessWidget {
  final ImagePdfState state;
  final ImagePdfController controller;
  final VoidCallback pickPdf;

  const _PdfToImagesPane({
    required this.state,
    required this.controller,
    required this.pickPdf,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PickerCard(
            icon: Icons.upload_file,
            color: _color,
            label: state.sourcePdf?.name ?? l10n.selectAPdf,
            hint: state.sourcePdf == null
                ? l10n.tapToBrowseFiles
                : l10n.tapToChangeFile,
            onTap: pickPdf,
          ),
          const SizedBox(height: 16),
          SegmentedButton<ImageOutputFormat>(
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: _color.withValues(alpha: 0.18),
              selectedForegroundColor: _color,
            ),
            segments: const [
              ButtonSegment(value: ImageOutputFormat.jpg, label: Text('JPG')),
              ButtonSegment(value: ImageOutputFormat.png, label: Text('PNG')),
            ],
            selected: {state.outputFormat},
            onSelectionChanged: (s) => controller.setOutputFormat(s.first),
          ),
          const SizedBox(height: 16),
          if (state.resultImagePaths.isNotEmpty)
            StartOverButton(color: _color, onPressed: controller.reset)
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
                  : const Icon(Icons.image),
              label: Text(l10n.convertButton),
              onPressed: state.isProcessing ? null : controller.convert,
            ),
          if (state.error != null) ...[
            const SizedBox(height: 12),
            Text(
              localizedError(context, state.error!),
              style: TextStyle(color: scheme.error),
            ),
          ],
          if (state.resultImagePaths.isNotEmpty) ...[
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
                          l10n.imagesCreatedCount(
                            state.resultImagePaths.length,
                          ),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...state.resultImagePaths.map(
                    (p) => Card(
                      margin: const EdgeInsets.only(top: 4),
                      child: ListTile(
                        leading: const Icon(Icons.image),
                        title: Text(
                          p.split('/').last,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.ios_share),
                              tooltip: l10n.share,
                              onPressed: () => SharePlus.instance.share(
                                ShareParams(files: [XFile(p)]),
                              ),
                            ),
                            DownloadIconButton(path: p),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (state.resultImagePaths.length > 1) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _color,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              side: BorderSide(
                                color: _color.withValues(alpha: 0.5),
                              ),
                            ),
                            icon: const Icon(Icons.folder_zip),
                            label: Text(
                              l10n.shareZip,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onPressed: () async {
                              final zipPath = await controller.zipResults();
                              if (context.mounted) {
                                await SharePlus.instance.share(
                                  ShareParams(files: [XFile(zipPath)]),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _color,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              side: BorderSide(
                                color: _color.withValues(alpha: 0.5),
                              ),
                            ),
                            icon: const Icon(Icons.download_outlined),
                            label: Text(
                              l10n.downloadZip,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onPressed: () async {
                              final zipPath = await controller.zipResults();
                              if (context.mounted) {
                                await downloadFile(context, zipPath);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
