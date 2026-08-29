// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class AppLocalizationsFa extends AppLocalizations {
  AppLocalizationsFa([String locale = 'fa']) : super(locale);

  @override
  String get appName => 'PuraPDF+';

  @override
  String get appTagline =>
      'ابزار PDF شما — ادغام، تقسیم، فشرده‌سازی و تبدیل، همه روی دستگاه.';

  @override
  String get categoryOrganize => 'سازمان‌دهی';

  @override
  String get categoryEditProtect => 'ویرایش و محافظت';

  @override
  String get recentsTooltip => 'اخیر';

  @override
  String get backToToolsTooltip => 'بازگشت به ابزارها';

  @override
  String get themeLightTooltip => 'پوسته روشن';

  @override
  String get themeDarkTooltip => 'پوسته تیره';

  @override
  String get languageTooltip => 'زبان';

  @override
  String get featureMergeTitle => 'ادغام PDF';

  @override
  String get featureMergeSubtitle => 'ترکیب چند سند';

  @override
  String get featureSplitTitle => 'تقسیم PDF';

  @override
  String get featureSplitSubtitle => 'جدا کردن به صفحه یا بخش';

  @override
  String get featureCompressTitle => 'فشرده‌سازی PDF';

  @override
  String get featureCompressSubtitle => 'بهینه‌سازی حجم برای اشتراک‌گذاری';

  @override
  String get featureImagePdfTitle => 'تصویر ⇄ PDF';

  @override
  String get featureImagePdfSubtitle => 'تبدیل بین فرمت‌ها';

  @override
  String get featureScanTitle => 'اسکن سند';

  @override
  String get featureScanSubtitle => 'ثبت اسناد کاغذی با دوربین';

  @override
  String get featurePageEditTitle => 'ویرایش صفحات';

  @override
  String get featurePageEditSubtitle => 'چرخش، جابجایی یا حذف صفحات';

  @override
  String get featureContentEditTitle => 'ویرایش PDF';

  @override
  String get featureContentEditSubtitle => 'اصلاح متن، حذف خط، افزودن تصویر';

  @override
  String get featureEncryptTitle => 'محافظت با رمز';

  @override
  String get featureEncryptSubtitle => 'افزودن یا حذف رمز عبور PDF';

  @override
  String get featureWatermarkTitle => 'واترمارک';

  @override
  String get featureWatermarkSubtitle => 'درج متن روی تمام صفحات';

  @override
  String get featureSignatureTitle => 'امضای دیجیتال';

  @override
  String get featureSignatureSubtitle => 'کشیدن یا تایپ امضا، قرار دادن، ذخیره';

  @override
  String get recentsEmptyTitle => 'هنوز فایلی نیست';

  @override
  String get recentsEmptyBody =>
      'فایل‌هایی که با ادغام، تقسیم، فشرده‌سازی یا تصویر ⇄ PDF می‌سازید اینجا نمایش داده می‌شوند.';

  @override
  String get browseTools => 'مرور ابزارها';

  @override
  String get clear => 'پاک کردن';

  @override
  String get clearAllTitle => 'همه موارد اخیر پاک شوند؟';

  @override
  String get clearAllBody =>
      'این کار همه فایل‌های این لیست را از دستگاه شما حذف می‌کند. این عمل قابل بازگشت نیست.';

  @override
  String get cancel => 'لغو';

  @override
  String get clearAllConfirm => 'پاک کردن همه';

  @override
  String get opUnknown => 'فایل';

  @override
  String get opMerge => 'ادغام';

  @override
  String get opSplit => 'تقسیم';

  @override
  String get opCompress => 'فشرده‌سازی';

  @override
  String get opImageToPdf => 'تصویر → PDF';

  @override
  String get opPdfToImage => 'PDF → تصویر';

  @override
  String get opScan => 'اسکن';

  @override
  String get opPageEdit => 'ویرایش صفحات';

  @override
  String get opContentEdit => 'ویرایش PDF';

  @override
  String get opLocked => 'قفل‌شده';

  @override
  String get opUnlocked => 'بازشده';

  @override
  String get opWatermark => 'واترمارک';

  @override
  String get opSigned => 'امضاشده';

  @override
  String get share => 'اشتراک‌گذاری';

  @override
  String get download => 'دانلود';

  @override
  String get startOver => 'شروع دوباره';

  @override
  String get save => 'ذخیره';

  @override
  String get remove => 'حذف';

  @override
  String get selectAPdf => 'انتخاب یک PDF';

  @override
  String get selectPdf => 'انتخاب PDF';

  @override
  String get tapToBrowseFiles => 'برای مرور فایل‌ها ضربه بزنید';

  @override
  String get tapToChangeFile => 'برای تغییر فایل ضربه بزنید';

  @override
  String get previousPage => 'صفحه قبل';

  @override
  String get nextPage => 'صفحه بعد';

  @override
  String downloadSavedToDownloads(Object fileName) {
    return 'در Downloads ذخیره شد: $fileName';
  }

  @override
  String downloadSaved(Object fileName) {
    return 'ذخیره شد: $fileName';
  }

  @override
  String get downloadCancelled => 'لغو شد';

  @override
  String get downloadNoDirectory => 'پوشه Downloads در دسترس نیست';

  @override
  String get errorGeneric => 'مشکلی پیش آمد. دوباره امتحان کنید.';

  @override
  String get errorSelectPdfFirst => 'اول یک PDF انتخاب کنید.';

  @override
  String get errorEnterPassword => 'رمز عبور را وارد کنید.';

  @override
  String get errorEnterPdfPassword => 'رمز عبور PDF را وارد کنید.';

  @override
  String get errorPasswordNoSpaces => 'رمز عبور نمی‌تواند فاصله داشته باشد.';

  @override
  String errorPasswordTooShort(Object minLength) {
    return 'رمز عبور باید حداقل $minLength کاراکتر باشد.';
  }

  @override
  String get errorPasswordsDontMatch => 'رمزهای عبور مطابقت ندارند.';

  @override
  String get errorAtLeastOnePageMustRemain => 'حداقل یک صفحه باید باقی بماند.';

  @override
  String get errorAtLeastOnePageMustRemainInPdf =>
      'حداقل یک صفحه باید در PDF باقی بماند.';

  @override
  String get errorMakeAChangeBeforeSaving =>
      'قبل از ذخیره حداقل یک تغییر ایجاد کنید.';

  @override
  String get errorSelectAtLeastOneImage => 'حداقل یک تصویر انتخاب کنید.';

  @override
  String get errorMergeNeedsTwoFiles =>
      'برای ادغام حداقل به ۲ فایل PDF نیاز است.';

  @override
  String get errorNewNameEmpty => 'نام جدید نمی‌تواند خالی باشد.';

  @override
  String get errorScanAtLeastOnePage => 'حداقل یک صفحه اسکن کنید.';

  @override
  String get errorScanAtLeastOnePageFirst => 'اول حداقل یک صفحه اسکن کنید.';

  @override
  String get errorProvideAtLeastOneRange =>
      'حداقل یک بازه صفحه برای تقسیم وارد کنید.';

  @override
  String errorInvalidPageRange(Object range) {
    return 'بازه صفحه نامعتبر: $range';
  }

  @override
  String errorRangeExceedsPageCount(Object range, Object pageCount) {
    return 'بازه $range از تعداد صفحات سند ($pageCount) بیشتر است.';
  }

  @override
  String get errorEnterWatermarkText => 'متن واترمارک را وارد کنید.';

  @override
  String get errorAddSignatureFirst => 'اول یک امضا اضافه کنید.';

  @override
  String errorPageIndexOutOfRange(Object index, Object max) {
    return 'شماره صفحه $index خارج از محدوده است (۰ تا $max).';
  }

  @override
  String get errorWrongPasswordOrNotProtected =>
      'رمز عبور اشتباه است، یا این PDF رمزگذاری نشده.';

  @override
  String get errorUnsupportedImageFormat =>
      'این فرمت تصویر پشتیبانی نمی‌شود. یک JPEG یا PNG امتحان کنید.';

  @override
  String get mergeTitle => 'ادغام PDF';

  @override
  String get mergeDescription =>
      'چند فایل PDF را با هر ترتیبی که بخواهید در یک سند ادغام کنید.';

  @override
  String get mergeStepAdd => 'افزودن فایل';

  @override
  String get mergeStepReorder => 'جابجایی';

  @override
  String get mergeStepMerge => 'ادغام';

  @override
  String get mergeStepSave => 'ذخیره';

  @override
  String get mergeAddFiles => 'افزودن فایل‌های PDF';

  @override
  String get mergeAddFilesHint => 'می‌توانید چند فایل را همزمان انتخاب کنید';

  @override
  String mergeFileCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فایل',
      one: '۱ فایل',
    );
    return '$_temp0 — برای جابجایی بکشید';
  }

  @override
  String get addMore => 'افزودن بیشتر';

  @override
  String get mergeButtonNeedsMore => 'برای ادغام حداقل ۲ فایل اضافه کنید';

  @override
  String mergeButtonReady(Object count) {
    return 'ادغام $count فایل';
  }

  @override
  String get mergeSuccess => 'با موفقیت ادغام شد';

  @override
  String get splitTitle => 'تقسیم PDF';

  @override
  String get splitDescription =>
      'یک PDF را به فایل‌های جداگانه تقسیم کنید — بر اساس صفحه یا بازه‌های دلخواه.';

  @override
  String get splitStepSelect => 'انتخاب PDF';

  @override
  String get splitStepChoose => 'انتخاب صفحات';

  @override
  String get splitStepSplit => 'تقسیم';

  @override
  String get splitStepSave => 'ذخیره';

  @override
  String splitPageCountHint(Object count) {
    return '$count صفحه — برای تغییر فایل ضربه بزنید';
  }

  @override
  String get splitOneFilePerPage => 'تقسیم به یک فایل برای هر صفحه';

  @override
  String get splitPageRanges => 'بازه صفحات';

  @override
  String get splitPageRangesHint => 'مثلاً ۱-۳، ۵، ۷-۹';

  @override
  String get splitButton => 'تقسیم';

  @override
  String splitFilesCreated(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فایل ساخته شد',
      one: '۱ فایل ساخته شد',
    );
    return '$_temp0';
  }

  @override
  String get shareZip => 'اشتراک‌گذاری ZIP';

  @override
  String get downloadZip => 'دانلود ZIP';

  @override
  String get compressTitle => 'فشرده‌سازی PDF';

  @override
  String get compressDescription =>
      'حجم فایل PDF را برای اشتراک‌گذاری آسان‌تر کاهش دهید، با سه سطح کیفیت.';

  @override
  String get compressStepSelect => 'انتخاب PDF';

  @override
  String get compressStepLevel => 'انتخاب سطح';

  @override
  String get compressStepCompress => 'فشرده‌سازی';

  @override
  String get compressStepSave => 'ذخیره';

  @override
  String compressOriginalSizeHint(Object size) {
    return 'حجم اصلی: $size — برای تغییر فایل ضربه بزنید';
  }

  @override
  String get compressLow => 'کم';

  @override
  String get compressMedium => 'متوسط';

  @override
  String get compressHigh => 'زیاد';

  @override
  String get compressHighWarning =>
      'سطح «زیاد» هر صفحه را به تصویر تبدیل می‌کند — بهترین کاهش حجم برای اسکن/عکس، اما متن قابل انتخاب/جستجو از بین می‌رود. در PDFهای متنی که این کار نتیجه معکوس بدهد، به‌طور خودکار به روش دیگری برمی‌گردد تا نتیجه هرگز از فایل اصلی بزرگ‌تر نشود.';

  @override
  String get compressButton => 'فشرده‌سازی';

  @override
  String compressReductionPercent(Object percent) {
    return '$percent٪ کوچک‌تر';
  }

  @override
  String compressBeforeAfter(Object before, Object after) {
    return 'قبل: $before  ←  بعد: $after';
  }

  @override
  String get imagePdfTitle => 'تصویر ⇄ PDF';

  @override
  String get imagesToPdfDescription =>
      'یک یا چند عکس را به یک سند PDF تبدیل کنید.';

  @override
  String get pdfToImagesDescription =>
      'هر صفحه از یک PDF را به‌صورت فایل تصویر جداگانه استخراج کنید.';

  @override
  String get imagePdfStepAddImages => 'افزودن تصویر';

  @override
  String get imagePdfStepConvert => 'تبدیل';

  @override
  String get imagePdfStepSave => 'ذخیره';

  @override
  String get imagePdfStepSelect => 'انتخاب PDF';

  @override
  String get imagePdfStepFormat => 'انتخاب فرمت';

  @override
  String get imagesToPdfSegment => 'تصویر → PDF';

  @override
  String get pdfToImagesSegment => 'PDF → تصویر';

  @override
  String get addImages => 'افزودن تصویر';

  @override
  String get addImagesHint => 'می‌توانید چند عکس را همزمان انتخاب کنید';

  @override
  String imagesSelectedCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تصویر انتخاب شد',
      one: '۱ تصویر انتخاب شد',
    );
    return '$_temp0';
  }

  @override
  String get pdfCreatedSuccess => 'PDF با موفقیت ساخته شد';

  @override
  String get convertButton => 'تبدیل';

  @override
  String get convertButtonEmpty => 'برای تبدیل، تصویر اضافه کنید';

  @override
  String convertButtonReady(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تبدیل $count تصویر',
      one: 'تبدیل ۱ تصویر',
    );
    return '$_temp0';
  }

  @override
  String imagesCreatedCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تصویر ساخته شد',
      one: '۱ تصویر ساخته شد',
    );
    return '$_temp0';
  }

  @override
  String get scanTitle => 'اسکن سند';

  @override
  String get scanDescription =>
      'عکس اسناد کاغذی را به یک PDF تمیز تبدیل کنید — تشخیص لبه و برش هنگام اسکن به‌طور خودکار انجام می‌شود.';

  @override
  String get scanStepScan => 'اسکن';

  @override
  String get scanStepReorder => 'جابجایی';

  @override
  String get scanStepCreatePdf => 'ساخت PDF';

  @override
  String get scanStepSave => 'ذخیره';

  @override
  String get scanADocument => 'اسکن یک سند';

  @override
  String get scanHint =>
      'از دوربین استفاده می‌کند — لبه‌ها به‌طور خودکار تشخیص و برش داده می‌شوند';

  @override
  String get openingCamera => 'در حال باز کردن دوربین…';

  @override
  String get scanMore => 'اسکن بیشتر';

  @override
  String scanPageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count صفحه',
      one: '۱ صفحه',
    );
    return '$_temp0 — برای جابجایی بکشید';
  }

  @override
  String pageNumberLabel(Object number) {
    return 'صفحه $number';
  }

  @override
  String get createPdfButton => 'ساخت PDF';

  @override
  String createPdfButtonReady(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ساخت PDF از $count صفحه',
      one: 'ساخت PDF از ۱ صفحه',
    );
    return '$_temp0';
  }

  @override
  String get pageEditTitle => 'ویرایش صفحات';

  @override
  String get pageEditDescription =>
      'صفحات یک PDF را بچرخانید، جابجا کنید یا حذف کنید — بقیه سند دست‌نخورده می‌ماند.';

  @override
  String get pageEditStepSelect => 'انتخاب PDF';

  @override
  String get pageEditStepEdit => 'ویرایش صفحات';

  @override
  String get pageEditStepSave => 'ذخیره تغییرات';

  @override
  String get rotate => 'چرخش';

  @override
  String get removePage => 'حذف صفحه';

  @override
  String get saveChanges => 'ذخیره تغییرات';

  @override
  String get pdfSavedSuccess => 'PDF با موفقیت ذخیره شد';

  @override
  String get contentEditTitle => 'ویرایش PDF';

  @override
  String get contentEditDescription =>
      'برای اصلاح یا حذف یک خط روی آن ضربه بزنید، یا یک تصویر اضافه کنید — ویرایش‌ها روی همان محل قبلی قرار می‌گیرند و باعث جابجایی بقیه صفحه نمی‌شوند.';

  @override
  String get contentEditStepSelect => 'انتخاب PDF';

  @override
  String get contentEditStepEdit => 'برای ویرایش ضربه بزنید';

  @override
  String get contentEditStepSave => 'ذخیره تغییرات';

  @override
  String get editLine => 'ویرایش خط';

  @override
  String get lineText => 'متن خط';

  @override
  String get delete => 'حذف';

  @override
  String get addImageToPage => 'افزودن تصویر به این صفحه';

  @override
  String get addImage => 'افزودن تصویر';

  @override
  String get thisPdfHasNoPages => 'این PDF صفحه‌ای ندارد.';

  @override
  String get encryptTitle => 'محافظت با رمز';

  @override
  String get encryptDescription =>
      'یک PDF را با رمز عبور قفل کنید تا فقط افرادی که رمز را می‌دانند بتوانند آن را باز کنند.';

  @override
  String get addPasswordSegment => 'افزودن رمز';

  @override
  String get removePasswordSegment => 'حذف رمز';

  @override
  String get password => 'رمز عبور';

  @override
  String get currentPassword => 'رمز عبور فعلی';

  @override
  String get confirmPassword => 'تکرار رمز عبور';

  @override
  String passwordHelperText(Object minLength) {
    return 'حداقل $minLength کاراکتر، بدون فاصله';
  }

  @override
  String get showPassword => 'نمایش رمز عبور';

  @override
  String get hidePassword => 'پنهان‌کردن رمز عبور';

  @override
  String get lockButton => 'قفل کردن';

  @override
  String get unlockButton => 'باز کردن قفل';

  @override
  String get passwordAdded => 'رمز عبور اضافه شد';

  @override
  String get passwordRemoved => 'رمز عبور حذف شد';

  @override
  String get watermarkTitle => 'واترمارک';

  @override
  String get watermarkDescription =>
      'متن را به‌صورت مورب روی تمام صفحات درج کنید — مناسب برای «پیش‌نویس»، «محرمانه» یا نام شرکت.';

  @override
  String get watermarkStepSelect => 'انتخاب PDF';

  @override
  String get watermarkStepText => 'تنظیم متن';

  @override
  String get watermarkStepStamp => 'درج';

  @override
  String get watermarkStepSave => 'ذخیره';

  @override
  String get watermarkText => 'متن واترمارک';

  @override
  String get watermarkTextHint => 'مثلاً محرمانه';

  @override
  String get color => 'رنگ';

  @override
  String opacityPercent(Object percent) {
    return 'شفافیت: $percent٪';
  }

  @override
  String sizeValue(Object size) {
    return 'اندازه: $size';
  }

  @override
  String get watermarkButton => 'درج';

  @override
  String get watermarkAdded => 'واترمارک اضافه شد';

  @override
  String get signatureTitle => 'امضای دیجیتال';

  @override
  String get signatureDescription =>
      'یک امضا بکشید یا تایپ کنید، آن را روی هر صفحه‌ای قرار دهید و ذخیره کنید.';

  @override
  String get signatureStepSelect => 'انتخاب PDF';

  @override
  String get signatureStepCreate => 'تنظیم امضا';

  @override
  String get signatureStepPlace => 'قرار دادن';

  @override
  String get signatureStepSave => 'ذخیره PDF امضاشده';

  @override
  String get addSignature => 'افزودن امضا';

  @override
  String get changeSignature => 'تغییر امضا';

  @override
  String get placeButton => 'قرار دادن';

  @override
  String get signButton => 'امضا';

  @override
  String get pdfSignedSuccess => 'PDF با موفقیت امضا شد';

  @override
  String get signaturePadDraw => 'کشیدن';

  @override
  String get signaturePadType => 'تایپ';

  @override
  String get signaturePadCreateTitle => 'ساخت امضا';

  @override
  String get signaturePadDrawHint => 'با انگشت یا ماوس امضا کنید';

  @override
  String get signaturePadClear => 'پاک کردن';

  @override
  String get signaturePadColor => 'رنگ';

  @override
  String get signaturePadStyle => 'سبک';

  @override
  String get signaturePadYourName => 'نام شما';

  @override
  String get signaturePadTypeYourName => 'نام خود را تایپ کنید';

  @override
  String get signaturePadDone => 'تمام';

  @override
  String get signaturePadFontCasual => 'غیررسمی';

  @override
  String get signaturePadFontElegant => 'شیک';

  @override
  String get signaturePadFontBold => 'پررنگ';

  @override
  String get colorBlack => 'مشکی';

  @override
  String get colorBlue => 'آبی';

  @override
  String get colorRed => 'قرمز';

  @override
  String get colorGreen => 'سبز';

  @override
  String get languagePickerTitle => 'زبان خود را انتخاب کنید';

  @override
  String get languagePickerSubtitle =>
      'می‌توانید بعداً این را از صفحه اصلی تغییر دهید.';

  @override
  String get languagePickerContinue => 'ادامه';

  @override
  String get changeFile => 'تغییر فایل';

  @override
  String pageOfTotal(Object current, Object total) {
    return 'صفحه $current از $total';
  }

  @override
  String get encryptRemoveDescription =>
      'رمز عبور یک PDF را حذف کنید، در صورت داشتن رمز درست.';

  @override
  String get encryptStepSetPassword => 'تنظیم رمز عبور';

  @override
  String get encryptStepEnterPassword => 'وارد کردن رمز عبور';
}
