import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ads_support.dart';

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
  ///
  /// `main.dart` awaits this *before `runApp()`* (so a required consent
  /// form is never raced by ad init), which means a stall here — no
  /// network on a first-ever launch, a plugin channel hiccup, any native
  /// callback in the chain below just never firing — would keep the whole
  /// app on a blank screen forever. [timeout] is the hard ceiling on that:
  /// past it, assume no consent info and let `AdsService` decide from
  /// there rather than block app startup indefinitely for something the
  /// user isn't even looking at yet.
  Future<bool> gatherConsent({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final Completer<bool> completer = Completer<bool>();

    void resolveFromCurrentStatus() {
      if (completer.isCompleted) return;
      ConsentInformation.instance.canRequestAds().then((canRequest) {
        if (!completer.isCompleted) completer.complete(canRequest);
      });
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

    final bool canRequestAds = await completer.future.timeout(
      timeout,
      onTimeout: () => false,
    );
    unawaited(_refreshPrivacyOptionsRequired());
    return canRequestAds;
  }

  /// Whether the user's region requires a way to change or withdraw their
  /// consent later (EEA/UK/Switzerland). The home screen shows a "Privacy
  /// settings" button only while this is true - AdMob policy requires that
  /// entry point wherever the consent form can appear.
  final ValueNotifier<bool> privacyOptionsRequired = ValueNotifier<bool>(false);

  Future<void> _refreshPrivacyOptionsRequired() async {
    if (!adsSupported) return;
    try {
      final status = await ConsentInformation.instance
          .getPrivacyOptionsRequirementStatus();
      privacyOptionsRequired.value =
          status == PrivacyOptionsRequirementStatus.required;
    } catch (_) {
      // Leave the button hidden if the status can't be read.
    }
  }

  /// Re-opens the consent form so the user can change their choices.
  /// Never throws; a form error just means nothing is shown.
  Future<void> showPrivacyOptions() async {
    if (!adsSupported) return;
    try {
      await ConsentForm.showPrivacyOptionsForm((_) {});
    } catch (_) {
      // Nothing actionable to show the user here.
    }
  }
}
