/// Sentry DSN for this app's crash/error reporting project.
///
/// This value is NOT a secret - a Sentry DSN is meant to be embedded in a
/// client app (same as a Firebase project's `google-services.json`). The
/// worst a leaked DSN allows is someone spamming fake events into this
/// project's dashboard, not reading anything back out of it.
///
/// To get one: sign in at https://sentry.io -> create a Flutter project ->
/// Settings -> Client Keys (DSN) -> copy the DSN URL and paste it below.
///
/// Left empty makes `SentryFlutter.init()` treat it as "reporting disabled"
/// (logs one warning, then is a safe no-op) rather than throwing.
///
/// Project: "purapdf" under the "pura-65" org (EU data region), created
/// 2026-09-01. See https://pura-65.sentry.io/projects/purapdf/ for the
/// dashboard (crash/error list, filterable by device model/OS/app version).
const String sentryDsn =
    'https://a689c44fae27904f3d7420cfade69953@o4512011101929472.ingest.de.sentry.io/4512011107565648';
