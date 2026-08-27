import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/theme_mode_controller.dart';
import 'features/compress/compress_screen.dart';
import 'features/history/history_controller.dart';
import 'features/history/history_screen.dart';
import 'features/image_pdf/image_pdf_screen.dart';
import 'features/merge/merge_screen.dart';
import 'features/split/split_screen.dart';
import 'shared_widgets/banner_ad_widget.dart';
import 'shared_widgets/download_file.dart';

/// Per-feature accent colors — deliberately distinct from the app's red
/// brand color (reserved for the logo/CTAs) so each tool reads as its own
/// "app icon" at a glance, the way a tool suite gives every module its own
/// hue instead of one flat brand tint everywhere.
///
/// Each feature has: a light/lighter pair for the card's own soft pastel
/// gradient (glossy, not matte — a subtle sheen, not a flat muted fill),
/// plus a separate saturated [icon] color so the icon reads clearly
/// against its white badge instead of matching the pale card behind it.
class _FeatureColors {
  _FeatureColors._();

  static const Color merge = Color(0xFFC7E3FC);
  static const Color mergeDark = Color(0xFFACD3FA);
  static const Color mergeIcon = Color(0xFF3B82F6);

  static const Color split = Color(0xFFE4D7F5);
  static const Color splitDark = Color(0xFFD3BEEC);
  static const Color splitIcon = Color(0xFF8B5CF6);

  static const Color compress = Color(0xFFFFE3C4);
  static const Color compressDark = Color(0xFFFFD1A0);
  static const Color compressIcon = Color(0xFFF97316);

  static const Color imagePdf = Color(0xFFCDEDD0);
  static const Color imagePdfDark = Color(0xFFB8E4BC);
  static const Color imagePdfIcon = Color(0xFF22C55E);

  static const Color history = Color(0xFFC9F1E9);
  static const Color historyDark = Color(0xFFABE8DD);
  static const Color historyIcon = Color(0xFF14B8A6);
}

/// Landing screen — feature hub. Grows one tile per Phase-1 feature as each
/// lands (merge/split/compress/...).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tabIndex = 0;

  IconData _themeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode_outlined;
      case ThemeMode.dark:
        return Icons.dark_mode_outlined;
      case ThemeMode.system:
        return Icons.brightness_auto_outlined;
    }
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light theme';
      case ThemeMode.dark:
        return 'Dark theme';
      case ThemeMode.system:
        return 'System theme';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeMode themeMode = ref.watch(themeModeControllerProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
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
            _ToolsRecentsTabBar(
              index: _tabIndex,
              onChanged: (i) => setState(() => _tabIndex = i),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _tabIndex == 0 ? const _ToolsTab() : const _RecentsTab(),
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
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.seedColor,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.picture_as_pdf,
                  color: Colors.white,
                  size: 20,
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

class _ToolsRecentsTabBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const _ToolsRecentsTabBar({required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: _TabButton(
                label: 'Tools',
                selected: index == 0,
                onTap: () => onChanged(0),
              ),
            ),
            Expanded(
              child: _TabButton(
                label: 'Recents',
                selected: index == 1,
                onTap: () => onChanged(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? scheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _ToolsTab extends StatelessWidget {
  const _ToolsTab();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final int columns = constraints.maxWidth >= 600 ? 2 : 1;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: GridView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisExtent: 108,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
              ),
              children: [
                _FeatureRowCard(
                  icon: Icons.call_merge,
                  color: _FeatureColors.merge,
                  colorDark: _FeatureColors.mergeDark,
                  iconColor: _FeatureColors.mergeIcon,
                  title: 'Merge PDFs',
                  subtitle: 'Combine multiple documents',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MergeScreen()),
                  ),
                ),
                _FeatureRowCard(
                  icon: Icons.call_split,
                  color: _FeatureColors.split,
                  colorDark: _FeatureColors.splitDark,
                  iconColor: _FeatureColors.splitIcon,
                  title: 'Split PDF',
                  subtitle: 'Separate into pages or sections',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SplitScreen()),
                  ),
                ),
                _FeatureRowCard(
                  icon: Icons.compress,
                  color: _FeatureColors.compress,
                  colorDark: _FeatureColors.compressDark,
                  iconColor: _FeatureColors.compressIcon,
                  title: 'Compress PDF',
                  subtitle: 'Optimize file size for sharing',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CompressScreen()),
                  ),
                ),
                _FeatureRowCard(
                  icon: Icons.image_outlined,
                  color: _FeatureColors.imagePdf,
                  colorDark: _FeatureColors.imagePdfDark,
                  iconColor: _FeatureColors.imagePdfIcon,
                  title: 'Image ⇄ PDF',
                  subtitle: 'Convert between formats',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ImagePdfScreen()),
                  ),
                ),
                _FeatureRowCard(
                  icon: Icons.history,
                  color: _FeatureColors.history,
                  colorDark: _FeatureColors.historyDark,
                  iconColor: _FeatureColors.historyIcon,
                  title: 'View History',
                  subtitle: 'Access previously processed files',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
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
    // a neutral dark grey (muted, not the fully-saturated iconColor) —
    // with white text/icon and a plain black shadow (a colored glow reads
    // oddly on a dark background).
    const Color darkMuted = Color(0xFF2A2A30);
    final Color cardTop = isDark
        ? Color.lerp(iconColor, darkMuted, 0.55)!
        : color;
    final Color cardBottom = isDark
        ? Color.lerp(iconColor, darkMuted, 0.72)!
        : colorDark;
    final Color textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final Color badgeColor = isDark
        ? iconColor
        : Colors.white.withValues(alpha: 0.85);
    final Color badgeIconColor = isDark ? Colors.white : iconColor;
    final BoxShadow shadow = isDark
        ? BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          )
        : BoxShadow(
            color: iconColor.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 6),
          );

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
            boxShadow: [shadow],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // The reference mockup's glossy sheen — soft diagonal
                // light streaks over the flat gradient.
                Positioned.fill(
                  child: CustomPaint(painter: _DiagonalSheenPainter()),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(icon, color: badgeIconColor, size: 25),
                      ),
                      const SizedBox(width: 14),
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
                                fontSize: 17,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: TextStyle(
                                color: textColor.withValues(
                                  alpha: isDark ? 0.82 : 0.72,
                                ),
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
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
class _DiagonalSheenPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16;

    const double spacing = 30;
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
  bool shouldRepaint(covariant _DiagonalSheenPainter oldDelegate) => false;
}

class _RecentsTab extends ConsumerStatefulWidget {
  const _RecentsTab();

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

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(historyControllerProvider);
    final recent = state.files.take(8).toList();

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (recent.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No files yet — use a tool above to create your first one.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      children: [
        ...recent.map(
          (f) => Card(
            child: ListTile(
              leading: Icon(
                f.name.endsWith('.pdf')
                    ? Icons.picture_as_pdf
                    : f.name.endsWith('.zip')
                    ? Icons.folder_zip
                    : Icons.image,
              ),
              title: Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(_formatSize(f.sizeBytes)),
              trailing: IconButton(
                icon: const Icon(Icons.share),
                tooltip: 'Share',
                onPressed: () => SharePlus.instance.share(
                  ShareParams(files: [XFile(f.path)]),
                ),
              ),
              onTap: () => downloadFile(context, f.path),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const HistoryScreen())),
            child: const Text('View all in History'),
          ),
        ),
      ],
    );
  }
}
