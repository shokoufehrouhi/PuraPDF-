import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app is only published on Google Play so far — the iOS side of
/// `in_app_review` needs an App Store ID for [ReviewService.openStoreListing],
/// which doesn't exist yet. Widen this once the app is on the App Store.
bool get reviewSupported => defaultTargetPlatform == TargetPlatform.android;

/// Asks for a Play rating via the native in-app review sheet, at a moment
/// the user just got something done — after their [successesBeforePrompt]th
/// successful operation, then at most once every [daysBetweenPrompts] days.
///
/// Play applies its own quota on top of this and may silently not show the
/// sheet; there's no way to tell whether it appeared or what was rated, so
/// a "prompt" here only means we asked. Never gate this on a "do you like
/// the app?" question first — Play policy forbids that.
class ReviewService {
  ReviewService._();

  static final ReviewService instance = ReviewService._();

  static const int successesBeforePrompt = 3;
  static const int daysBetweenPrompts = 60;

  static const String _successCountKey = 'purapdf_review_success_count';
  static const String _lastPromptKey = 'purapdf_review_last_prompt_ms';

  final InAppReview _inAppReview = InAppReview.instance;

  /// Call once an operation has finished successfully. Fire-and-forget:
  /// it never throws, since a rating prompt is never worth breaking the
  /// result screen over.
  Future<void> recordSuccessfulOperation() async {
    if (!reviewSupported) return;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final int count = (prefs.getInt(_successCountKey) ?? 0) + 1;
      await prefs.setInt(_successCountKey, count);
      if (count < successesBeforePrompt) return;

      final int? lastPromptMs = prefs.getInt(_lastPromptKey);
      if (lastPromptMs != null) {
        final Duration sinceLast = DateTime.now().difference(
          DateTime.fromMillisecondsSinceEpoch(lastPromptMs),
        );
        if (sinceLast.inDays < daysBetweenPrompts) return;
      }

      if (!await _inAppReview.isAvailable()) return;
      await prefs.setInt(
        _lastPromptKey,
        DateTime.now().millisecondsSinceEpoch,
      );
      await _inAppReview.requestReview();
    } catch (_) {
      // Deliberately swallowed - see doc comment above.
    }
  }

  /// Opens the app's Play Store page, for an explicit "Rate this app" tap.
  /// Unlike [recordSuccessfulOperation] this isn't subject to Play's quota.
  Future<void> openStoreListing() async {
    if (!reviewSupported) return;
    try {
      await _inAppReview.openStoreListing();
    } catch (_) {
      // Nothing useful to show if the Play Store can't be opened.
    }
  }
}
