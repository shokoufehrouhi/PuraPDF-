import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:signature/signature.dart';

import '../../../core/theme/feature_colors.dart';

const Color _color = FeatureColors.signatureIcon;

/// Pushes a full-screen "create a signature" flow (Draw or Type) and pops
/// with the resulting PNG bytes (transparent background), or null if the
/// user backed out without finishing one.
Future<Uint8List?> showSignaturePad(BuildContext context) {
  return Navigator.of(context).push<Uint8List>(
    MaterialPageRoute(builder: (_) => const _SignaturePadScreen()),
  );
}

class _SignaturePadScreen extends StatefulWidget {
  const _SignaturePadScreen();

  @override
  State<_SignaturePadScreen> createState() => _SignaturePadScreenState();
}

class _SignaturePadScreenState extends State<_SignaturePadScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final SignatureController _drawController;
  final TextEditingController _typeController = TextEditingController();
  final GlobalKey _typeCaptureKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _drawController = SignatureController(
      penStrokeWidth: 4,
      penColor: Colors.black,
      exportBackgroundColor: Colors.transparent,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _drawController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  Future<void> _finishDraw() async {
    if (_drawController.isEmpty) return;
    final Uint8List? bytes = await _drawController.toPngBytes();
    if (bytes != null && mounted) Navigator.of(context).pop(bytes);
  }

  Future<void> _finishType() async {
    if (_typeController.text.trim().isEmpty) return;
    final RenderRepaintBoundary boundary =
        _typeCaptureKey.currentContext!.findRenderObject()
            as RenderRepaintBoundary;
    // 3x for a crisp result once this gets scaled up on the PDF page.
    final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    image.dispose();
    if (byteData != null && mounted) {
      Navigator.of(context).pop(byteData.buffer.asUint8List());
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Signature'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _color,
          indicatorColor: _color,
          tabs: const [
            Tab(text: 'Draw'),
            Tab(text: 'Type'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // --- Draw ---
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Sign with your finger or mouse',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: scheme.outlineVariant),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Signature(
                      controller: _drawController,
                      backgroundColor: scheme.surfaceContainerHigh,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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
                        icon: const Icon(Icons.refresh),
                        label: const Text('Clear'),
                        onPressed: _drawController.clear,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _color,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.check),
                        label: const Text('Done'),
                        onPressed: _finishDraw,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // --- Type ---
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Type your name',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _typeController,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(hintText: 'Your name'),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: BoxDecoration(
                    border: Border.all(color: scheme.outlineVariant),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: RepaintBoundary(
                    key: _typeCaptureKey,
                    child: Text(
                      _typeController.text.trim().isEmpty
                          ? ' '
                          : _typeController.text,
                      style: const TextStyle(
                        fontSize: 44,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _color,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.check),
                  label: const Text('Done'),
                  onPressed: _typeController.text.trim().isEmpty
                      ? null
                      : _finishType,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
