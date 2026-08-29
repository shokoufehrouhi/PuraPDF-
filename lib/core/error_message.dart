import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';

/// Turns a caught error into a *localization key* — never raw text — safe
/// to store in a feature controller's `state.error` (a plain `String?`,
/// with no `BuildContext` available at controller-catch-time to resolve
/// it there) and only turned into real, localized text later by
/// [localizedError] in the screen that actually displays it.
///
/// Our own domain/usecase validation throws `ArgumentError` whose message
/// IS already one of these keys (see `domain/usecases/*.dart`) — passed
/// through as-is. Left as `e.toString()` it would come out prefixed with
/// Dart's own "Invalid argument(s): ", on top of not being a key at all.
///
/// Anything else — a `FileSystemException`, a `PlatformException` from a
/// plugin, a Syncfusion parse failure on a malformed PDF, disk-full, and so
/// on — is not something a user should have to parse, so it falls back to
/// the generic key instead of raw exception text.
String friendlyErrorMessage(Object error) {
  if (error is ArgumentError && error.message is String) {
    return error.message as String;
  }
  return 'errorGeneric';
}

/// Resolves a `state.error` value (a key from [friendlyErrorMessage] or set
/// directly by a controller, e.g. `EncryptController.setPassword`) into
/// localized text for display. A handful of keys carry one dynamic value
/// encoded as `key:value` (there's no `BuildContext` in a controller to
/// build the full `AppLocalizations` call with, so the raw value travels
/// alongside the key instead) — decoded here, where context is available.
/// Anything not recognized is shown as-is, so a key nobody's wired up yet
/// degrades to plain (English) text instead of disappearing.
String localizedError(BuildContext context, String value) {
  final l10n = AppLocalizations.of(context);
  final int colon = value.indexOf(':');
  final String key = colon == -1 ? value : value.substring(0, colon);
  final String arg = colon == -1 ? '' : value.substring(colon + 1);

  switch (key) {
    case 'errorGeneric':
      return l10n.errorGeneric;
    case 'errorSelectPdfFirst':
      return l10n.errorSelectPdfFirst;
    case 'errorEnterPassword':
      return l10n.errorEnterPassword;
    case 'errorEnterPdfPassword':
      return l10n.errorEnterPdfPassword;
    case 'errorPasswordNoSpaces':
      return l10n.errorPasswordNoSpaces;
    case 'errorPasswordTooShort':
      return l10n.errorPasswordTooShort(int.tryParse(arg) ?? 0);
    case 'errorPasswordsDontMatch':
      return l10n.errorPasswordsDontMatch;
    case 'errorAtLeastOnePageMustRemain':
      return l10n.errorAtLeastOnePageMustRemain;
    case 'errorAtLeastOnePageMustRemainInPdf':
      return l10n.errorAtLeastOnePageMustRemainInPdf;
    case 'errorMakeAChangeBeforeSaving':
      return l10n.errorMakeAChangeBeforeSaving;
    case 'errorSelectAtLeastOneImage':
      return l10n.errorSelectAtLeastOneImage;
    case 'errorMergeNeedsTwoFiles':
      return l10n.errorMergeNeedsTwoFiles;
    case 'errorNewNameEmpty':
      return l10n.errorNewNameEmpty;
    case 'errorScanAtLeastOnePage':
      return l10n.errorScanAtLeastOnePage;
    case 'errorScanAtLeastOnePageFirst':
      return l10n.errorScanAtLeastOnePageFirst;
    case 'errorProvideAtLeastOneRange':
      return l10n.errorProvideAtLeastOneRange;
    case 'errorInvalidPageRange':
      return l10n.errorInvalidPageRange(arg);
    case 'errorEnterWatermarkText':
      return l10n.errorEnterWatermarkText;
    case 'errorAddSignatureFirst':
      return l10n.errorAddSignatureFirst;
    case 'errorWrongPasswordOrNotProtected':
      return l10n.errorWrongPasswordOrNotProtected;
    case 'errorUnsupportedImageFormat':
      return l10n.errorUnsupportedImageFormat;
    default:
      return value;
  }
}
