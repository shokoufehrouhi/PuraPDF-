import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/theme_mode_controller.dart';
import 'features/compress/compress_screen.dart';
import 'features/history/history_screen.dart';
import 'features/image_pdf/image_pdf_screen.dart';
import 'features/merge/merge_screen.dart';
import 'features/split/split_screen.dart';
import 'shared_widgets/banner_ad_widget.dart';

/// Landing screen — feature hub. Grows one tile per Phase-1 feature as each
/// lands (merge/split/compress/...).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

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
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode themeMode = ref.watch(themeModeControllerProvider);
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PuraPDF+'),
        actions: [
          IconButton(
            icon: Icon(_themeIcon(themeMode)),
            tooltip: '${_themeLabel(themeMode)} — tap to change',
            onPressed: () =>
                ref.read(themeModeControllerProvider.notifier).cycle(),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'History',
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const HistoryScreen())),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final int columns = constraints.maxWidth >= 640 ? 3 : 2;
            return GridView.count(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              crossAxisCount: columns,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.05,
              children: [
                _FeatureCard(
                  icon: Icons.call_merge,
                  color: scheme.primary,
                  title: 'Merge',
                  subtitle: 'Combine PDFs',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MergeScreen()),
                  ),
                ),
                _FeatureCard(
                  icon: Icons.call_split,
                  color: scheme.tertiary,
                  title: 'Split',
                  subtitle: 'Break into pages',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SplitScreen()),
                  ),
                ),
                _FeatureCard(
                  icon: Icons.compress,
                  color: scheme.secondary,
                  title: 'Compress',
                  subtitle: 'Shrink file size',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CompressScreen()),
                  ),
                ),
                _FeatureCard(
                  icon: Icons.image_outlined,
                  color: scheme.primary,
                  title: 'Image ⇄ PDF',
                  subtitle: 'Convert both ways',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ImagePdfScreen()),
                  ),
                ),
                _FeatureCard(
                  icon: Icons.history,
                  color: scheme.tertiary,
                  title: 'History',
                  subtitle: 'Your generated files',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: const BannerAdWidget(),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
