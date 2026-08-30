import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fa.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fa'),
    Locale('tr'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'PuraPDF+'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Your PDF toolkit — merge, split, compress, and convert, all on-device.'**
  String get appTagline;

  /// No description provided for @categoryOrganize.
  ///
  /// In en, this message translates to:
  /// **'Organize'**
  String get categoryOrganize;

  /// No description provided for @categoryEditProtect.
  ///
  /// In en, this message translates to:
  /// **'Edit & Protect'**
  String get categoryEditProtect;

  /// No description provided for @recentsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Recents'**
  String get recentsTooltip;

  /// No description provided for @backToToolsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Back to tools'**
  String get backToToolsTooltip;

  /// No description provided for @themeLightTooltip.
  ///
  /// In en, this message translates to:
  /// **'Light theme'**
  String get themeLightTooltip;

  /// No description provided for @themeDarkTooltip.
  ///
  /// In en, this message translates to:
  /// **'Dark theme'**
  String get themeDarkTooltip;

  /// No description provided for @languageTooltip.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTooltip;

  /// No description provided for @featureMergeTitle.
  ///
  /// In en, this message translates to:
  /// **'Merge PDFs'**
  String get featureMergeTitle;

  /// No description provided for @featureMergeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Combine multiple documents'**
  String get featureMergeSubtitle;

  /// No description provided for @featureSplitTitle.
  ///
  /// In en, this message translates to:
  /// **'Split PDF'**
  String get featureSplitTitle;

  /// No description provided for @featureSplitSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Separate into pages or sections'**
  String get featureSplitSubtitle;

  /// No description provided for @featureCompressTitle.
  ///
  /// In en, this message translates to:
  /// **'Compress PDF'**
  String get featureCompressTitle;

  /// No description provided for @featureCompressSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optimize file size for sharing'**
  String get featureCompressSubtitle;

  /// No description provided for @featureImagePdfTitle.
  ///
  /// In en, this message translates to:
  /// **'Image ⇄ PDF'**
  String get featureImagePdfTitle;

  /// No description provided for @featureImagePdfSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Convert between formats'**
  String get featureImagePdfSubtitle;

  /// No description provided for @featurePdfWordTitle.
  ///
  /// In en, this message translates to:
  /// **'PDF ⇄ Word'**
  String get featurePdfWordTitle;

  /// No description provided for @featurePdfWordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Convert to and from Word'**
  String get featurePdfWordSubtitle;

  /// No description provided for @featureScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan Document'**
  String get featureScanTitle;

  /// No description provided for @featureScanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Capture paper documents with your camera'**
  String get featureScanSubtitle;

  /// No description provided for @featurePageEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Pages'**
  String get featurePageEditTitle;

  /// No description provided for @featurePageEditSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Rotate, reorder, or remove pages'**
  String get featurePageEditSubtitle;

  /// No description provided for @featureContentEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit PDF'**
  String get featureContentEditTitle;

  /// No description provided for @featureContentEditSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fix text, remove a line, add an image'**
  String get featureContentEditSubtitle;

  /// No description provided for @featureEncryptTitle.
  ///
  /// In en, this message translates to:
  /// **'Password Protect'**
  String get featureEncryptTitle;

  /// No description provided for @featureEncryptSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add or remove a PDF password'**
  String get featureEncryptSubtitle;

  /// No description provided for @featureWatermarkTitle.
  ///
  /// In en, this message translates to:
  /// **'Watermark'**
  String get featureWatermarkTitle;

  /// No description provided for @featureWatermarkSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stamp text across every page'**
  String get featureWatermarkSubtitle;

  /// No description provided for @featureSignatureTitle.
  ///
  /// In en, this message translates to:
  /// **'Digital Signature'**
  String get featureSignatureTitle;

  /// No description provided for @featureSignatureSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Draw or type a signature, place it, save'**
  String get featureSignatureSubtitle;

  /// No description provided for @recentsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No files yet'**
  String get recentsEmptyTitle;

  /// No description provided for @recentsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Files you create with Merge, Split, Compress, or Image ⇄ PDF will show up here.'**
  String get recentsEmptyBody;

  /// No description provided for @browseTools.
  ///
  /// In en, this message translates to:
  /// **'Browse tools'**
  String get browseTools;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @clearAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear all recents?'**
  String get clearAllTitle;

  /// No description provided for @clearAllBody.
  ///
  /// In en, this message translates to:
  /// **'This deletes every file listed here from your device. This cannot be undone.'**
  String get clearAllBody;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @clearAllConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAllConfirm;

  /// No description provided for @opUnknown.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get opUnknown;

  /// No description provided for @opMerge.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get opMerge;

  /// No description provided for @opSplit.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get opSplit;

  /// No description provided for @opCompress.
  ///
  /// In en, this message translates to:
  /// **'Compress'**
  String get opCompress;

  /// No description provided for @opImageToPdf.
  ///
  /// In en, this message translates to:
  /// **'Image → PDF'**
  String get opImageToPdf;

  /// No description provided for @opPdfToImage.
  ///
  /// In en, this message translates to:
  /// **'PDF → Image'**
  String get opPdfToImage;

  /// No description provided for @opScan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get opScan;

  /// No description provided for @opPageEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Pages'**
  String get opPageEdit;

  /// No description provided for @opContentEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit PDF'**
  String get opContentEdit;

  /// No description provided for @opRedact.
  ///
  /// In en, this message translates to:
  /// **'Redact'**
  String get opRedact;

  /// No description provided for @opFillSign.
  ///
  /// In en, this message translates to:
  /// **'Filled'**
  String get opFillSign;

  /// No description provided for @opLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get opLocked;

  /// No description provided for @opUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get opUnlocked;

  /// No description provided for @opWatermark.
  ///
  /// In en, this message translates to:
  /// **'Watermark'**
  String get opWatermark;

  /// No description provided for @opSigned.
  ///
  /// In en, this message translates to:
  /// **'Signed'**
  String get opSigned;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @startOver.
  ///
  /// In en, this message translates to:
  /// **'Start over'**
  String get startOver;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @selectAPdf.
  ///
  /// In en, this message translates to:
  /// **'Select a PDF'**
  String get selectAPdf;

  /// No description provided for @selectPdf.
  ///
  /// In en, this message translates to:
  /// **'Select PDF'**
  String get selectPdf;

  /// No description provided for @tapToBrowseFiles.
  ///
  /// In en, this message translates to:
  /// **'Tap to browse your files'**
  String get tapToBrowseFiles;

  /// No description provided for @tapToChangeFile.
  ///
  /// In en, this message translates to:
  /// **'Tap to change file'**
  String get tapToChangeFile;

  /// No description provided for @previousPage.
  ///
  /// In en, this message translates to:
  /// **'Previous page'**
  String get previousPage;

  /// No description provided for @nextPage.
  ///
  /// In en, this message translates to:
  /// **'Next page'**
  String get nextPage;

  /// No description provided for @downloadSavedToDownloads.
  ///
  /// In en, this message translates to:
  /// **'Saved to Downloads: {fileName}'**
  String downloadSavedToDownloads(Object fileName);

  /// No description provided for @downloadSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved: {fileName}'**
  String downloadSaved(Object fileName);

  /// No description provided for @downloadCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get downloadCancelled;

  /// No description provided for @downloadNoDirectory.
  ///
  /// In en, this message translates to:
  /// **'No Downloads directory available'**
  String get downloadNoDirectory;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @errorSelectPdfFirst.
  ///
  /// In en, this message translates to:
  /// **'Select a PDF first.'**
  String get errorSelectPdfFirst;

  /// No description provided for @errorEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter a password.'**
  String get errorEnterPassword;

  /// No description provided for @errorEnterPdfPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter the PDF\'s password.'**
  String get errorEnterPdfPassword;

  /// No description provided for @errorPasswordNoSpaces.
  ///
  /// In en, this message translates to:
  /// **'Password can\'t contain spaces.'**
  String get errorPasswordNoSpaces;

  /// No description provided for @errorPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least {minLength} characters.'**
  String errorPasswordTooShort(Object minLength);

  /// No description provided for @errorPasswordsDontMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords don\'t match.'**
  String get errorPasswordsDontMatch;

  /// No description provided for @errorAtLeastOnePageMustRemain.
  ///
  /// In en, this message translates to:
  /// **'At least one page must remain.'**
  String get errorAtLeastOnePageMustRemain;

  /// No description provided for @errorAtLeastOnePageMustRemainInPdf.
  ///
  /// In en, this message translates to:
  /// **'At least one page must remain in the PDF.'**
  String get errorAtLeastOnePageMustRemainInPdf;

  /// No description provided for @errorMakeAChangeBeforeSaving.
  ///
  /// In en, this message translates to:
  /// **'Make at least one change before saving.'**
  String get errorMakeAChangeBeforeSaving;

  /// No description provided for @errorMarkAtLeastOneLineToRedact.
  ///
  /// In en, this message translates to:
  /// **'Mark at least one line to redact.'**
  String get errorMarkAtLeastOneLineToRedact;

  /// No description provided for @errorFillAtLeastOneFieldFirst.
  ///
  /// In en, this message translates to:
  /// **'Fill in at least one field first.'**
  String get errorFillAtLeastOneFieldFirst;

  /// No description provided for @errorSelectAtLeastOneImage.
  ///
  /// In en, this message translates to:
  /// **'Select at least one image.'**
  String get errorSelectAtLeastOneImage;

  /// No description provided for @errorMergeNeedsTwoFiles.
  ///
  /// In en, this message translates to:
  /// **'Merge requires at least 2 PDF files.'**
  String get errorMergeNeedsTwoFiles;

  /// No description provided for @errorNewNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'New name cannot be empty.'**
  String get errorNewNameEmpty;

  /// No description provided for @errorScanAtLeastOnePage.
  ///
  /// In en, this message translates to:
  /// **'Scan at least one page.'**
  String get errorScanAtLeastOnePage;

  /// No description provided for @errorScanAtLeastOnePageFirst.
  ///
  /// In en, this message translates to:
  /// **'Scan at least one page first.'**
  String get errorScanAtLeastOnePageFirst;

  /// No description provided for @errorProvideAtLeastOneRange.
  ///
  /// In en, this message translates to:
  /// **'Provide at least one page range to split.'**
  String get errorProvideAtLeastOneRange;

  /// No description provided for @errorInvalidPageRange.
  ///
  /// In en, this message translates to:
  /// **'Invalid page range: {range}'**
  String errorInvalidPageRange(Object range);

  /// No description provided for @errorRangeExceedsPageCount.
  ///
  /// In en, this message translates to:
  /// **'Range {range} exceeds document page count ({pageCount}).'**
  String errorRangeExceedsPageCount(Object range, Object pageCount);

  /// No description provided for @errorEnterWatermarkText.
  ///
  /// In en, this message translates to:
  /// **'Enter watermark text.'**
  String get errorEnterWatermarkText;

  /// No description provided for @errorAddSignatureFirst.
  ///
  /// In en, this message translates to:
  /// **'Add a signature first.'**
  String get errorAddSignatureFirst;

  /// No description provided for @errorPageIndexOutOfRange.
  ///
  /// In en, this message translates to:
  /// **'Page index {index} out of range (0-{max}).'**
  String errorPageIndexOutOfRange(Object index, Object max);

  /// No description provided for @errorWrongPasswordOrNotProtected.
  ///
  /// In en, this message translates to:
  /// **'Wrong password, or this PDF isn\'t password-protected.'**
  String get errorWrongPasswordOrNotProtected;

  /// No description provided for @errorUnsupportedImageFormat.
  ///
  /// In en, this message translates to:
  /// **'This image format isn\'t supported. Try a JPEG or PNG instead.'**
  String get errorUnsupportedImageFormat;

  /// No description provided for @mergeTitle.
  ///
  /// In en, this message translates to:
  /// **'Merge PDFs'**
  String get mergeTitle;

  /// No description provided for @mergeDescription.
  ///
  /// In en, this message translates to:
  /// **'Combine multiple PDF files into a single document, in whatever order you like.'**
  String get mergeDescription;

  /// No description provided for @mergeStepAdd.
  ///
  /// In en, this message translates to:
  /// **'Add files'**
  String get mergeStepAdd;

  /// No description provided for @mergeStepReorder.
  ///
  /// In en, this message translates to:
  /// **'Reorder'**
  String get mergeStepReorder;

  /// No description provided for @mergeStepMerge.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get mergeStepMerge;

  /// No description provided for @mergeStepSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get mergeStepSave;

  /// No description provided for @mergeAddFiles.
  ///
  /// In en, this message translates to:
  /// **'Add PDF files'**
  String get mergeAddFiles;

  /// No description provided for @mergeAddFilesHint.
  ///
  /// In en, this message translates to:
  /// **'You can select multiple files at once'**
  String get mergeAddFilesHint;

  /// No description provided for @mergeFileCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 file} other{{count} files}} — drag to reorder'**
  String mergeFileCount(num count);

  /// No description provided for @addMore.
  ///
  /// In en, this message translates to:
  /// **'Add more'**
  String get addMore;

  /// No description provided for @mergeButtonNeedsMore.
  ///
  /// In en, this message translates to:
  /// **'Add at least 2 files to merge'**
  String get mergeButtonNeedsMore;

  /// No description provided for @mergeButtonReady.
  ///
  /// In en, this message translates to:
  /// **'Merge {count} files'**
  String mergeButtonReady(Object count);

  /// No description provided for @mergeSuccess.
  ///
  /// In en, this message translates to:
  /// **'Merged successfully'**
  String get mergeSuccess;

  /// No description provided for @splitTitle.
  ///
  /// In en, this message translates to:
  /// **'Split PDF'**
  String get splitTitle;

  /// No description provided for @splitDescription.
  ///
  /// In en, this message translates to:
  /// **'Break a PDF into separate files — by page or by custom ranges.'**
  String get splitDescription;

  /// No description provided for @splitStepSelect.
  ///
  /// In en, this message translates to:
  /// **'Select PDF'**
  String get splitStepSelect;

  /// No description provided for @splitStepChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose pages'**
  String get splitStepChoose;

  /// No description provided for @splitStepSplit.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get splitStepSplit;

  /// No description provided for @splitStepSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get splitStepSave;

  /// No description provided for @splitPageCountHint.
  ///
  /// In en, this message translates to:
  /// **'{count} pages — tap to change file'**
  String splitPageCountHint(Object count);

  /// No description provided for @splitOneFilePerPage.
  ///
  /// In en, this message translates to:
  /// **'Split into one file per page'**
  String get splitOneFilePerPage;

  /// No description provided for @splitPageRanges.
  ///
  /// In en, this message translates to:
  /// **'Page ranges'**
  String get splitPageRanges;

  /// No description provided for @splitPageRangesHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 1-3, 5, 7-9'**
  String get splitPageRangesHint;

  /// No description provided for @splitButton.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get splitButton;

  /// No description provided for @splitFilesCreated.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 file created} other{{count} files created}}'**
  String splitFilesCreated(num count);

  /// No description provided for @shareZip.
  ///
  /// In en, this message translates to:
  /// **'Share ZIP'**
  String get shareZip;

  /// No description provided for @downloadZip.
  ///
  /// In en, this message translates to:
  /// **'Download ZIP'**
  String get downloadZip;

  /// No description provided for @compressTitle.
  ///
  /// In en, this message translates to:
  /// **'Compress PDF'**
  String get compressTitle;

  /// No description provided for @compressDescription.
  ///
  /// In en, this message translates to:
  /// **'Shrink a PDF\'s file size for easier sharing, with three quality levels to choose from.'**
  String get compressDescription;

  /// No description provided for @compressStepSelect.
  ///
  /// In en, this message translates to:
  /// **'Select PDF'**
  String get compressStepSelect;

  /// No description provided for @compressStepLevel.
  ///
  /// In en, this message translates to:
  /// **'Pick level'**
  String get compressStepLevel;

  /// No description provided for @compressStepCompress.
  ///
  /// In en, this message translates to:
  /// **'Compress'**
  String get compressStepCompress;

  /// No description provided for @compressStepSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get compressStepSave;

  /// No description provided for @compressOriginalSizeHint.
  ///
  /// In en, this message translates to:
  /// **'Original size: {size} — tap to change file'**
  String compressOriginalSizeHint(Object size);

  /// No description provided for @compressLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get compressLow;

  /// No description provided for @compressMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get compressMedium;

  /// No description provided for @compressHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get compressHigh;

  /// No description provided for @compressHighWarning.
  ///
  /// In en, this message translates to:
  /// **'High rebuilds every page as an image — best size reduction for scans/photos, but the result loses selectable/searchable text. On text-heavy PDFs where that would backfire, it automatically falls back so the result is never bigger than the original.'**
  String get compressHighWarning;

  /// No description provided for @compressButton.
  ///
  /// In en, this message translates to:
  /// **'Compress'**
  String get compressButton;

  /// No description provided for @compressReductionPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% smaller'**
  String compressReductionPercent(Object percent);

  /// No description provided for @compressBeforeAfter.
  ///
  /// In en, this message translates to:
  /// **'Before: {before}  →  After: {after}'**
  String compressBeforeAfter(Object before, Object after);

  /// No description provided for @beforeLabel.
  ///
  /// In en, this message translates to:
  /// **'Before'**
  String get beforeLabel;

  /// No description provided for @afterLabel.
  ///
  /// In en, this message translates to:
  /// **'After'**
  String get afterLabel;

  /// No description provided for @imagePdfTitle.
  ///
  /// In en, this message translates to:
  /// **'Image ⇄ PDF'**
  String get imagePdfTitle;

  /// No description provided for @imagesToPdfDescription.
  ///
  /// In en, this message translates to:
  /// **'Turn one or more photos into a single PDF document.'**
  String get imagesToPdfDescription;

  /// No description provided for @pdfToImagesDescription.
  ///
  /// In en, this message translates to:
  /// **'Export every page of a PDF as a separate image file.'**
  String get pdfToImagesDescription;

  /// No description provided for @imagePdfStepAddImages.
  ///
  /// In en, this message translates to:
  /// **'Add images'**
  String get imagePdfStepAddImages;

  /// No description provided for @imagePdfStepConvert.
  ///
  /// In en, this message translates to:
  /// **'Convert'**
  String get imagePdfStepConvert;

  /// No description provided for @imagePdfStepSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get imagePdfStepSave;

  /// No description provided for @imagePdfStepSelect.
  ///
  /// In en, this message translates to:
  /// **'Select PDF'**
  String get imagePdfStepSelect;

  /// No description provided for @imagePdfStepFormat.
  ///
  /// In en, this message translates to:
  /// **'Pick format'**
  String get imagePdfStepFormat;

  /// No description provided for @imagesToPdfSegment.
  ///
  /// In en, this message translates to:
  /// **'Images → PDF'**
  String get imagesToPdfSegment;

  /// No description provided for @pdfToImagesSegment.
  ///
  /// In en, this message translates to:
  /// **'PDF → Images'**
  String get pdfToImagesSegment;

  /// No description provided for @imagesWord.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get imagesWord;

  /// No description provided for @pdfWordTitle.
  ///
  /// In en, this message translates to:
  /// **'PDF ⇄ Word'**
  String get pdfWordTitle;

  /// No description provided for @pdfToWordDescription.
  ///
  /// In en, this message translates to:
  /// **'Extract a PDF\'s text into an editable Word document.'**
  String get pdfToWordDescription;

  /// No description provided for @wordToPdfDescription.
  ///
  /// In en, this message translates to:
  /// **'Turn a Word document\'s text into a PDF.'**
  String get wordToPdfDescription;

  /// No description provided for @pdfWordStepSelect.
  ///
  /// In en, this message translates to:
  /// **'Select file'**
  String get pdfWordStepSelect;

  /// No description provided for @pdfWordStepConvert.
  ///
  /// In en, this message translates to:
  /// **'Convert'**
  String get pdfWordStepConvert;

  /// No description provided for @pdfWordStepSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get pdfWordStepSave;

  /// No description provided for @wordWord.
  ///
  /// In en, this message translates to:
  /// **'Word'**
  String get wordWord;

  /// No description provided for @selectAWordFile.
  ///
  /// In en, this message translates to:
  /// **'Select a Word file'**
  String get selectAWordFile;

  /// No description provided for @docCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Word document created successfully'**
  String get docCreatedSuccess;

  /// No description provided for @errorSelectWordFirst.
  ///
  /// In en, this message translates to:
  /// **'Select a Word file first.'**
  String get errorSelectWordFirst;

  /// No description provided for @errorPdfHasNoExtractableText.
  ///
  /// In en, this message translates to:
  /// **'This PDF has no text to extract.'**
  String get errorPdfHasNoExtractableText;

  /// No description provided for @errorWordHasNoExtractableText.
  ///
  /// In en, this message translates to:
  /// **'This Word document has no text to extract.'**
  String get errorWordHasNoExtractableText;

  /// No description provided for @addImages.
  ///
  /// In en, this message translates to:
  /// **'Add images'**
  String get addImages;

  /// No description provided for @addImagesHint.
  ///
  /// In en, this message translates to:
  /// **'You can select multiple photos at once'**
  String get addImagesHint;

  /// No description provided for @imagesSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 image selected} other{{count} images selected}}'**
  String imagesSelectedCount(num count);

  /// No description provided for @pdfCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'PDF created successfully'**
  String get pdfCreatedSuccess;

  /// No description provided for @convertButton.
  ///
  /// In en, this message translates to:
  /// **'Convert'**
  String get convertButton;

  /// No description provided for @convertButtonEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add images to convert'**
  String get convertButtonEmpty;

  /// No description provided for @convertButtonReady.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Convert 1 image} other{Convert {count} images}}'**
  String convertButtonReady(num count);

  /// No description provided for @imagesCreatedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 image created} other{{count} images created}}'**
  String imagesCreatedCount(num count);

  /// No description provided for @scanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan Document'**
  String get scanTitle;

  /// No description provided for @scanDescription.
  ///
  /// In en, this message translates to:
  /// **'Turn photos of paper documents into a clean PDF — edge detection and cropping happen automatically as you scan.'**
  String get scanDescription;

  /// No description provided for @scanStepScan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scanStepScan;

  /// No description provided for @scanStepReorder.
  ///
  /// In en, this message translates to:
  /// **'Reorder'**
  String get scanStepReorder;

  /// No description provided for @scanStepCreatePdf.
  ///
  /// In en, this message translates to:
  /// **'Create PDF'**
  String get scanStepCreatePdf;

  /// No description provided for @scanStepSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get scanStepSave;

  /// No description provided for @scanADocument.
  ///
  /// In en, this message translates to:
  /// **'Scan a document'**
  String get scanADocument;

  /// No description provided for @scanHint.
  ///
  /// In en, this message translates to:
  /// **'Uses your camera — edges are detected and cropped automatically'**
  String get scanHint;

  /// No description provided for @openingCamera.
  ///
  /// In en, this message translates to:
  /// **'Opening camera…'**
  String get openingCamera;

  /// No description provided for @scanMore.
  ///
  /// In en, this message translates to:
  /// **'Scan more'**
  String get scanMore;

  /// No description provided for @scanOcrToggleLabel.
  ///
  /// In en, this message translates to:
  /// **'Make text searchable'**
  String get scanOcrToggleLabel;

  /// No description provided for @scanOcrToggleHint.
  ///
  /// In en, this message translates to:
  /// **'On-device text recognition (Latin-script text only)'**
  String get scanOcrToggleHint;

  /// No description provided for @scanPageCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 page} other{{count} pages}} — drag to reorder'**
  String scanPageCount(num count);

  /// No description provided for @pageNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Page {number}'**
  String pageNumberLabel(Object number);

  /// No description provided for @createPdfButton.
  ///
  /// In en, this message translates to:
  /// **'Create PDF'**
  String get createPdfButton;

  /// No description provided for @createPdfButtonReady.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Create PDF from 1 page} other{Create PDF from {count} pages}}'**
  String createPdfButtonReady(num count);

  /// No description provided for @pageEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Pages'**
  String get pageEditTitle;

  /// No description provided for @pageEditDescription.
  ///
  /// In en, this message translates to:
  /// **'Rotate, reorder, or remove pages from a PDF — the rest of the document stays untouched.'**
  String get pageEditDescription;

  /// No description provided for @pageEditStepSelect.
  ///
  /// In en, this message translates to:
  /// **'Select PDF'**
  String get pageEditStepSelect;

  /// No description provided for @pageEditStepEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit pages'**
  String get pageEditStepEdit;

  /// No description provided for @pageEditStepSave.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get pageEditStepSave;

  /// No description provided for @rotate.
  ///
  /// In en, this message translates to:
  /// **'Rotate'**
  String get rotate;

  /// No description provided for @removePage.
  ///
  /// In en, this message translates to:
  /// **'Remove page'**
  String get removePage;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @pdfSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'PDF saved successfully'**
  String get pdfSavedSuccess;

  /// No description provided for @contentEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit PDF'**
  String get contentEditTitle;

  /// No description provided for @contentEditDescription.
  ///
  /// In en, this message translates to:
  /// **'Tap a line to fix or remove it, or drop in an image — edits cover the original spot rather than reflowing the page.'**
  String get contentEditDescription;

  /// No description provided for @contentEditStepSelect.
  ///
  /// In en, this message translates to:
  /// **'Select PDF'**
  String get contentEditStepSelect;

  /// No description provided for @contentEditStepEdit.
  ///
  /// In en, this message translates to:
  /// **'Tap to edit'**
  String get contentEditStepEdit;

  /// No description provided for @contentEditStepSave.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get contentEditStepSave;

  /// No description provided for @editLine.
  ///
  /// In en, this message translates to:
  /// **'Edit line'**
  String get editLine;

  /// No description provided for @lineText.
  ///
  /// In en, this message translates to:
  /// **'Line text'**
  String get lineText;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @addImageToPage.
  ///
  /// In en, this message translates to:
  /// **'Add image to this page'**
  String get addImageToPage;

  /// No description provided for @addImage.
  ///
  /// In en, this message translates to:
  /// **'Add image'**
  String get addImage;

  /// No description provided for @thisPdfHasNoPages.
  ///
  /// In en, this message translates to:
  /// **'This PDF has no pages.'**
  String get thisPdfHasNoPages;

  /// No description provided for @thisPdfHasNoFormFields.
  ///
  /// In en, this message translates to:
  /// **'This PDF has no fillable form fields.'**
  String get thisPdfHasNoFormFields;

  /// No description provided for @encryptTitle.
  ///
  /// In en, this message translates to:
  /// **'Password Protect'**
  String get encryptTitle;

  /// No description provided for @encryptDescription.
  ///
  /// In en, this message translates to:
  /// **'Lock a PDF with a password so only people who know it can open it.'**
  String get encryptDescription;

  /// No description provided for @addPasswordSegment.
  ///
  /// In en, this message translates to:
  /// **'Add Password'**
  String get addPasswordSegment;

  /// No description provided for @removePasswordSegment.
  ///
  /// In en, this message translates to:
  /// **'Remove Password'**
  String get removePasswordSegment;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @passwordHelperText.
  ///
  /// In en, this message translates to:
  /// **'At least {minLength} characters, no spaces'**
  String passwordHelperText(Object minLength);

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @lockButton.
  ///
  /// In en, this message translates to:
  /// **'Lock'**
  String get lockButton;

  /// No description provided for @unlockButton.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlockButton;

  /// No description provided for @passwordAdded.
  ///
  /// In en, this message translates to:
  /// **'Password added'**
  String get passwordAdded;

  /// No description provided for @passwordRemoved.
  ///
  /// In en, this message translates to:
  /// **'Password removed'**
  String get passwordRemoved;

  /// No description provided for @watermarkTitle.
  ///
  /// In en, this message translates to:
  /// **'Watermark'**
  String get watermarkTitle;

  /// No description provided for @watermarkDescription.
  ///
  /// In en, this message translates to:
  /// **'Stamp text diagonally across every page — great for \"DRAFT\", \"CONFIDENTIAL\", or a company name.'**
  String get watermarkDescription;

  /// No description provided for @watermarkStepSelect.
  ///
  /// In en, this message translates to:
  /// **'Select PDF'**
  String get watermarkStepSelect;

  /// No description provided for @watermarkStepText.
  ///
  /// In en, this message translates to:
  /// **'Set text'**
  String get watermarkStepText;

  /// No description provided for @watermarkStepStamp.
  ///
  /// In en, this message translates to:
  /// **'Stamp'**
  String get watermarkStepStamp;

  /// No description provided for @watermarkStepSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get watermarkStepSave;

  /// No description provided for @watermarkText.
  ///
  /// In en, this message translates to:
  /// **'Watermark text'**
  String get watermarkText;

  /// No description provided for @watermarkTextHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. CONFIDENTIAL'**
  String get watermarkTextHint;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @opacityPercent.
  ///
  /// In en, this message translates to:
  /// **'Opacity: {percent}%'**
  String opacityPercent(Object percent);

  /// No description provided for @sizeValue.
  ///
  /// In en, this message translates to:
  /// **'Size: {size}'**
  String sizeValue(Object size);

  /// No description provided for @watermarkButton.
  ///
  /// In en, this message translates to:
  /// **'Stamp'**
  String get watermarkButton;

  /// No description provided for @watermarkAdded.
  ///
  /// In en, this message translates to:
  /// **'Watermark added'**
  String get watermarkAdded;

  /// No description provided for @signatureTitle.
  ///
  /// In en, this message translates to:
  /// **'Digital Signature'**
  String get signatureTitle;

  /// No description provided for @signatureDescription.
  ///
  /// In en, this message translates to:
  /// **'Draw or type a signature, place it on any page, and save.'**
  String get signatureDescription;

  /// No description provided for @signatureStepSelect.
  ///
  /// In en, this message translates to:
  /// **'Select PDF'**
  String get signatureStepSelect;

  /// No description provided for @signatureStepCreate.
  ///
  /// In en, this message translates to:
  /// **'Set signature'**
  String get signatureStepCreate;

  /// No description provided for @signatureStepPlace.
  ///
  /// In en, this message translates to:
  /// **'Place'**
  String get signatureStepPlace;

  /// No description provided for @signatureStepSave.
  ///
  /// In en, this message translates to:
  /// **'Save signed PDF'**
  String get signatureStepSave;

  /// No description provided for @addSignature.
  ///
  /// In en, this message translates to:
  /// **'Add Signature'**
  String get addSignature;

  /// No description provided for @changeSignature.
  ///
  /// In en, this message translates to:
  /// **'Change Signature'**
  String get changeSignature;

  /// No description provided for @placeButton.
  ///
  /// In en, this message translates to:
  /// **'Place'**
  String get placeButton;

  /// No description provided for @signButton.
  ///
  /// In en, this message translates to:
  /// **'Sign'**
  String get signButton;

  /// No description provided for @pdfSignedSuccess.
  ///
  /// In en, this message translates to:
  /// **'PDF signed successfully'**
  String get pdfSignedSuccess;

  /// No description provided for @signaturePadDraw.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get signaturePadDraw;

  /// No description provided for @signaturePadType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get signaturePadType;

  /// No description provided for @signaturePadCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Signature'**
  String get signaturePadCreateTitle;

  /// No description provided for @signaturePadDrawHint.
  ///
  /// In en, this message translates to:
  /// **'Sign with your finger or mouse'**
  String get signaturePadDrawHint;

  /// No description provided for @signaturePadClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get signaturePadClear;

  /// No description provided for @signaturePadColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get signaturePadColor;

  /// No description provided for @signaturePadStyle.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get signaturePadStyle;

  /// No description provided for @signaturePadYourName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get signaturePadYourName;

  /// No description provided for @signaturePadTypeYourName.
  ///
  /// In en, this message translates to:
  /// **'Type your name'**
  String get signaturePadTypeYourName;

  /// No description provided for @signaturePadDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get signaturePadDone;

  /// No description provided for @signaturePadFontCasual.
  ///
  /// In en, this message translates to:
  /// **'Casual'**
  String get signaturePadFontCasual;

  /// No description provided for @signaturePadFontElegant.
  ///
  /// In en, this message translates to:
  /// **'Elegant'**
  String get signaturePadFontElegant;

  /// No description provided for @signaturePadFontBold.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get signaturePadFontBold;

  /// No description provided for @colorBlack.
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get colorBlack;

  /// No description provided for @colorBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get colorBlue;

  /// No description provided for @colorRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get colorRed;

  /// No description provided for @colorGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get colorGreen;

  /// No description provided for @languagePickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get languagePickerTitle;

  /// No description provided for @languagePickerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can change this later from the home screen.'**
  String get languagePickerSubtitle;

  /// No description provided for @languagePickerContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get languagePickerContinue;

  /// No description provided for @changeFile.
  ///
  /// In en, this message translates to:
  /// **'Change file'**
  String get changeFile;

  /// No description provided for @pageOfTotal.
  ///
  /// In en, this message translates to:
  /// **'Page {current} of {total}'**
  String pageOfTotal(Object current, Object total);

  /// No description provided for @encryptRemoveDescription.
  ///
  /// In en, this message translates to:
  /// **'Remove a PDF\'s password, given the correct one.'**
  String get encryptRemoveDescription;

  /// No description provided for @encryptStepSetPassword.
  ///
  /// In en, this message translates to:
  /// **'Set password'**
  String get encryptStepSetPassword;

  /// No description provided for @encryptStepEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get encryptStepEnterPassword;

  /// No description provided for @featureRedactTitle.
  ///
  /// In en, this message translates to:
  /// **'Redact'**
  String get featureRedactTitle;

  /// No description provided for @featureRedactSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently remove sensitive text'**
  String get featureRedactSubtitle;

  /// No description provided for @redactDescription.
  ///
  /// In en, this message translates to:
  /// **'Tap the lines you want to permanently remove, then confirm — unlike Edit PDF\'s cover-only fix, redacted text can\'t be recovered or copied.'**
  String get redactDescription;

  /// No description provided for @redactStepSelect.
  ///
  /// In en, this message translates to:
  /// **'Select PDF'**
  String get redactStepSelect;

  /// No description provided for @redactStepMark.
  ///
  /// In en, this message translates to:
  /// **'Tap to mark'**
  String get redactStepMark;

  /// No description provided for @redactStepConfirm.
  ///
  /// In en, this message translates to:
  /// **'Redact permanently'**
  String get redactStepConfirm;

  /// No description provided for @redactMarkedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} marked for redaction'**
  String redactMarkedCount(Object count);

  /// No description provided for @redactConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Redact permanently?'**
  String get redactConfirmTitle;

  /// No description provided for @redactConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This can\'t be undone. The marked text will be completely removed from the PDF, not just covered.'**
  String get redactConfirmBody;

  /// No description provided for @redactConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Redact'**
  String get redactConfirmAction;

  /// No description provided for @redactButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Redact ({count})'**
  String redactButtonLabel(Object count);

  /// No description provided for @featureFillSignTitle.
  ///
  /// In en, this message translates to:
  /// **'Fill & Sign'**
  String get featureFillSignTitle;

  /// No description provided for @featureFillSignSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fill in real form fields'**
  String get featureFillSignSubtitle;

  /// No description provided for @fillSignDescription.
  ///
  /// In en, this message translates to:
  /// **'Tap a form\'s actual text fields and checkboxes to fill them in, then save — the filled values are permanently flattened into the page, not left as a separate editable layer.'**
  String get fillSignDescription;

  /// No description provided for @fillSignStepSelect.
  ///
  /// In en, this message translates to:
  /// **'Select PDF'**
  String get fillSignStepSelect;

  /// No description provided for @fillSignStepFill.
  ///
  /// In en, this message translates to:
  /// **'Tap to fill'**
  String get fillSignStepFill;

  /// No description provided for @fillSignStepConfirm.
  ///
  /// In en, this message translates to:
  /// **'Save permanently'**
  String get fillSignStepConfirm;

  /// No description provided for @fillSignButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Fill & Sign ({count})'**
  String fillSignButtonLabel(Object count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'de',
    'en',
    'es',
    'fa',
    'tr',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fa':
      return AppLocalizationsFa();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
