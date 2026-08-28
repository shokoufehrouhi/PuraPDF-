import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/ads/ads_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_controller.dart';
import 'presentation/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdsService.instance.init();
  runApp(const ProviderScope(child: PuraPdfApp()));
  // Fire-and-forget: shows the app-open ad once it's ready (or gives up
  // after a short timeout) without delaying the home screen's first frame.
  unawaited(AdsService.instance.appOpen.showIfReady());
}

class PuraPdfApp extends ConsumerWidget {
  const PuraPdfApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode themeMode = ref.watch(themeModeControllerProvider);
    return MaterialApp(
      title: 'PuraPDF+',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: const HomeScreen(),
    );
  }
}
