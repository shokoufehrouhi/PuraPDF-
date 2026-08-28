import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/feature_colors.dart';
import '../core/theme/theme_mode_controller.dart';
import '../domain/entities/history_file.dart';
import '../core/scanner_support.dart';
import 'features/compress/compress_screen.dart';
import 'features/content_edit/content_edit_screen.dart';
import 'features/encrypt/encrypt_screen.dart';
import 'features/history/history_controller.dart';
import 'features/image_pdf/image_pdf_screen.dart';
import 'features/merge/merge_screen.dart';
import 'features/page_edit/page_edit_screen.dart';
import 'features/scanner/scanner_screen.dart';
import 'features/signature/signature_screen.dart';
import 'features/split/split_screen.dart';
import 'features/watermark/watermark_screen.dart';
import 'shared_widgets/banner_ad_widget.dart';
import 'shared_widgets/download_file.dart';

/// Landing screen — feature hub. Grows one tile per Phase-1 feature as each
/// lands (merge/split/compress/...).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tabIndex = 0;

  IconData _themeIcon(ThemeMode mode) => mode == ThemeMode.dark
      ? Icons.dark_mode_outlined
      : Icons.light_mode_outlined;

  String _themeLabel(ThemeMode mode) =>
      mode == ThemeMode.dark ? 'Dark theme' : 'Light theme';

  @override
  Widget build(BuildContext context) {
    final ThemeMode themeMode = ref.watch(themeModeControllerProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          _RecentsIconButton(
            active: _tabIndex == 1,
            onPressed: () =>
                setState(() => _tabIndex = _tabIndex == 1 ? 0 : 1),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(_themeIcon(themeMode)),
            tooltip: '${_themeLabel(themeMode)} — tap to change',
            onPressed: () =>
                ref.read(themeModeControllerProvider.notifier).cycle(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const _Header(),
            const SizedBox(height: 8),
            Expanded(
              child: _tabIndex == 0
                  ? const _ToolsTab()
                  : _RecentsTab(
                      onBrowseTools: () => setState(() => _tabIndex = 0),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BannerAdWidget(),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Image.asset(
                  'assets/icon/icon.png',
                  width: 38,
                  height: 38,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 10),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'PuraPDF',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                    TextSpan(
                      text: '+',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.seedColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Your PDF toolkit — merge, split, compress, and convert, '
            'all on-device.',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Recents used to be a full "Tools / Recents" segmented tab bar; now it's
/// this single icon in the app bar, tinted when active — same toggle
/// behavior as before (switches _tabIndex), just a lighter-weight control
/// since Tools is the primary/default surface.
class _RecentsIconButton extends StatelessWidget {
  final bool active;
  final VoidCallback onPressed;

  const _RecentsIconButton({required this.active, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return IconButton(
      icon: const Icon(Icons.history_rounded),
      tooltip: active ? 'Back to tools' : 'Recents',
      style: IconButton.styleFrom(
        backgroundColor: active
            ? AppTheme.seedColor.withValues(alpha: 0.14)
            : Colors.transparent,
        foregroundColor: active ? AppTheme.seedColor : scheme.onSurfaceVariant,
      ),
      onPressed: onPressed,
    );
  }
}

/// Tools tab — a small "Organize" / "Edit & Protect" segmented tab bar up
/// top switches which category's grid is shown below, so only one set of
/// cards is on screen at a time instead of one long scroll of everything.
class _ToolsTab extends StatefulWidget {
  const _ToolsTab();

  @override
  State<_ToolsTab> createState() => _ToolsTabState();
}

class _ToolsTabState extends State<_ToolsTab> {
  int _categoryIndex = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final int columns = constraints.maxWidth >= 600 ? 2 : 1;

        final List<Widget> organizeCards = [
          _FeatureRowCard(
            icon: Icons.call_merge,
            color: FeatureColors.merge,
            colorDark: FeatureColors.mergeDark,
            iconColor: FeatureColors.mergeIcon,
            title: 'Merge PDFs',
            subtitle: 'Combine multiple documents',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MergeScreen()),
            ),
          ),
          _FeatureRowCard(
            icon: Icons.call_split,
            color: FeatureColors.split,
            colorDark: FeatureColors.splitDark,
            iconColor: FeatureColors.splitIcon,
            title: 'Split PDF',
            subtitle: 'Separate into pages or sections',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SplitScreen()),
            ),
          ),
          _FeatureRowCard(
            icon: Icons.compress,
            color: FeatureColors.compress,
            colorDark: FeatureColors.compressDark,
            iconColor: FeatureColors.compressIcon,
            title: 'Compress PDF',
            subtitle: 'Optimize file size for sharing',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CompressScreen()),
            ),
          ),
          _FeatureRowCard(
            icon: Icons.image_outlined,
            color: FeatureColors.imagePdf,
            colorDark: FeatureColors.imagePdfDark,
            iconColor: FeatureColors.imagePdfIcon,
            title: 'Image ⇄ PDF',
            subtitle: 'Convert between formats',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ImagePdfScreen()),
            ),
          ),
          if (scannerSupported)
            _FeatureRowCard(
              icon: Icons.document_scanner_outlined,
              color: FeatureColors.scanner,
              colorDark: FeatureColors.scannerDark,
              iconColor: FeatureColors.scannerIcon,
              title: 'Scan Document',
              subtitle: 'Capture paper documents with your camera',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ScannerScreen()),
              ),
            ),
        ];

        final List<Widget> editCards = [
          _FeatureRowCard(
            icon: Icons.crop_rotate,
            color: FeatureColors.pageEdit,
            colorDark: FeatureColors.pageEditDark,
            iconColor: FeatureColors.pageEditIcon,
            title: 'Edit Pages',
            subtitle: 'Rotate, reorder, or remove pages',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PageEditScreen()),
            ),
          ),
          _FeatureRowCard(
            icon: Icons.text_fields,
            color: FeatureColors.contentEdit,
            colorDark: FeatureColors.contentEditDark,
            iconColor: FeatureColors.contentEditIcon,
            title: 'Edit PDF',
            subtitle: 'Fix text, remove a line, add an image',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ContentEditScreen()),
            ),
          ),
          _FeatureRowCard(
            icon: Icons.lock_outline,
            color: FeatureColors.encrypt,
            colorDark: FeatureColors.encryptDark,
            iconColor: FeatureColors.encryptIcon,
            title: 'Password Protect',
            subtitle: 'Add or remove a PDF password',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EncryptScreen()),
            ),
          ),
          _FeatureRowCard(
            icon: Icons.branding_watermark_outlined,
            color: FeatureColors.watermark,
            colorDark: FeatureColors.watermarkDark,
            iconColor: FeatureColors.watermarkIcon,
            title: 'Watermark',
            subtitle: 'Stamp text across every page',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WatermarkScreen()),
            ),
          ),
          _FeatureRowCard(
            icon: Icons.draw_outlined,
            color: FeatureColors.signature,
            colorDark: FeatureColors.signatureDark,
            iconColor: FeatureColors.signatureIcon,
            title: 'Digital Signature',
            subtitle: 'Draw or type a signature, place it, save',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SignatureScreen()),
            ),
          ),
        ];

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                  child: _CategoryTabBar(
                    index: _categoryIndex,
                    onChanged: (i) => setState(() => _categoryIndex = i),
                  ),
                ),
                Expanded(
                  child: GridView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisExtent: 78,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                    children: _categoryIndex == 0 ? organizeCards : editCards,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Two-segment "Organize" / "Edit & Protect" switcher for the Tools tab —
/// same pill styling language as [_RecentsIconButton]'s active tint.
class _CategoryTabBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const _CategoryTabBar({required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _CategoryTabSegment(
            label: 'Organize',
            selected: index == 0,
            onTap: () => onChanged(0),
          ),
          _CategoryTabSegment(
            label: 'Edit & Protect',
            selected: index == 1,
            onTap: () => onChanged(1),
          ),
        ],
      ),
    );
  }
}

