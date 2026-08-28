import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

/// GDPR/UK-DPA consent (Google's User Messaging Platform). Required by
/// AdMob policy before requesting ads for users in the EEA, UK, and
/// Switzerland — Google can restrict ad serving on an app that skips this.
/// No-ops (resolves immediately) for everyone else since
/// [ConsentInformation.requestConsentInfoUpdate] itself determines whether
/// the region needs it.
class ConsentService {
  ConsentService._();
  static final ConsentService instance = ConsentService._();

  /// Runs the UMP flow (requests consent info, loads + shows the form only
  /// if the user's region requires it) and resolves once it's safe to know
  /// whether ads can be requested this session. Never throws — a failed
  /// consent-info update (e.g. no network) falls back to whatever
  /// [ConsentInformation.canRequestAds] already knows from a prior session.
  Future<bool> gatherConsent() async {
    final Completer<bool> completer = Completer<bool>();

    void resolveFromCurrentStatus() {
      if (completer.isCompleted) return;
      ConsentInformation.instance.canRequestAds().then(completer.complete);
    }

    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () {
        ConsentForm.loadAndShowConsentFormIfRequired((_) {
          // formError (if any) isn't actionable here — canRequestAds()
          // below is the source of truth either way.
          resolveFromCurrentStatus();
        });
      },
      (_) => resolveFromCurrentStatus(),
    );

    return completer.future;
  }
}
