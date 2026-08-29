import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/ads/ads_service.dart';
import 'core/locale/app_language.dart';
import 'core/locale/locale_controller.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_controller.dart';
import 'l10n/app_localizations.dart';
import 'presentation/home_screen.dart';
import 'presentation/language_picker_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Loads month/day names etc. for every locale, so Recents' timestamps
  // (DateFormat, see home_screen.dart's _formatDateTime) format correctly
  // in whichever of the 6 supported languages the user picks - without
  // this, DateFormat throws for any non-English locale on first use.
  await initializeDateFormatting();
  runApp(const ProviderScope(child: PuraPdfApp()));
  // Fire-and-forget: ad setup (GDPR/UK consent, the iOS tracking prompt,
  // then the Mobile Ads SDK itself) runs in the background instead of
  // gating the home screen's first frame on it. None of PuraPDF+'s actual
  // PDF features depend on ads being ready - a merge/split/etc. started
  // before this finishes just doesn't get an interstitial that one time
  // (InterstitialAdManager already handles "nothing preloaded yet"
  // gracefully). Previously this was awaited before runApp(), which meant
  // a stalled consent/tracking flow (no network on a first-ever launch,
  // a slow-to-respond ATT prompt, ...) held the entire app on a blank
  // launch screen.
  // Chained, not two separate unawaited calls: init() is what calls
  // appOpen.preload() (right at its end), so showIfReady() has to run
  // after init() actually gets there, or it'd find nothing preloaded yet
  // and skip the app-open ad for this launch every time.
  unawaited(
    AdsService.instance.init().then(
      (_) => AdsService.instance.appOpen.showIfReady(),
    ),
  );
}

class PuraPdfApp extends ConsumerWidget {
  const PuraPdfApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode themeMode = ref.watch(themeModeControllerProvider);
    // null means "not chosen yet" (see LocaleController) - MaterialApp's
    // own `locale` stays unset in that case so it falls back to matching
    // the device's locale for the picker screen's own directionality/
    // system strings, then the user's explicit pick takes over everywhere
    // after that.
    final Locale? locale = ref.watch(localeControllerProvider);

    return MaterialApp(
      title: 'PuraPDF+',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: [for (final l in supportedAppLanguages) l.locale],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: locale == null
          ? const LanguagePickerScreen()
          : const HomeScreen(),
    );
  }
}
