import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/locale/app_language.dart';
import '../../core/locale/locale_controller.dart';
import '../../l10n/app_localizations.dart';

/// App-bar icon showing the current language's flag — tap opens a dropdown
/// of every supported language, each shown by its own native name (not
/// translated into whatever's currently active, so it's always readable).
class LanguageSwitcherButton extends ConsumerWidget {
  const LanguageSwitcherButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Locale? current = ref.watch(localeControllerProvider);
    final AppLanguage active = appLanguageFor(
      current ?? Localizations.localeOf(context),
    );

    return PopupMenuButton<AppLanguage>(
      tooltip: AppLocalizations.of(context).languageTooltip,
      initialValue: active,
      onSelected: (language) =>
          ref.read(localeControllerProvider.notifier).setLocale(
            language.locale,
          ),
      itemBuilder: (context) => [
        for (final language in supportedAppLanguages)
          PopupMenuItem(
            value: language,
            child: Row(
              children: [
                Text(language.flag, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Text(language.nativeName),
                if (language.locale.languageCode == active.locale.languageCode) ...[
                  const Spacer(),
                  const Icon(Icons.check, size: 18),
                ],
              ],
            ),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(active.flag, style: const TextStyle(fontSize: 20)),
      ),
    );
  }
}
