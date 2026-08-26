import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../domain/entities/image_output_format.dart';
import '../../../domain/entities/pdf_file.dart';
import '../../shared_widgets/download_file.dart';
import 'image_pdf_controller.dart';

class ImagePdfScreen extends ConsumerWidget {
  const ImagePdfScreen({super.key});

  Future<void> _pickImages(WidgetRef ref) async {
    final List<PlatformFile> picked = await FilePicker.pickFiles(
      type: FileType.image,
    );
    final files = picked
        .where((f) => f.path != null)
        .map((f) => PdfFile(path: f.path!, name: f.name))
        .toList();
    if (files.isNotEmpty) {
      ref.read(imagePdfControllerProvider.notifier).addImages(files);
    }
  }

  Future<void> _pickPdf(WidgetRef ref) async {
    final List<PlatformFile> picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
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

    return Scaffold(
      appBar: AppBar(title: const Text('Image ⇄ PDF')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<ConversionDirection>(
              segments: const [
                ButtonSegment(
                  value: ConversionDirection.imagesToPdf,
                  label: Text('Images → PDF'),
                ),
                ButtonSegment(
                  value: ConversionDirection.pdfToImages,
                  label: Text('PDF → Images'),
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
                    pickImages: () => _pickImages(ref),
                  )
                : _PdfToImagesPane(
                    state: state,
                    controller: controller,
                    pickPdf: () => _pickPdf(ref),
                  ),
          ),
        ],
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
    return Column(
      children: [
        Expanded(
          child: state.images.isEmpty
              ? const Center(child: Text('Hich aksi entekhab nashode.'))
              : ListView.builder(
                  itemCount: state.images.length,
                  itemBuilder: (context, index) {
                    final f = state.images[index];
                    return ListTile(
                      leading: const Icon(Icons.image),
                      title: Text(f.name),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => controller.removeImageAt(index),
                      ),
                    );
                  },
                ),
        ),
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              state.error!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        if (state.resultPdfPath != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                const Text('PDF sakhte shod ✅'),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                      onPressed: () => SharePlus.instance.share(
                        ShareParams(files: [XFile(state.resultPdfPath!)]),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.download),
                      label: const Text('Download'),
                      onPressed: () =>
                          downloadFile(context, state.resultPdfPath!),
                    ),
                  ],
                ),
              ],
            ),
          ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('Add images'),
                  onPressed: pickImages,
                ),
                ElevatedButton.icon(
                  icon: state.isProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.picture_as_pdf),
                  label: const Text('Convert'),
                  onPressed: state.isProcessing ? null : controller.convert,
                ),
              ],
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.upload_file),
            label: Text(state.sourcePdf?.name ?? 'Select a PDF'),
            onPressed: pickPdf,
          ),
          const SizedBox(height: 16),
          SegmentedButton<ImageOutputFormat>(
            segments: const [
              ButtonSegment(value: ImageOutputFormat.jpg, label: Text('JPG')),
              ButtonSegment(value: ImageOutputFormat.png, label: Text('PNG')),
            ],
            selected: {state.outputFormat},
            onSelectionChanged: (s) => controller.setOutputFormat(s.first),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: state.isProcessing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.image),
            label: const Text('Convert'),
            onPressed: state.isProcessing ? null : controller.convert,
          ),
          if (state.error != null) ...[
            const SizedBox(height: 12),
            Text(state.error!, style: const TextStyle(color: Colors.red)),
          ],
          if (state.resultImagePaths.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('${state.resultImagePaths.length} image(s) created ✅'),
            const SizedBox(height: 8),
            ...state.resultImagePaths.map(
              (p) => ListTile(
                leading: const Icon(Icons.image),
                title: Text(p.split('/').last),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.share),
                      tooltip: 'Share',
                      onPressed: () => SharePlus.instance.share(
                        ShareParams(files: [XFile(p)]),
                      ),
                    ),
                    DownloadIconButton(path: p),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
