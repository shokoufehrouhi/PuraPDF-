// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'PuraPDF+';

  @override
  String get appTagline =>
      'أداة PDF الخاصة بك — دمج وتقسيم وضغط وتحويل، كل ذلك على جهازك.';

  @override
  String get categoryOrganize => 'تنظيم';

  @override
  String get categoryEditProtect => 'تحرير وحماية';

  @override
  String get recentsTooltip => 'الأخيرة';

  @override
  String get backToToolsTooltip => 'العودة إلى الأدوات';

  @override
  String get themeLightTooltip => 'المظهر الفاتح';

  @override
  String get themeDarkTooltip => 'المظهر الداكن';

  @override
  String get languageTooltip => 'اللغة';

  @override
  String get featureMergeTitle => 'دمج ملفات PDF';

  @override
  String get featureMergeSubtitle => 'دمج عدة مستندات';

  @override
  String get featureSplitTitle => 'تقسيم PDF';

  @override
  String get featureSplitSubtitle => 'الفصل إلى صفحات أو أقسام';

  @override
  String get featureCompressTitle => 'ضغط PDF';

  @override
  String get featureCompressSubtitle => 'تحسين حجم الملف للمشاركة';

  @override
  String get featureImagePdfTitle => 'صورة ⇄ PDF';

  @override
  String get featureImagePdfSubtitle => 'التحويل بين الصيغ';

  @override
  String get featureScanTitle => 'مسح مستند';

  @override
  String get featureScanSubtitle => 'التقاط المستندات الورقية بالكاميرا';

  @override
  String get featurePageEditTitle => 'تحرير الصفحات';

  @override
  String get featurePageEditSubtitle =>
      'تدوير الصفحات أو إعادة ترتيبها أو حذفها';

  @override
  String get featureContentEditTitle => 'تحرير PDF';

  @override
  String get featureContentEditSubtitle => 'تصحيح النص، حذف سطر، إضافة صورة';

  @override
  String get featureEncryptTitle => 'الحماية بكلمة مرور';

  @override
  String get featureEncryptSubtitle => 'إضافة أو إزالة كلمة مرور PDF';

  @override
  String get featureWatermarkTitle => 'علامة مائية';

  @override
  String get featureWatermarkSubtitle => 'طباعة نص على كل صفحة';

  @override
  String get featureSignatureTitle => 'توقيع رقمي';

  @override
  String get featureSignatureSubtitle => 'ارسم أو اكتب توقيعًا، ضعه، احفظ';

  @override
  String get recentsEmptyTitle => 'لا توجد ملفات بعد';

  @override
  String get recentsEmptyBody =>
      'الملفات التي تنشئها باستخدام الدمج أو التقسيم أو الضغط أو صورة ⇄ PDF ستظهر هنا.';

  @override
  String get browseTools => 'تصفح الأدوات';

  @override
  String get clear => 'مسح';

  @override
  String get clearAllTitle => 'هل تريد مسح جميع الملفات الأخيرة؟';

  @override
  String get clearAllBody =>
      'سيؤدي هذا إلى حذف كل الملفات المدرجة هنا من جهازك. لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get cancel => 'إلغاء';

  @override
  String get clearAllConfirm => 'مسح الكل';

  @override
  String get opUnknown => 'ملف';

  @override
  String get opMerge => 'دمج';

  @override
  String get opSplit => 'تقسيم';

  @override
  String get opCompress => 'ضغط';

  @override
  String get opImageToPdf => 'صورة ← PDF';

  @override
  String get opPdfToImage => 'PDF ← صورة';

  @override
  String get opScan => 'مسح ضوئي';

  @override
  String get opPageEdit => 'تحرير الصفحات';

  @override
  String get opContentEdit => 'تحرير PDF';

  @override
  String get opLocked => 'مقفل';

  @override
  String get opUnlocked => 'غير مقفل';

  @override
  String get opWatermark => 'علامة مائية';

  @override
  String get opSigned => 'موقّع';

  @override
  String get share => 'مشاركة';

  @override
  String get download => 'تنزيل';

  @override
  String get startOver => 'البدء من جديد';

  @override
  String get save => 'حفظ';

  @override
  String get remove => 'إزالة';

  @override
  String get selectAPdf => 'اختر ملف PDF';

  @override
  String get selectPdf => 'اختيار PDF';

  @override
  String get tapToBrowseFiles => 'اضغط لتصفح ملفاتك';

  @override
  String get tapToChangeFile => 'اضغط لتغيير الملف';

  @override
  String get previousPage => 'الصفحة السابقة';

  @override
  String get nextPage => 'الصفحة التالية';

  @override
  String downloadSavedToDownloads(Object fileName) {
    return 'تم الحفظ في التنزيلات: $fileName';
  }

  @override
  String downloadSaved(Object fileName) {
    return 'تم الحفظ: $fileName';
  }

  @override
  String get downloadCancelled => 'تم الإلغاء';

  @override
  String get downloadNoDirectory => 'مجلد التنزيلات غير متاح';

  @override
  String get errorGeneric => 'حدث خطأ ما. حاول مرة أخرى.';

  @override
  String get errorSelectPdfFirst => 'اختر ملف PDF أولًا.';

  @override
  String get errorEnterPassword => 'أدخل كلمة مرور.';

  @override
  String get errorEnterPdfPassword => 'أدخل كلمة مرور ملف PDF.';

  @override
  String get errorPasswordNoSpaces =>
      'لا يمكن أن تحتوي كلمة المرور على مسافات.';

  @override
  String errorPasswordTooShort(Object minLength) {
    return 'يجب أن تتكون كلمة المرور من $minLength حرفًا على الأقل.';
  }

  @override
  String get errorPasswordsDontMatch => 'كلمتا المرور غير متطابقتين.';

  @override
  String get errorAtLeastOnePageMustRemain =>
      'يجب أن تبقى صفحة واحدة على الأقل.';

  @override
  String get errorAtLeastOnePageMustRemainInPdf =>
      'يجب أن تبقى صفحة واحدة على الأقل في ملف PDF.';

  @override
  String get errorMakeAChangeBeforeSaving =>
      'قم بإجراء تغيير واحد على الأقل قبل الحفظ.';

  @override
  String get errorSelectAtLeastOneImage => 'اختر صورة واحدة على الأقل.';

  @override
  String get errorMergeNeedsTwoFiles => 'يتطلب الدمج ملفي PDF على الأقل.';

  @override
  String get errorNewNameEmpty => 'لا يمكن أن يكون الاسم الجديد فارغًا.';

  @override
  String get errorScanAtLeastOnePage => 'امسح صفحة واحدة على الأقل.';

  @override
  String get errorScanAtLeastOnePageFirst => 'امسح صفحة واحدة على الأقل أولًا.';

  @override
  String get errorProvideAtLeastOneRange =>
      'حدد نطاق صفحات واحدًا على الأقل للتقسيم.';

  @override
  String errorInvalidPageRange(Object range) {
    return 'نطاق صفحات غير صالح: $range';
  }

  @override
  String errorRangeExceedsPageCount(Object range, Object pageCount) {
    return 'النطاق $range يتجاوز عدد صفحات المستند ($pageCount).';
  }

  @override
  String get errorEnterWatermarkText => 'أدخل نص العلامة المائية.';

  @override
  String get errorAddSignatureFirst => 'أضف توقيعًا أولًا.';

  @override
  String errorPageIndexOutOfRange(Object index, Object max) {
    return 'رقم الصفحة $index خارج النطاق (0-$max).';
  }

  @override
  String get errorWrongPasswordOrNotProtected =>
      'كلمة المرور خاطئة، أو أن ملف PDF هذا غير محمي بكلمة مرور.';

  @override
  String get errorUnsupportedImageFormat =>
      'صيغة الصورة هذه غير مدعومة. جرّب JPEG أو PNG بدلًا من ذلك.';

  @override
  String get mergeTitle => 'دمج ملفات PDF';

  @override
  String get mergeDescription =>
      'ادمج عدة ملفات PDF في مستند واحد، بالترتيب الذي تريده.';

  @override
  String get mergeStepAdd => 'إضافة ملفات';

  @override
  String get mergeStepReorder => 'إعادة الترتيب';

  @override
  String get mergeStepMerge => 'دمج';

  @override
  String get mergeStepSave => 'حفظ';

  @override
  String get mergeAddFiles => 'إضافة ملفات PDF';

  @override
  String get mergeAddFilesHint => 'يمكنك اختيار عدة ملفات في وقت واحد';

  @override
  String mergeFileCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ملفات',
      one: 'ملف واحد',
    );
    return '$_temp0 — اسحب لإعادة الترتيب';
  }

  @override
  String get addMore => 'إضافة المزيد';

  @override
  String get mergeButtonNeedsMore => 'أضف ملفين على الأقل للدمج';

  @override
  String mergeButtonReady(Object count) {
    return 'دمج $count ملفات';
  }

  @override
  String get mergeSuccess => 'تم الدمج بنجاح';

  @override
  String get splitTitle => 'تقسيم PDF';

  @override
  String get splitDescription =>
      'قسّم ملف PDF إلى ملفات منفصلة — حسب الصفحة أو نطاقات مخصصة.';

  @override
  String get splitStepSelect => 'اختيار PDF';

  @override
  String get splitStepChoose => 'اختيار الصفحات';

  @override
  String get splitStepSplit => 'تقسيم';

  @override
  String get splitStepSave => 'حفظ';

  @override
  String splitPageCountHint(Object count) {
    return '$count صفحات — اضغط لتغيير الملف';
  }

  @override
  String get splitOneFilePerPage => 'التقسيم إلى ملف واحد لكل صفحة';

  @override
  String get splitPageRanges => 'نطاقات الصفحات';

  @override
  String get splitPageRangesHint => 'مثال: 1-3، 5، 7-9';

  @override
  String get splitButton => 'تقسيم';

  @override
  String splitFilesCreated(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم إنشاء $count ملفات',
      one: 'تم إنشاء ملف واحد',
    );
    return '$_temp0';
  }

  @override
  String get shareZip => 'مشاركة ZIP';

  @override
  String get downloadZip => 'تنزيل ZIP';

  @override
  String get compressTitle => 'ضغط PDF';

  @override
  String get compressDescription =>
      'قلّل حجم ملف PDF لمشاركة أسهل، مع ثلاثة مستويات جودة للاختيار من بينها.';

  @override
  String get compressStepSelect => 'اختيار PDF';

  @override
  String get compressStepLevel => 'اختيار المستوى';

  @override
  String get compressStepCompress => 'ضغط';

  @override
  String get compressStepSave => 'حفظ';

  @override
  String compressOriginalSizeHint(Object size) {
    return 'الحجم الأصلي: $size — اضغط لتغيير الملف';
  }

  @override
  String get compressLow => 'منخفض';

  @override
  String get compressMedium => 'متوسط';

  @override
  String get compressHigh => 'عالٍ';

  @override
  String get compressHighWarning =>
      'يعيد المستوى «عالٍ» بناء كل صفحة كصورة — أفضل تقليل للحجم للمستندات الممسوحة/الصور، لكن النتيجة تفقد النص القابل للتحديد/البحث. في ملفات PDF كثيفة النص حيث قد يأتي هذا بنتيجة عكسية، يتم التبديل تلقائيًا إلى طريقة أخرى حتى لا تكون النتيجة أبدًا أكبر من الأصل.';

  @override
  String get compressButton => 'ضغط';

  @override
  String compressReductionPercent(Object percent) {
    return 'أصغر بنسبة $percent٪';
  }

  @override
  String compressBeforeAfter(Object before, Object after) {
    return 'قبل: $before  ←  بعد: $after';
  }

  @override
  String get beforeLabel => 'قبل';

  @override
  String get afterLabel => 'بعد';

  @override
  String get imagePdfTitle => 'صورة ⇄ PDF';

  @override
  String get imagesToPdfDescription =>
      'حوّل صورة واحدة أو أكثر إلى مستند PDF واحد.';

  @override
  String get pdfToImagesDescription =>
      'صدّر كل صفحة من ملف PDF كملف صورة منفصل.';

  @override
  String get imagePdfStepAddImages => 'إضافة صور';

  @override
  String get imagePdfStepConvert => 'تحويل';

  @override
  String get imagePdfStepSave => 'حفظ';

  @override
  String get imagePdfStepSelect => 'اختيار PDF';

  @override
  String get imagePdfStepFormat => 'اختيار الصيغة';

  @override
  String get imagesToPdfSegment => 'صور ← PDF';

  @override
  String get pdfToImagesSegment => 'PDF ← صور';

  @override
  String get imagesWord => 'صور';

  @override
  String get addImages => 'إضافة صور';

  @override
  String get addImagesHint => 'يمكنك اختيار عدة صور في وقت واحد';

  @override
  String imagesSelectedCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم اختيار $count صور',
      one: 'تم اختيار صورة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get pdfCreatedSuccess => 'تم إنشاء PDF بنجاح';

  @override
  String get convertButton => 'تحويل';

  @override
  String get convertButtonEmpty => 'أضف صورًا للتحويل';

  @override
  String convertButtonReady(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تحويل $count صور',
      one: 'تحويل صورة واحدة',
    );
    return '$_temp0';
  }

  @override
  String imagesCreatedCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم إنشاء $count صور',
      one: 'تم إنشاء صورة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get scanTitle => 'مسح مستند';

  @override
  String get scanDescription =>
      'حوّل صور المستندات الورقية إلى ملف PDF نظيف — يتم اكتشاف الحواف والقص تلقائيًا أثناء المسح.';

  @override
  String get scanStepScan => 'مسح';

  @override
  String get scanStepReorder => 'إعادة الترتيب';

  @override
  String get scanStepCreatePdf => 'إنشاء PDF';

  @override
  String get scanStepSave => 'حفظ';

  @override
  String get scanADocument => 'مسح مستند';

  @override
  String get scanHint => 'يستخدم الكاميرا — يتم اكتشاف الحواف وقصها تلقائيًا';

  @override
  String get openingCamera => 'جارٍ فتح الكاميرا…';

  @override
  String get scanMore => 'مسح المزيد';

  @override
  String scanPageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count صفحات',
      one: 'صفحة واحدة',
    );
    return '$_temp0 — اسحب لإعادة الترتيب';
  }

  @override
  String pageNumberLabel(Object number) {
    return 'صفحة $number';
  }

  @override
  String get createPdfButton => 'إنشاء PDF';

  @override
  String createPdfButtonReady(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'إنشاء PDF من $count صفحات',
      one: 'إنشاء PDF من صفحة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get pageEditTitle => 'تحرير الصفحات';

  @override
  String get pageEditDescription =>
      'قم بتدوير صفحات ملف PDF أو إعادة ترتيبها أو إزالتها — تبقى بقية المستند دون تغيير.';

  @override
  String get pageEditStepSelect => 'اختيار PDF';

  @override
  String get pageEditStepEdit => 'تحرير الصفحات';

  @override
  String get pageEditStepSave => 'حفظ التغييرات';

  @override
  String get rotate => 'تدوير';

  @override
  String get removePage => 'إزالة الصفحة';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get pdfSavedSuccess => 'تم حفظ PDF بنجاح';

  @override
  String get contentEditTitle => 'تحرير PDF';

  @override
  String get contentEditDescription =>
      'اضغط على سطر لتصحيحه أو إزالته، أو أضف صورة — تغطي التعديلات المكان الأصلي بدلًا من إعادة تدفق الصفحة.';

  @override
  String get contentEditStepSelect => 'اختيار PDF';

  @override
  String get contentEditStepEdit => 'اضغط للتحرير';

  @override
  String get contentEditStepSave => 'حفظ التغييرات';

  @override
  String get editLine => 'تحرير السطر';

  @override
  String get lineText => 'نص السطر';

  @override
  String get delete => 'حذف';

  @override
  String get addImageToPage => 'إضافة صورة لهذه الصفحة';

  @override
  String get addImage => 'إضافة صورة';

  @override
  String get thisPdfHasNoPages => 'لا يحتوي ملف PDF هذا على صفحات.';

  @override
  String get encryptTitle => 'الحماية بكلمة مرور';

  @override
  String get encryptDescription =>
      'أقفل ملف PDF بكلمة مرور بحيث لا يفتحه إلا من يعرفها.';

  @override
  String get addPasswordSegment => 'إضافة كلمة مرور';

  @override
  String get removePasswordSegment => 'إزالة كلمة مرور';

  @override
  String get password => 'كلمة المرور';

  @override
  String get currentPassword => 'كلمة المرور الحالية';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String passwordHelperText(Object minLength) {
    return '$minLength أحرف على الأقل، بدون مسافات';
  }

  @override
  String get showPassword => 'إظهار كلمة المرور';

  @override
  String get hidePassword => 'إخفاء كلمة المرور';

  @override
  String get lockButton => 'قفل';

  @override
  String get unlockButton => 'فتح القفل';

  @override
  String get passwordAdded => 'تمت إضافة كلمة المرور';

  @override
  String get passwordRemoved => 'تمت إزالة كلمة المرور';

  @override
  String get watermarkTitle => 'علامة مائية';

  @override
  String get watermarkDescription =>
      'اطبع نصًا بشكل قطري على كل صفحة — رائع لكلمة \"مسودة\" أو \"سري\" أو اسم شركة.';

  @override
  String get watermarkStepSelect => 'اختيار PDF';

  @override
  String get watermarkStepText => 'تحديد النص';

  @override
  String get watermarkStepStamp => 'طباعة';

  @override
  String get watermarkStepSave => 'حفظ';

  @override
  String get watermarkText => 'نص العلامة المائية';

  @override
  String get watermarkTextHint => 'مثال: سري';

  @override
  String get color => 'اللون';

  @override
  String opacityPercent(Object percent) {
    return 'الشفافية: $percent٪';
  }

  @override
  String sizeValue(Object size) {
    return 'الحجم: $size';
  }

  @override
  String get watermarkButton => 'طباعة';

  @override
  String get watermarkAdded => 'تمت إضافة العلامة المائية';

  @override
  String get signatureTitle => 'توقيع رقمي';

  @override
  String get signatureDescription =>
      'ارسم أو اكتب توقيعًا، ضعه في أي صفحة، ثم احفظ.';

  @override
  String get signatureStepSelect => 'اختيار PDF';

  @override
  String get signatureStepCreate => 'تحديد التوقيع';

  @override
  String get signatureStepPlace => 'وضع';

  @override
  String get signatureStepSave => 'حفظ PDF الموقّع';

  @override
  String get addSignature => 'إضافة توقيع';

  @override
  String get changeSignature => 'تغيير التوقيع';

  @override
  String get placeButton => 'وضع';

  @override
  String get signButton => 'توقيع';

  @override
  String get pdfSignedSuccess => 'تم توقيع PDF بنجاح';

  @override
  String get signaturePadDraw => 'رسم';

  @override
  String get signaturePadType => 'كتابة';

  @override
  String get signaturePadCreateTitle => 'إنشاء توقيع';

  @override
  String get signaturePadDrawHint => 'وقّع بإصبعك أو بالماوس';

  @override
  String get signaturePadClear => 'مسح';

  @override
  String get signaturePadColor => 'اللون';

  @override
  String get signaturePadStyle => 'النمط';

  @override
  String get signaturePadYourName => 'اسمك';

  @override
  String get signaturePadTypeYourName => 'اكتب اسمك';

  @override
  String get signaturePadDone => 'تم';

  @override
  String get signaturePadFontCasual => 'غير رسمي';

  @override
  String get signaturePadFontElegant => 'أنيق';

  @override
  String get signaturePadFontBold => 'عريض';

  @override
  String get colorBlack => 'أسود';

  @override
  String get colorBlue => 'أزرق';

  @override
  String get colorRed => 'أحمر';

  @override
  String get colorGreen => 'أخضر';

  @override
  String get languagePickerTitle => 'اختر لغتك';

  @override
  String get languagePickerSubtitle =>
      'يمكنك تغيير هذا لاحقًا من الشاشة الرئيسية.';

  @override
  String get languagePickerContinue => 'متابعة';

  @override
  String get changeFile => 'تغيير الملف';

  @override
  String pageOfTotal(Object current, Object total) {
    return 'صفحة $current من $total';
  }

  @override
  String get encryptRemoveDescription =>
      'أزل كلمة مرور ملف PDF، بمعرفة كلمة المرور الصحيحة.';

  @override
  String get encryptStepSetPassword => 'تعيين كلمة المرور';

  @override
  String get encryptStepEnterPassword => 'إدخال كلمة المرور';
}
