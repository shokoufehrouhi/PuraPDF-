import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:signature/signature.dart';

import '../../../core/theme/feature_colors.dart';

const Color _color = FeatureColors.signatureIcon;

/// A signature ink color choice.
class _ColorOption {
  final String label;
  final Color color;
  const _ColorOption(this.label, this.color);
}

const List<_ColorOption> _colorOptions = [
  _ColorOption('Blue', Color(0xFF2563EB)),
  _ColorOption('Red', Color(0xFFDC2626)),
  _ColorOption('Black', Colors.black),
  _ColorOption('Green', Color(0xFF16A34A)),
];

/// A typed-signature font choice — [preview] is shown rendered in its own
/// font so the difference is obvious at a glance, not just named.
class _FontOption {
  final String label;
  final String family;
  const _FontOption(this.label, this.family);
}

const List<_FontOption> _fontOptions = [
  _FontOption('Elegant', 'DancingScript'),
  _FontOption('Bold', 'Pacifico'),
  _FontOption('Casual', 'Caveat'),
];

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
  late SignatureController _drawController;
  final TextEditingController _typeController = TextEditingController();
  final GlobalKey _typeCaptureKey = GlobalKey();

  _ColorOption _drawColor = _colorOptions[2]; // Black
  _ColorOption _typeColor = _colorOptions[2];
  _FontOption _typeFont = _fontOptions[0];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _drawController = _newDrawController(_drawColor.color);
  }

  SignatureController _newDrawController(Color color) {
    return SignatureController(
      penStrokeWidth: 4,
      penColor: color,
      exportBackgroundColor: Colors.transparent,
      exportPenColor: color,
    );
  }

  void _setDrawColor(_ColorOption option) {
    // penColor/exportPenColor are only set at construction, so changing
    // ink color means starting a fresh controller (and canvas).
    final old = _drawController;
    setState(() {
      _drawColor = option;
      _drawController = _newDrawController(option.color);
    });
    old.dispose();
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

  Widget _colorPicker(_ColorOption selected, ValueChanged<_ColorOption> onPick) {
    return Row(
      children: [
        for (final option in _colorOptions)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => onPick(option),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: option.color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected == option
                        ? _color
                        : Theme.of(context).colorScheme.outlineVariant,
                    width: selected == option ? 3 : 1,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
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
                _colorPicker(_drawColor, _setDrawColor),
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
                const SizedBox(height: 16),
                Text(
                  'Style',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final font in _fontOptions)
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: ChoiceChip(
                          selected: _typeFont == font,
                          selectedColor: _color.withValues(alpha: 0.18),
                          onSelected: (_) => setState(() => _typeFont = font),
                          label: Text(
                            'Abc',
                            style: TextStyle(
                              fontFamily: font.family,
                              fontSize: 20,
                              color: _typeFont == font
                                  ? _color
                                  : scheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Color',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                _colorPicker(
                  _typeColor,
                  (option) => setState(() => _typeColor = option),
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
                      style: TextStyle(
                        fontFamily: _typeFont.family,
                        fontSize: 44,
                        color: _typeColor.color,
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
