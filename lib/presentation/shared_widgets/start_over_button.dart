import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Replaces a feature's primary action button once it has produced a
/// result. Leaving the original action re-clickable there would just redo
/// the same work on the same input — this instead clears the feature's
/// state (via the controller's `reset()`) so the next tap starts over from
/// an empty screen.
class StartOverButton extends StatelessWidget {
  final Color color;
  final VoidCallback onPressed;

  const StartOverButton({
    super.key,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.5)),
        ),
        icon: const Icon(Icons.refresh),
        label: Text(AppLocalizations.of(context).startOver),
        onPressed: onPressed,
      ),
    );
  }
}