class _CategoryTabSegment extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryTabSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppTheme.seedColor : Colors.transparent,
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureRowCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color colorDark;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FeatureRowCard({
    required this.icon,
    required this.color,
    required this.colorDark,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Light mode: light pastel card + dark near-black text (white text
    // would lose contrast on a pale card). Dark mode: the pastel would
    // wash out against a dark scaffold, so the card gradient is instead
    // derived from the feature's own saturated iconColor blended toward
    // a neutral dark grey — kept close together (0.5/0.62, was 0.55/0.72)
    // so the card reads as evenly colored instead of fading to a heavy
    // dark corner that reads as a shadow. No box shadow at all in dark
    // mode (a glow or a plain black one both looked wrong against a dark
    // scaffold); light mode keeps its colored shadow for lift.
    const Color darkMuted = Color(0xFF2A2A30);
    final Color cardTop = isDark
        ? Color.lerp(iconColor, darkMuted, 0.50)!
        : color;
    final Color cardBottom = isDark
        ? Color.lerp(iconColor, darkMuted, 0.62)!
        : colorDark;
    final Color textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final Color badgeColor = isDark
        ? iconColor
        : Colors.white.withValues(alpha: 0.85);
    final Color badgeIconColor = isDark ? Colors.white : iconColor;
    final List<BoxShadow> shadow = isDark
        ? const []
        : [
            BoxShadow(
              color: iconColor.withValues(alpha: 0.22),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ];

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [cardTop, cardBottom],
            ),
            boxShadow: shadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // The reference mockup's glossy sheen — soft diagonal
                // light streaks over the flat gradient.
                Positioned.fill(
                  child: CustomPaint(
                    painter: _DiagonalSheenPainter(
                      opacity: isDark ? 0.045 : 0.16,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(icon, color: badgeIconColor, size: 20),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 14.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 1),
                            Text(
                              subtitle,
                              style: TextStyle(
                                color: textColor.withValues(
                                  alpha: isDark ? 0.82 : 0.72,
                                ),
                                fontSize: 11.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: textColor.withValues(alpha: isDark ? 0.7 : 0.55),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints soft, evenly-spaced diagonal white streaks — the glossy sheen
/// look from the reference mockup, layered under the card's content.
///
/// [opacity] is theme-specific: the same white stripe reads very
/// differently against a light pastel card vs. a dark muted one, so this
/// isn't one fixed value — see the two call sites in _FeatureRowCard.
class _DiagonalSheenPainter extends CustomPainter {
  final double opacity;

  const _DiagonalSheenPainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14;

    const double spacing = 34;
    final double span = size.width + size.height;
    for (double x = -size.height; x < span; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DiagonalSheenPainter oldDelegate) =>
      oldDelegate.opacity != opacity;
}

/// What kind of tool produced a generated file — derived from the output
/// filename's `purapdf_<op>_...` prefix (see `_writeOutput`/`_recordGenerated`
/// in [PdfRepositoryImpl]) rather than a stored field, so it stays correct
/// even for files written before this existed.
class _OperationInfo {
  final IconData icon;
  final Color color;
  final String label;

  const _OperationInfo(this.icon, this.color, this.label);
}

const _OperationInfo _unknownOperation = _OperationInfo(
  Icons.insert_drive_file,
  Color(0xFF9CA3AF),
  'File',
);

_OperationInfo _operationFor(String fileName) {
  if (fileName.startsWith('purapdf_merged_')) {
    return const _OperationInfo(
      Icons.call_merge,
      FeatureColors.mergeIcon,
      'Merge',
    );
  }
  if (fileName.startsWith('purapdf_split_')) {
    return const _OperationInfo(
      Icons.call_split,
      FeatureColors.splitIcon,
      'Split',
    );
  }
  if (fileName.startsWith('purapdf_compressed_')) {
    return const _OperationInfo(
      Icons.compress,
      FeatureColors.compressIcon,
      'Compress',
    );
  }
  if (fileName.startsWith('purapdf_images_')) {
    return const _OperationInfo(
      Icons.image_outlined,
      FeatureColors.imagePdfIcon,
      'Image → PDF',
    );
  }
  if (fileName.startsWith('purapdf_page_')) {
    return const _OperationInfo(
      Icons.image_outlined,
      FeatureColors.imagePdfIcon,
      'PDF → Image',
    );
  }
  if (fileName.startsWith('purapdf_scan_')) {
    return const _OperationInfo(
      Icons.document_scanner_outlined,
      FeatureColors.scannerIcon,
      'Scan',
    );
  }
  if (fileName.startsWith('purapdf_pages_')) {
    return const _OperationInfo(
      Icons.crop_rotate,
      FeatureColors.pageEditIcon,
      'Edit Pages',
    );
  }
  if (fileName.startsWith('purapdf_content_')) {
    return const _OperationInfo(
      Icons.text_fields,
      FeatureColors.contentEditIcon,
      'Edit PDF',
    );
  }
  if (fileName.startsWith('purapdf_locked_')) {
    return const _OperationInfo(
      Icons.lock_outline,
      FeatureColors.encryptIcon,
      'Locked',
    );
  }
  if (fileName.startsWith('purapdf_unlocked_')) {
    return const _OperationInfo(
      Icons.lock_open_outlined,
      FeatureColors.encryptIcon,
      'Unlocked',
    );
  }
  if (fileName.startsWith('purapdf_watermark_')) {
    return const _OperationInfo(
      Icons.branding_watermark_outlined,
      FeatureColors.watermarkIcon,
      'Watermark',
    );
  }
  if (fileName.startsWith('purapdf_signed_')) {
    return const _OperationInfo(
      Icons.draw_outlined,
      FeatureColors.signatureIcon,
      'Signed',
    );
  }
  return _unknownOperation;
}

const List<String> _monthAbbrevs = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _formatDateTime(DateTime dt) {
  final DateTime local = dt.toLocal();
  final String month = _monthAbbrevs[local.month - 1];
  final int hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final String ampm = local.hour < 12 ? 'AM' : 'PM';
  final String minute = local.minute.toString().padLeft(2, '0');
  return '$month ${local.day}, $hour12:$minute $ampm';
}

/// Recents tab — the app's only history surface (the dedicated History
/// screen was removed; every generated file lives here, one row per
/// operation: type, date/time, file name, download, share).
class _RecentsTab extends ConsumerStatefulWidget {
  final VoidCallback onBrowseTools;

  const _RecentsTab({required this.onBrowseTools});

  @override
  ConsumerState<_RecentsTab> createState() => _RecentsTabState();
}

class _RecentsTabState extends ConsumerState<_RecentsTab> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(historyControllerProvider.notifier).refresh(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(historyControllerProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.files.isEmpty) {
      final ColorScheme scheme = Theme.of(context).colorScheme;
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppTheme.seedColor.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.folder_open_rounded,
                  size: 38,
                  color: AppTheme.seedColor,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No files yet',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Files you create with Merge, Split, Compress, or '
                'Image ⇄ PDF will show up here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 22),
              OutlinedButton.icon(
                onPressed: widget.onBrowseTools,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.seedColor,
                  side: BorderSide(
                    color: AppTheme.seedColor.withValues(alpha: 0.5),
                  ),
                ),
                icon: const Icon(Icons.grid_view_rounded, size: 18),
                label: const Text('Browse tools'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      itemCount: state.files.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) =>
          _RecentRecordRow(file: state.files[index]),
    );
  }
}

class _RecentRecordRow extends StatelessWidget {
  final HistoryFile file;

  const _RecentRecordRow({required this.file});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final _OperationInfo op = _operationFor(file.name);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Operation-type column: colored badge doubles as the type
          // indicator, with the label spelled out beside it.
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: op.color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(op.icon, color: op.color, size: 18),
          ),
          const SizedBox(width: 10),
          // File name + date-time column.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      op.label,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: op.color,
                      ),
                    ),
                    Text(
                      '  •  ${_formatDateTime(file.createdAt)}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Download / share columns.
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Download',
            onPressed: () => downloadFile(context, file.path),
          ),
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: 'Share',
            onPressed: () => SharePlus.instance.share(
              ShareParams(files: [XFile(file.path)]),
            ),
          ),
        ],
      ),
    );
  }
}
