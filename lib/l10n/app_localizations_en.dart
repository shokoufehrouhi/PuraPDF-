// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'PuraPDF+';

  @override
  String get appTagline =>
      'Your PDF toolkit — merge, split, compress, and convert, all on-device.';

  @override
  String get categoryOrganize => 'Organize';

  @override
  String get categoryEditProtect => 'Edit & Protect';

  @override
  String get recentsTooltip => 'Recents';

  @override
  String get backToToolsTooltip => 'Back to tools';

  @override
  String get themeLightTooltip => 'Light theme';

  @override
  String get themeDarkTooltip => 'Dark theme';

  @override
  String get languageTooltip => 'Language';

  @override
  String get featureMergeTitle => 'Merge PDFs';

  @override
  String get featureMergeSubtitle => 'Combine multiple documents';

  @override
  String get featureSplitTitle => 'Split PDF';

  @override
  String get featureSplitSubtitle => 'Separate into pages or sections';

  @override
  String get featureCompressTitle => 'Compress PDF';

  @override
  String get featureCompressSubtitle => 'Optimize file size for sharing';

  @override
  String get featureImagePdfTitle => 'Image ⇄ PDF';

  @override
  String get featureImagePdfSubtitle => 'Convert between formats';

  @override
  String get featureScanTitle => 'Scan Document';

  @override
  String get featureScanSubtitle => 'Capture paper documents with your camera';

  @override
  String get featurePageEditTitle => 'Edit Pages';

  @override
  String get featurePageEditSubtitle => 'Rotate, reorder, or remove pages';

  @override
  String get featureContentEditTitle => 'Edit PDF';

  @override
  String get featureContentEditSubtitle =>
      'Fix text, remove a line, add an image';

  @override
  String get featureEncryptTitle => 'Password Protect';

  @override
  String get featureEncryptSubtitle => 'Add or remove a PDF password';

  @override
  String get featureWatermarkTitle => 'Watermark';

  @override
  String get featureWatermarkSubtitle => 'Stamp text across every page';

  @override
  String get featureSignatureTitle => 'Digital Signature';

  @override
  String get featureSignatureSubtitle =>
      'Draw or type a signature, place it, save';

  @override
  String get recentsEmptyTitle => 'No files yet';

  @override
  String get recentsEmptyBody =>
      'Files you create with Merge, Split, Compress, or Image ⇄ PDF will show up here.';

  @override
  String get browseTools => 'Browse tools';

  @override
  String get clear => 'Clear';

  @override
  String get clearAllTitle => 'Clear all recents?';

  @override
  String get clearAllBody =>
      'This deletes every file listed here from your device. This cannot be undone.';

  @override
  String get cancel => 'Cancel';

  @override
  String get clearAllConfirm => 'Clear all';

  @override
  String get opUnknown => 'File';

  @override
  String get opMerge => 'Merge';

  @override
  String get opSplit => 'Split';

  @override
  String get opCompress => 'Compress';

  @override
  String get opImageToPdf => 'Image → PDF';

  @override
  String get opPdfToImage => 'PDF → Image';

  @override
  String get opScan => 'Scan';

  @override
  String get opPageEdit => 'Edit Pages';

  @override
  String get opContentEdit => 'Edit PDF';

  @override
  String get opLocked => 'Locked';

  @override
  String get opUnlocked => 'Unlocked';

  @override
  String get opWatermark => 'Watermark';

  @override
  String get opSigned => 'Signed';

  @override
  String get share => 'Share';

  @override
  String get download => 'Download';

  @override
  String get startOver => 'Start over';

  @override
  String get save => 'Save';

  @override
  String get remove => 'Remove';

  @override
  String get selectAPdf => 'Select a PDF';

  @override
  String get selectPdf => 'Select PDF';

  @override
  String get tapToBrowseFiles => 'Tap to browse your files';

  @override
  String get tapToChangeFile => 'Tap to change file';

  @override
  String get previousPage => 'Previous page';

  @override
  String get nextPage => 'Next page';

  @override
  String downloadSavedToDownloads(Object fileName) {
    return 'Saved to Downloads: $fileName';
  }

  @override
  String downloadSaved(Object fileName) {
    return 'Saved: $fileName';
  }

  @override
  String get downloadCancelled => 'Cancelled';

  @override
  String get downloadNoDirectory => 'No Downloads directory available';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorSelectPdfFirst => 'Select a PDF first.';

  @override
  String get errorEnterPassword => 'Enter a password.';

  @override
  String get errorEnterPdfPassword => 'Enter the PDF\'s password.';

  @override
  String get errorPasswordNoSpaces => 'Password can\'t contain spaces.';

  @override
  String errorPasswordTooShort(Object minLength) {
    return 'Password must be at least $minLength characters.';
  }

  @override
  String get errorPasswordsDontMatch => 'Passwords don\'t match.';

  @override
  String get errorAtLeastOnePageMustRemain => 'At least one page must remain.';

  @override
  String get errorAtLeastOnePageMustRemainInPdf =>
      'At least one page must remain in the PDF.';

  @override
  String get errorMakeAChangeBeforeSaving =>
      'Make at least one change before saving.';

  @override
  String get errorSelectAtLeastOneImage => 'Select at least one image.';

  @override
  String get errorMergeNeedsTwoFiles => 'Merge requires at least 2 PDF files.';

  @override
  String get errorNewNameEmpty => 'New name cannot be empty.';

  @override
  String get errorScanAtLeastOnePage => 'Scan at least one page.';

  @override
  String get errorScanAtLeastOnePageFirst => 'Scan at least one page first.';

  @override
  String get errorProvideAtLeastOneRange =>
      'Provide at least one page range to split.';

  @override
  String errorInvalidPageRange(Object range) {
    return 'Invalid page range: $range';
  }

  @override
  String errorRangeExceedsPageCount(Object range, Object pageCount) {
    return 'Range $range exceeds document page count ($pageCount).';
  }

  @override
  String get errorEnterWatermarkText => 'Enter watermark text.';

  @override
  String get errorAddSignatureFirst => 'Add a signature first.';

  @override
  String errorPageIndexOutOfRange(Object index, Object max) {
    return 'Page index $index out of range (0-$max).';
  }

  @override
  String get errorWrongPasswordOrNotProtected =>
      'Wrong password, or this PDF isn\'t password-protected.';

  @override
  String get errorUnsupportedImageFormat =>
      'This image format isn\'t supported. Try a JPEG or PNG instead.';

  @override
  String get mergeTitle => 'Merge PDFs';

  @override
  String get mergeDescription =>
      'Combine multiple PDF files into a single document, in whatever order you like.';

  @override
  String get mergeStepAdd => 'Add files';

  @override
  String get mergeStepReorder => 'Reorder';

  @override
  String get mergeStepMerge => 'Merge';

  @override
  String get mergeStepSave => 'Save';

  @override
  String get mergeAddFiles => 'Add PDF files';

  @override
  String get mergeAddFilesHint => 'You can select multiple files at once';

  @override
  String mergeFileCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
    );
    return '$_temp0 — drag to reorder';
  }

  @override
  String get addMore => 'Add more';

  @override
  String get mergeButtonNeedsMore => 'Add at least 2 files to merge';

  @override
  String mergeButtonReady(Object count) {
    return 'Merge $count files';
  }

  @override
  String get mergeSuccess => 'Merged successfully';

  @override
  String get splitTitle => 'Split PDF';

  @override
  String get splitDescription =>
      'Break a PDF into separate files — by page or by custom ranges.';

  @override
  String get splitStepSelect => 'Select PDF';

  @override
  String get splitStepChoose => 'Choose pages';

  @override
  String get splitStepSplit => 'Split';

  @override
  String get splitStepSave => 'Save';

  @override
  String splitPageCountHint(Object count) {
    return '$count pages — tap to change file';
  }

  @override
  String get splitOneFilePerPage => 'Split into one file per page';

  @override
  String get splitPageRanges => 'Page ranges';

  @override
  String get splitPageRangesHint => 'e.g. 1-3, 5, 7-9';

  @override
  String get splitButton => 'Split';

  @override
  String splitFilesCreated(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files created',
      one: '1 file created',
    );
    return '$_temp0';
  }

  @override
  String get shareZip => 'Share ZIP';

  @override
  String get downloadZip => 'Download ZIP';

  @override
  String get compressTitle => 'Compress PDF';

  @override
  String get compressDescription =>
      'Shrink a PDF\'s file size for easier sharing, with three quality levels to choose from.';

  @override
  String get compressStepSelect => 'Select PDF';

  @override
  String get compressStepLevel => 'Pick level';

  @override
  String get compressStepCompress => 'Compress';

  @override
  String get compressStepSave => 'Save';

  @override
  String compressOriginalSizeHint(Object size) {
    return 'Original size: $size — tap to change file';
  }

  @override
  String get compressLow => 'Low';

  @override
  String get compressMedium => 'Medium';

  @override
  String get compressHigh => 'High';

  @override
  String get compressHighWarning =>
      'High rebuilds every page as an image — best size reduction for scans/photos, but the result loses selectable/searchable text. On text-heavy PDFs where that would backfire, it automatically falls back so the result is never bigger than the original.';

  @override
  String get compressButton => 'Compress';

  @override
  String compressReductionPercent(Object percent) {
    return '$percent% smaller';
  }

  @override
  String compressBeforeAfter(Object before, Object after) {
    return 'Before: $before  →  After: $after';
  }

  @override
  String get imagePdfTitle => 'Image ⇄ PDF';

  @override
  String get imagesToPdfDescription =>
      'Turn one or more photos into a single PDF document.';

  @override
  String get pdfToImagesDescription =>
      'Export every page of a PDF as a separate image file.';

  @override
  String get imagePdfStepAddImages => 'Add images';

  @override
  String get imagePdfStepConvert => 'Convert';

  @override
  String get imagePdfStepSave => 'Save';

  @override
  String get imagePdfStepSelect => 'Select PDF';

  @override
  String get imagePdfStepFormat => 'Pick format';

  @override
  String get imagesToPdfSegment => 'Images → PDF';

  @override
  String get pdfToImagesSegment => 'PDF → Images';

  @override
  String get addImages => 'Add images';

  @override
  String get addImagesHint => 'You can select multiple photos at once';

  @override
  String imagesSelectedCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count images selected',
      one: '1 image selected',
    );
    return '$_temp0';
  }

  @override
  String get pdfCreatedSuccess => 'PDF created successfully';

  @override
  String get convertButton => 'Convert';

  @override
  String get convertButtonEmpty => 'Add images to convert';

  @override
  String convertButtonReady(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Convert $count images',
      one: 'Convert 1 image',
    );
    return '$_temp0';
  }

  @override
  String imagesCreatedCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count images created',
      one: '1 image created',
    );
    return '$_temp0';
  }

  @override
  String get scanTitle => 'Scan Document';

  @override
  String get scanDescription =>
      'Turn photos of paper documents into a clean PDF — edge detection and cropping happen automatically as you scan.';

  @override
  String get scanStepScan => 'Scan';

  @override
  String get scanStepReorder => 'Reorder';

  @override
  String get scanStepCreatePdf => 'Create PDF';

  @override
  String get scanStepSave => 'Save';

  @override
  String get scanADocument => 'Scan a document';

  @override
  String get scanHint =>
      'Uses your camera — edges are detected and cropped automatically';

  @override
  String get openingCamera => 'Opening camera…';

  @override
  String get scanMore => 'Scan more';

  @override
  String scanPageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages',
      one: '1 page',
    );
    return '$_temp0 — drag to reorder';
  }

  @override
  String pageNumberLabel(Object number) {
    return 'Page $number';
  }

  @override
  String get createPdfButton => 'Create PDF';

  @override
  String createPdfButtonReady(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Create PDF from $count pages',
      one: 'Create PDF from 1 page',
    );
    return '$_temp0';
  }

  @override
  String get pageEditTitle => 'Edit Pages';

  @override
  String get pageEditDescription =>
      'Rotate, reorder, or remove pages from a PDF — the rest of the document stays untouched.';

  @override
  String get pageEditStepSelect => 'Select PDF';

  @override
  String get pageEditStepEdit => 'Edit pages';

  @override
  String get pageEditStepSave => 'Save changes';

  @override
  String get rotate => 'Rotate';

  @override
  String get removePage => 'Remove page';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get pdfSavedSuccess => 'PDF saved successfully';

  @override
  String get contentEditTitle => 'Edit PDF';

  @override
  String get contentEditDescription =>
      'Tap a line to fix or remove it, or drop in an image — edits cover the original spot rather than reflowing the page.';

  @override
  String get contentEditStepSelect => 'Select PDF';

  @override
  String get contentEditStepEdit => 'Tap to edit';

  @override
  String get contentEditStepSave => 'Save changes';

  @override
  String get editLine => 'Edit line';

  @override
  String get lineText => 'Line text';

  @override
  String get delete => 'Delete';

  @override
  String get addImageToPage => 'Add image to this page';

  @override
  String get addImage => 'Add image';

  @override
  String get thisPdfHasNoPages => 'This PDF has no pages.';

  @override
  String get encryptTitle => 'Password Protect';

  @override
  String get encryptDescription =>
      'Lock a PDF with a password so only people who know it can open it.';

  @override
  String get addPasswordSegment => 'Add Password';

  @override
  String get removePasswordSegment => 'Remove Password';

  @override
  String get password => 'Password';

  @override
  String get currentPassword => 'Current password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String passwordHelperText(Object minLength) {
    return 'At least $minLength characters, no spaces';
  }

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get lockButton => 'Lock';

  @override
  String get unlockButton => 'Unlock';

  @override
  String get passwordAdded => 'Password added';

  @override
  String get passwordRemoved => 'Password removed';

  @override
  String get watermarkTitle => 'Watermark';

  @override
  String get watermarkDescription =>
      'Stamp text diagonally across every page — great for \"DRAFT\", \"CONFIDENTIAL\", or a company name.';

  @override
  String get watermarkStepSelect => 'Select PDF';

  @override
  String get watermarkStepText => 'Set text';

  @override
  String get watermarkStepStamp => 'Stamp';

  @override
  String get watermarkStepSave => 'Save';

  @override
  String get watermarkText => 'Watermark text';

  @override
  String get watermarkTextHint => 'e.g. CONFIDENTIAL';

  @override
  String get color => 'Color';

  @override
  String opacityPercent(Object percent) {
    return 'Opacity: $percent%';
  }

  @override
  String sizeValue(Object size) {
    return 'Size: $size';
  }

  @override
  String get watermarkButton => 'Stamp';

  @override
  String get watermarkAdded => 'Watermark added';

  @override
  String get signatureTitle => 'Digital Signature';

  @override
  String get signatureDescription =>
      'Draw or type a signature, place it on any page, and save.';

  @override
  String get signatureStepSelect => 'Select PDF';

  @override
  String get signatureStepCreate => 'Set signature';

  @override
  String get signatureStepPlace => 'Place';

  @override
  String get signatureStepSave => 'Save signed PDF';

  @override
  String get addSignature => 'Add Signature';

  @override
  String get changeSignature => 'Change Signature';

  @override
  String get placeButton => 'Place';

  @override
  String get signButton => 'Sign';

  @override
  String get pdfSignedSuccess => 'PDF signed successfully';

  @override
  String get signaturePadDraw => 'Draw';

  @override
  String get signaturePadType => 'Type';

  @override
  String get signaturePadCreateTitle => 'Create Signature';

  @override
  String get signaturePadDrawHint => 'Sign with your finger or mouse';

  @override
  String get signaturePadClear => 'Clear';

  @override
  String get signaturePadColor => 'Color';

  @override
  String get signaturePadStyle => 'Style';

  @override
  String get signaturePadYourName => 'Your name';

  @override
  String get signaturePadTypeYourName => 'Type your name';

  @override
  String get signaturePadDone => 'Done';

  @override
  String get signaturePadFontCasual => 'Casual';

  @override
  String get signaturePadFontElegant => 'Elegant';

  @override
  String get signaturePadFontBold => 'Bold';

  @override
  String get colorBlack => 'Black';

  @override
  String get colorBlue => 'Blue';

  @override
  String get colorRed => 'Red';

  @override
  String get colorGreen => 'Green';

  @override
  String get languagePickerTitle => 'Choose your language';

  @override
  String get languagePickerSubtitle =>
      'You can change this later from the home screen.';

  @override
  String get languagePickerContinue => 'Continue';

  @override
  String get changeFile => 'Change file';

  @override
  String pageOfTotal(Object current, Object total) {
    return 'Page $current of $total';
  }

  @override
  String get encryptRemoveDescription =>
      'Remove a PDF\'s password, given the correct one.';

  @override
  String get encryptStepSetPassword => 'Set password';

  @override
  String get encryptStepEnterPassword => 'Enter password';
}
