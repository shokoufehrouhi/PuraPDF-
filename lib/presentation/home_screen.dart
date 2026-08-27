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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Your PDF toolkit — merge, split, compress, and convert, '
                  'all on-device.',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: GridView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    shrinkWrap: true,
                    // A max tile width (not a fixed column count) keeps each
                    // card a sensible, phone-sized tile — more columns
                    // appear as the window widens instead of the same 2
                    // tiles stretching huge.
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 152,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.92,
                        ),
                    children: [
                      _FeatureCard(
                        icon: Icons.call_merge,
                        color: scheme.primary,
                        title: 'Merge',
                        subtitle: 'Combine PDFs',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const MergeScreen(),
                          ),
                        ),
                      ),
                      _FeatureCard(
                        icon: Icons.call_split,
                        color: scheme.tertiary,
                        title: 'Split',
                        subtitle: 'Break into pages',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SplitScreen(),
                          ),
                        ),
                      ),
                      _FeatureCard(
                        icon: Icons.compress,
                        color: scheme.secondary,
                        title: 'Compress',
                        subtitle: 'Shrink file size',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CompressScreen(),
                          ),
                        ),
                      ),
                      _FeatureCard(
                        icon: Icons.image_outlined,
                        color: scheme.primary,
                        title: 'Image ⇄ PDF',
                        subtitle: 'Convert both ways',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ImagePdfScreen(),
                          ),
                        ),
                      ),
                      _FeatureCard(
                        icon: Icons.history,
                        color: scheme.tertiary,
                        title: 'History',
                        subtitle: 'Your generated files',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const HistoryScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
