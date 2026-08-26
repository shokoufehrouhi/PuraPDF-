import 'package:flutter/material.dart';

import 'features/compress/compress_screen.dart';
import 'features/history/history_screen.dart';
import 'features/image_pdf/image_pdf_screen.dart';
import 'features/merge/merge_screen.dart';
import 'features/split/split_screen.dart';
import 'shared_widgets/banner_ad_widget.dart';

/// Landing screen — feature hub. Grows one tile per Phase-1 feature as each
/// lands (merge/split/compress/...).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PuraPDF'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'History',
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const HistoryScreen())),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _FeatureTile(
            icon: Icons.call_merge,
            title: 'Merge PDF',
            subtitle: 'Combine multiple PDFs into one',
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const MergeScreen())),
          ),
          _FeatureTile(
            icon: Icons.call_split,
            title: 'Split PDF',
            subtitle: 'Break a PDF into page ranges or single pages',
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const SplitScreen())),
          ),
          _FeatureTile(
            icon: Icons.compress,
            title: 'Compress PDF',
            subtitle: 'Shrink a PDF at low/medium/high strength',
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const CompressScreen())),
          ),
          _FeatureTile(
            icon: Icons.image,
            title: 'Image ⇄ PDF',
            subtitle: 'Images to PDF, or PDF pages to PNG/JPG',
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ImagePdfScreen())),
          ),
          _FeatureTile(
            icon: Icons.history,
            title: 'History',
            subtitle: 'All files PuraPDF has generated on this device',
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const HistoryScreen())),
          ),
        ],
      ),
      bottomNavigationBar: const BannerAdWidget(),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
