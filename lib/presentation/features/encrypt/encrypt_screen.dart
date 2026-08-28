import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/feature_colors.dart';
import '../../../domain/entities/pdf_file.dart';
import '../../shared_widgets/download_file.dart';
import '../../shared_widgets/feature_screen_header.dart';
import '../../shared_widgets/picker_card.dart';
import '../../shared_widgets/start_over_button.dart';
import 'encrypt_controller.dart';

const Color _color = FeatureColors.encryptIcon;

class EncryptScreen extends ConsumerWidget {
  const EncryptScreen({super.key});

  Future<void> _pickFile(WidgetRef ref) async {
    final List<PlatformFile> picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (picked.isEmpty || picked.first.path == null) return;
    final file = PdfFile(path: picked.first.path!, name: picked.first.name);
    ref.read(encryptControllerProvider.notifier).setSourceFile(file);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(encryptControllerProvider);
    final controller = ref.read(encryptControllerProvider.notifier);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isAdd = state.action == PasswordAction.add;

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
                icon: Icons.lock_outline,
                color: _color,
                title: 'Password Protect',
                description: isAdd
                    ? 'Lock a PDF with a password so only people who know '
                          'it can open it.'
                    : 'Remove a PDF\'s password, given the correct one.',
                steps: isAdd
                    ? const ['Select PDF', 'Set password', 'Lock', 'Save']
                    : const ['Select PDF', 'Enter password', 'Unlock', 'Save'],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SegmentedButton<PasswordAction>(
                      style: SegmentedButton.styleFrom(
                        selectedBackgroundColor: _color.withValues(
                          alpha: 0.18,
                        ),
                        selectedForegroundColor: _color,
                      ),
                      segments: const [
                        ButtonSegment(
                          value: PasswordAction.add,
                          label: Text('Add Password'),
                        ),
                        ButtonSegment(
                          value: PasswordAction.remove,
                          label: Text('Remove Password'),
                        ),
                      ],
                      selected: {state.action},
                      onSelectionChanged: (s) =>
                          controller.setAction(s.first),
                    ),
                    const SizedBox(height: 16),
                    PickerCard(
                      icon: Icons.upload_file,
                      color: _color,
                      label: state.sourceFile?.name ?? 'Select a PDF',
                      hint: state.sourceFile == null
                          ? 'Tap to browse your files'
                          : 'Tap to change file',
                      onTap: () => _pickFile(ref),
                    ),
                    if (state.sourceFile != null) ...[
                      const SizedBox(height: 16),
                      TextField(
                        obscureText: state.obscurePassword,
                        onChanged: controller.setPassword,
                        inputFormatters: [
                          FilteringTextInputFormatter.deny(RegExp(r'\s')),
                        ],
                        decoration: InputDecoration(
                          labelText: isAdd ? 'Password' : 'Current password',
                          helperText: isAdd
                              ? 'At least '
                                    '${EncryptController.minPasswordLength} '
                                    'characters, no spaces'
                              : null,
                          suffixIcon: IconButton(
                            icon: Icon(
                              state.obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            tooltip: state.obscurePassword
                                ? 'Show password'
                                : 'Hide password',
                            onPressed: controller.toggleObscurePassword,
                          ),
                        ),
                      ),
                      if (isAdd) ...[
                        const SizedBox(height: 12),
                        TextField(
                          obscureText: state.obscureConfirmPassword,
                          onChanged: controller.setConfirmPassword,
                          inputFormatters: [
                            FilteringTextInputFormatter.deny(RegExp(r'\s')),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Confirm password',
                            suffixIcon: IconButton(
                              icon: Icon(
                                state.obscureConfirmPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              tooltip: state.obscureConfirmPassword
                                  ? 'Show password'
                                  : 'Hide password',
                              onPressed: controller.toggleObscureConfirmPassword,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
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
                              : Icon(
                                  isAdd
                                      ? Icons.lock_outline
                                      : Icons.lock_open_outlined,
                                ),
                          label: Text(isAdd ? 'Add Password' : 'Remove Password'),
                          onPressed: state.isProcessing
                              ? null
                              : controller.submit,
                        ),
                    ],
                    if (state.error != null) ...[
                      const SizedBox(height: 12),
                      Text(state.error!, style: TextStyle(color: scheme.error)),
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
                                    isAdd
                                        ? 'Password added'
                                        : 'Password removed',
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
                                    label: const Text('Share'),
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
                                    label: const Text('Download'),
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
