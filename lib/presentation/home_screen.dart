import 'package:flutter/material.dart';

/// Temporary landing screen for Phase 0.
/// Will be replaced by the real feature hub (merge/split/compress/...) in Phase 1.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PuraPDF')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Phase 0 scaffold ready.\nFeatures land in Phase 1.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
