// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appName => 'PuraPDF+';

  @override
  String get appTagline =>
      'PDF araç setiniz — birleştirin, bölün, sıkıştırın ve dönüştürün, hepsi cihazınızda.';

  @override
  String get categoryOrganize => 'Düzenle';

  @override
  String get categoryEditProtect => 'Düzenle ve Koru';

  @override
  String get recentsTooltip => 'Son öğeler';

  @override
  String get backToToolsTooltip => 'Araçlara dön';

  @override
  String get themeLightTooltip => 'Açık tema';

  @override
  String get themeDarkTooltip => 'Koyu tema';

  @override
  String get languageTooltip => 'Dil';

  @override
  String get featureMergeTitle => 'PDF\'leri Birleştir';

  @override
  String get featureMergeSubtitle => 'Birden fazla belgeyi birleştir';

  @override
  String get featureSplitTitle => 'PDF Böl';

  @override
  String get featureSplitSubtitle => 'Sayfalara veya bölümlere ayır';

  @override
  String get featureCompressTitle => 'PDF Sıkıştır';

  @override
  String get featureCompressSubtitle =>
      'Paylaşım için dosya boyutunu optimize et';

  @override
  String get featureImagePdfTitle => 'Görsel ⇄ PDF';

  @override
  String get featureImagePdfSubtitle => 'Formatlar arasında dönüştür';

  @override
  String get featurePdfWordTitle => 'PDF ⇄ Word';

  @override
  String get featurePdfWordSubtitle => 'Word\'e ve Word\'den dönüştürün';

  @override
  String get featureScanTitle => 'Belge Tara';

  @override
  String get featureScanSubtitle => 'Kamerayla kağıt belgeleri yakala';

  @override
  String get featurePageEditTitle => 'Sayfaları Düzenle';

  @override
  String get featurePageEditSubtitle =>
      'Sayfaları döndür, yeniden sırala veya kaldır';

  @override
  String get featureContentEditTitle => 'PDF Düzenle';

  @override
  String get featureContentEditSubtitle =>
      'Metni düzelt, satır kaldır, görsel ekle';

  @override
  String get featureEncryptTitle => 'Parola Koruması';

  @override
  String get featureEncryptSubtitle => 'PDF parolası ekle veya kaldır';

  @override
  String get featureWatermarkTitle => 'Filigran';

  @override
  String get featureWatermarkSubtitle => 'Her sayfaya metin damgala';

  @override
  String get featureSignatureTitle => 'Dijital İmza';

  @override
  String get featureSignatureSubtitle => 'İmza çiz veya yaz, yerleştir, kaydet';

  @override
  String get recentsEmptyTitle => 'Henüz dosya yok';

  @override
  String get recentsEmptyBody =>
      'Birleştir, Böl, Sıkıştır veya Görsel ⇄ PDF ile oluşturduğunuz dosyalar burada görünecek.';

  @override
  String get browseTools => 'Araçlara göz at';

  @override
  String get clear => 'Temizle';

  @override
  String get clearAllTitle => 'Tüm son öğeler temizlensin mi?';

  @override
  String get clearAllBody =>
      'Bu, burada listelenen tüm dosyaları cihazınızdan siler. Bu işlem geri alınamaz.';

  @override
  String get cancel => 'İptal';

  @override
  String get clearAllConfirm => 'Tümünü temizle';

  @override
  String get opUnknown => 'Dosya';

  @override
  String get opMerge => 'Birleştirme';

  @override
  String get opSplit => 'Bölme';

  @override
  String get opCompress => 'Sıkıştırma';

  @override
  String get opImageToPdf => 'Görsel → PDF';

  @override
  String get opPdfToImage => 'PDF → Görsel';

  @override
  String get opScan => 'Tarama';

  @override
  String get opPageEdit => 'Sayfa Düzenleme';

  @override
  String get opContentEdit => 'PDF Düzenleme';

  @override
  String get opRedact => 'Karart';

  @override
  String get opLocked => 'Kilitli';

  @override
  String get opUnlocked => 'Kilit Açıldı';

  @override
  String get opWatermark => 'Filigran';

  @override
  String get opSigned => 'İmzalandı';

  @override
  String get share => 'Paylaş';

  @override
  String get download => 'İndir';

  @override
  String get startOver => 'Yeniden başla';

  @override
  String get save => 'Kaydet';

  @override
  String get remove => 'Kaldır';

  @override
  String get selectAPdf => 'Bir PDF seçin';

  @override
  String get selectPdf => 'PDF Seç';

  @override
  String get tapToBrowseFiles => 'Dosyalara göz atmak için dokunun';

  @override
  String get tapToChangeFile => 'Dosyayı değiştirmek için dokunun';

  @override
  String get previousPage => 'Önceki sayfa';

  @override
  String get nextPage => 'Sonraki sayfa';

  @override
  String downloadSavedToDownloads(Object fileName) {
    return 'İndirilenler\'e kaydedildi: $fileName';
  }

  @override
  String downloadSaved(Object fileName) {
    return 'Kaydedildi: $fileName';
  }

  @override
  String get downloadCancelled => 'İptal edildi';

  @override
  String get downloadNoDirectory => 'İndirilenler klasörü kullanılamıyor';

  @override
  String get errorGeneric => 'Bir şeyler ters gitti. Lütfen tekrar deneyin.';

  @override
  String get errorSelectPdfFirst => 'Önce bir PDF seçin.';

  @override
  String get errorEnterPassword => 'Bir parola girin.';

  @override
  String get errorEnterPdfPassword => 'PDF\'nin parolasını girin.';

  @override
  String get errorPasswordNoSpaces => 'Parola boşluk içeremez.';

  @override
  String errorPasswordTooShort(Object minLength) {
    return 'Parola en az $minLength karakter olmalıdır.';
  }

  @override
  String get errorPasswordsDontMatch => 'Parolalar eşleşmiyor.';

  @override
  String get errorAtLeastOnePageMustRemain => 'En az bir sayfa kalmalıdır.';

  @override
  String get errorAtLeastOnePageMustRemainInPdf =>
      'PDF\'de en az bir sayfa kalmalıdır.';

  @override
  String get errorMakeAChangeBeforeSaving =>
      'Kaydetmeden önce en az bir değişiklik yapın.';

  @override
  String get errorMarkAtLeastOneLineToRedact =>
      'Karartmak için en az bir satır işaretleyin.';

  @override
  String get errorSelectAtLeastOneImage => 'En az bir görsel seçin.';

  @override
  String get errorMergeNeedsTwoFiles =>
      'Birleştirme için en az 2 PDF dosyası gerekir.';

  @override
  String get errorNewNameEmpty => 'Yeni ad boş olamaz.';

  @override
  String get errorScanAtLeastOnePage => 'En az bir sayfa tarayın.';

  @override
  String get errorScanAtLeastOnePageFirst => 'Önce en az bir sayfa tarayın.';

  @override
  String get errorProvideAtLeastOneRange =>
      'Bölmek için en az bir sayfa aralığı belirtin.';

  @override
  String errorInvalidPageRange(Object range) {
    return 'Geçersiz sayfa aralığı: $range';
  }

  @override
  String errorRangeExceedsPageCount(Object range, Object pageCount) {
    return '$range aralığı belge sayfa sayısını ($pageCount) aşıyor.';
  }

  @override
  String get errorEnterWatermarkText => 'Filigran metni girin.';

  @override
  String get errorAddSignatureFirst => 'Önce bir imza ekleyin.';

  @override
  String errorPageIndexOutOfRange(Object index, Object max) {
    return 'Sayfa dizini $index aralık dışında (0-$max).';
  }

  @override
  String get errorWrongPasswordOrNotProtected =>
      'Yanlış parola veya bu PDF parola korumalı değil.';

  @override
  String get errorUnsupportedImageFormat =>
      'Bu görsel formatı desteklenmiyor. Bunun yerine bir JPEG veya PNG deneyin.';

  @override
  String get mergeTitle => 'PDF\'leri Birleştir';

  @override
  String get mergeDescription =>
      'Birden fazla PDF dosyasını istediğiniz sırayla tek bir belgede birleştirin.';

  @override
  String get mergeStepAdd => 'Dosya ekle';

  @override
  String get mergeStepReorder => 'Yeniden sırala';

  @override
  String get mergeStepMerge => 'Birleştir';

  @override
  String get mergeStepSave => 'Kaydet';

  @override
  String get mergeAddFiles => 'PDF dosyaları ekle';

  @override
  String get mergeAddFilesHint =>
      'Birden fazla dosyayı aynı anda seçebilirsiniz';

  @override
  String mergeFileCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosya',
      one: '1 dosya',
    );
    return '$_temp0 — sıralamak için sürükleyin';
  }

  @override
  String get addMore => 'Daha fazla ekle';

  @override
  String get mergeButtonNeedsMore => 'Birleştirmek için en az 2 dosya ekleyin';

  @override
  String mergeButtonReady(Object count) {
    return '$count dosyayı birleştir';
  }

  @override
  String get mergeSuccess => 'Başarıyla birleştirildi';

  @override
  String get splitTitle => 'PDF Böl';

  @override
  String get splitDescription =>
      'Bir PDF\'yi ayrı dosyalara bölün — sayfaya veya özel aralıklara göre.';

  @override
  String get splitStepSelect => 'PDF seç';

  @override
  String get splitStepChoose => 'Sayfaları seç';

  @override
  String get splitStepSplit => 'Böl';

  @override
  String get splitStepSave => 'Kaydet';

  @override
  String splitPageCountHint(Object count) {
    return '$count sayfa — dosyayı değiştirmek için dokunun';
  }

  @override
  String get splitOneFilePerPage => 'Her sayfa için bir dosyaya böl';

  @override
  String get splitPageRanges => 'Sayfa aralıkları';

  @override
  String get splitPageRangesHint => 'örn. 1-3, 5, 7-9';

  @override
  String get splitButton => 'Böl';

  @override
  String splitFilesCreated(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosya oluşturuldu',
      one: '1 dosya oluşturuldu',
    );
    return '$_temp0';
  }

  @override
  String get shareZip => 'ZIP Paylaş';

  @override
  String get downloadZip => 'ZIP İndir';

  @override
  String get compressTitle => 'PDF Sıkıştır';

  @override
  String get compressDescription =>
      'Daha kolay paylaşım için PDF dosya boyutunu üç kalite seviyesiyle küçültün.';

  @override
  String get compressStepSelect => 'PDF seç';

  @override
  String get compressStepLevel => 'Seviye seç';

  @override
  String get compressStepCompress => 'Sıkıştır';

  @override
  String get compressStepSave => 'Kaydet';

  @override
  String compressOriginalSizeHint(Object size) {
    return 'Orijinal boyut: $size — dosyayı değiştirmek için dokunun';
  }

  @override
  String get compressLow => 'Düşük';

  @override
  String get compressMedium => 'Orta';

  @override
  String get compressHigh => 'Yüksek';

  @override
  String get compressHighWarning =>
      'Yüksek, her sayfayı görsel olarak yeniden oluşturur — taramalar/fotoğraflar için en iyi boyut küçültmesidir, ancak sonuç seçilebilir/aranabilir metni kaybeder. Bunun ters teper olacağı metin ağırlıklı PDF\'lerde, sonucun asla orijinalden büyük olmaması için otomatik olarak başka bir yönteme geçilir.';

  @override
  String get compressButton => 'Sıkıştır';

  @override
  String compressReductionPercent(Object percent) {
    return '%$percent daha küçük';
  }

  @override
  String compressBeforeAfter(Object before, Object after) {
    return 'Önce: $before  →  Sonra: $after';
  }

  @override
  String get beforeLabel => 'Önce';

  @override
  String get afterLabel => 'Sonra';

  @override
  String get imagePdfTitle => 'Görsel ⇄ PDF';

  @override
  String get imagesToPdfDescription =>
      'Bir veya daha fazla fotoğrafı tek bir PDF belgesine dönüştürün.';

  @override
  String get pdfToImagesDescription =>
      'Bir PDF\'nin her sayfasını ayrı bir görsel dosyası olarak dışa aktarın.';

  @override
  String get imagePdfStepAddImages => 'Görsel ekle';

  @override
  String get imagePdfStepConvert => 'Dönüştür';

  @override
  String get imagePdfStepSave => 'Kaydet';

  @override
  String get imagePdfStepSelect => 'PDF seç';

  @override
  String get imagePdfStepFormat => 'Format seç';

  @override
  String get imagesToPdfSegment => 'Görsel → PDF';

  @override
  String get pdfToImagesSegment => 'PDF → Görsel';

  @override
  String get imagesWord => 'Görsel';

  @override
  String get pdfWordTitle => 'PDF ⇄ Word';

  @override
  String get pdfToWordDescription =>
      'Bir PDF\'nin metnini düzenlenebilir bir Word belgesine çıkarın.';

  @override
  String get wordToPdfDescription =>
      'Bir Word belgesinin metnini PDF\'ye dönüştürün.';

  @override
  String get pdfWordStepSelect => 'Dosya seç';

  @override
  String get pdfWordStepConvert => 'Dönüştür';

  @override
  String get pdfWordStepSave => 'Kaydet';

  @override
  String get wordWord => 'Word';

  @override
  String get selectAWordFile => 'Bir Word dosyası seçin';

  @override
  String get docCreatedSuccess => 'Word belgesi başarıyla oluşturuldu';

  @override
  String get errorSelectWordFirst => 'Önce bir Word dosyası seçin.';

  @override
  String get errorPdfHasNoExtractableText =>
      'Bu PDF\'de çıkarılacak metin yok.';

  @override
  String get errorWordHasNoExtractableText =>
      'Bu Word belgesinde çıkarılacak metin yok.';

  @override
  String get addImages => 'Görsel ekle';

  @override
  String get addImagesHint => 'Birden fazla fotoğrafı aynı anda seçebilirsiniz';

  @override
  String imagesSelectedCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count görsel seçildi',
      one: '1 görsel seçildi',
    );
    return '$_temp0';
  }

  @override
  String get pdfCreatedSuccess => 'PDF başarıyla oluşturuldu';

  @override
  String get convertButton => 'Dönüştür';

  @override
  String get convertButtonEmpty => 'Dönüştürmek için görsel ekleyin';

  @override
  String convertButtonReady(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count görseli dönüştür',
      one: '1 görseli dönüştür',
    );
    return '$_temp0';
  }

  @override
  String imagesCreatedCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count görsel oluşturuldu',
      one: '1 görsel oluşturuldu',
    );
    return '$_temp0';
  }

  @override
  String get scanTitle => 'Belge Tara';

  @override
  String get scanDescription =>
      'Kağıt belgelerin fotoğraflarını temiz bir PDF\'ye dönüştürün — kenar algılama ve kırpma tarama sırasında otomatik olarak yapılır.';

  @override
  String get scanStepScan => 'Tara';

  @override
  String get scanStepReorder => 'Yeniden sırala';

  @override
  String get scanStepCreatePdf => 'PDF oluştur';

  @override
  String get scanStepSave => 'Kaydet';

  @override
  String get scanADocument => 'Bir belge tara';

  @override
  String get scanHint =>
      'Kameranızı kullanır — kenarlar otomatik olarak algılanır ve kırpılır';

  @override
  String get openingCamera => 'Kamera açılıyor…';

  @override
  String get scanMore => 'Daha fazla tara';

  @override
  String get scanOcrToggleLabel => 'Metni aranabilir yap';

  @override
  String get scanOcrToggleHint =>
      'Cihaz üzerinde metin tanıma (yalnızca Latin alfabesi)';

  @override
  String scanPageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sayfa',
      one: '1 sayfa',
    );
    return '$_temp0 — sıralamak için sürükleyin';
  }

  @override
  String pageNumberLabel(Object number) {
    return 'Sayfa $number';
  }

  @override
  String get createPdfButton => 'PDF oluştur';

  @override
  String createPdfButtonReady(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sayfadan PDF oluştur',
      one: '1 sayfadan PDF oluştur',
    );
    return '$_temp0';
  }

  @override
  String get pageEditTitle => 'Sayfaları Düzenle';

  @override
  String get pageEditDescription =>
      'Bir PDF\'nin sayfalarını döndürün, yeniden sıralayın veya kaldırın — belgenin geri kalanı değişmeden kalır.';

  @override
  String get pageEditStepSelect => 'PDF seç';

  @override
  String get pageEditStepEdit => 'Sayfaları düzenle';

  @override
  String get pageEditStepSave => 'Değişiklikleri kaydet';

  @override
  String get rotate => 'Döndür';

  @override
  String get removePage => 'Sayfayı kaldır';

  @override
  String get saveChanges => 'Değişiklikleri kaydet';

  @override
  String get pdfSavedSuccess => 'PDF başarıyla kaydedildi';

  @override
  String get contentEditTitle => 'PDF Düzenle';

  @override
  String get contentEditDescription =>
      'Düzeltmek veya kaldırmak için bir satıra dokunun ya da bir görsel ekleyin — düzenlemeler sayfayı yeniden akıtmak yerine orijinal konumu kaplar.';

  @override
  String get contentEditStepSelect => 'PDF seç';

  @override
  String get contentEditStepEdit => 'Düzenlemek için dokunun';

  @override
  String get contentEditStepSave => 'Değişiklikleri kaydet';

  @override
  String get editLine => 'Satırı düzenle';

  @override
  String get lineText => 'Satır metni';

  @override
  String get delete => 'Sil';

  @override
  String get addImageToPage => 'Bu sayfaya görsel ekle';

  @override
  String get addImage => 'Görsel ekle';

  @override
  String get thisPdfHasNoPages => 'Bu PDF\'nin sayfası yok.';

  @override
  String get encryptTitle => 'Parola Koruması';

  @override
  String get encryptDescription =>
      'Bir PDF\'yi yalnızca bilenlerin açabilmesi için parolayla kilitleyin.';

  @override
  String get addPasswordSegment => 'Parola Ekle';

  @override
  String get removePasswordSegment => 'Parolayı Kaldır';

  @override
  String get password => 'Parola';

  @override
  String get currentPassword => 'Mevcut parola';

  @override
  String get confirmPassword => 'Parolayı onayla';

  @override
  String passwordHelperText(Object minLength) {
    return 'En az $minLength karakter, boşluk yok';
  }

  @override
  String get showPassword => 'Parolayı göster';

  @override
  String get hidePassword => 'Parolayı gizle';

  @override
  String get lockButton => 'Kilitle';

  @override
  String get unlockButton => 'Kilidi aç';

  @override
  String get passwordAdded => 'Parola eklendi';

  @override
  String get passwordRemoved => 'Parola kaldırıldı';

  @override
  String get watermarkTitle => 'Filigran';

  @override
  String get watermarkDescription =>
      'Metni her sayfaya çapraz olarak damgalayın — \"TASLAK\", \"GİZLİ\" veya bir şirket adı için harika.';

  @override
  String get watermarkStepSelect => 'PDF seç';

  @override
  String get watermarkStepText => 'Metni ayarla';

  @override
  String get watermarkStepStamp => 'Damgala';

  @override
  String get watermarkStepSave => 'Kaydet';

  @override
  String get watermarkText => 'Filigran metni';

  @override
  String get watermarkTextHint => 'örn. GİZLİ';

  @override
  String get color => 'Renk';

  @override
  String opacityPercent(Object percent) {
    return 'Opaklık: %$percent';
  }

  @override
  String sizeValue(Object size) {
    return 'Boyut: $size';
  }

  @override
  String get watermarkButton => 'Damgala';

  @override
  String get watermarkAdded => 'Filigran eklendi';

  @override
  String get signatureTitle => 'Dijital İmza';

  @override
  String get signatureDescription =>
      'Bir imza çizin veya yazın, herhangi bir sayfaya yerleştirin ve kaydedin.';

  @override
  String get signatureStepSelect => 'PDF seç';

  @override
  String get signatureStepCreate => 'İmza ayarla';

  @override
  String get signatureStepPlace => 'Yerleştir';

  @override
  String get signatureStepSave => 'İmzalı PDF\'yi kaydet';

  @override
  String get addSignature => 'İmza Ekle';

  @override
  String get changeSignature => 'İmzayı Değiştir';

  @override
  String get placeButton => 'Yerleştir';

  @override
  String get signButton => 'İmzala';

  @override
  String get pdfSignedSuccess => 'PDF başarıyla imzalandı';

  @override
  String get signaturePadDraw => 'Çiz';

  @override
  String get signaturePadType => 'Yaz';

  @override
  String get signaturePadCreateTitle => 'İmza Oluştur';

  @override
  String get signaturePadDrawHint => 'Parmağınızla veya fareyle imzalayın';

  @override
  String get signaturePadClear => 'Temizle';

  @override
  String get signaturePadColor => 'Renk';

  @override
  String get signaturePadStyle => 'Stil';

  @override
  String get signaturePadYourName => 'Adınız';

  @override
  String get signaturePadTypeYourName => 'Adınızı yazın';

  @override
  String get signaturePadDone => 'Tamam';

  @override
  String get signaturePadFontCasual => 'Rahat';

  @override
  String get signaturePadFontElegant => 'Zarif';

  @override
  String get signaturePadFontBold => 'Kalın';

  @override
  String get colorBlack => 'Siyah';

  @override
  String get colorBlue => 'Mavi';

  @override
  String get colorRed => 'Kırmızı';

  @override
  String get colorGreen => 'Yeşil';

  @override
  String get languagePickerTitle => 'Dilinizi seçin';

  @override
  String get languagePickerSubtitle =>
      'Bunu daha sonra ana ekrandan değiştirebilirsiniz.';

  @override
  String get languagePickerContinue => 'Devam et';

  @override
  String get changeFile => 'Dosyayı değiştir';

  @override
  String pageOfTotal(Object current, Object total) {
    return 'Sayfa $current / $total';
  }

  @override
  String get encryptRemoveDescription =>
      'Doğru parolayı bilerek bir PDF\'nin parolasını kaldırın.';

  @override
  String get encryptStepSetPassword => 'Parola belirle';

  @override
  String get encryptStepEnterPassword => 'Parolayı gir';

  @override
  String get featureRedactTitle => 'Karart';

  @override
  String get featureRedactSubtitle => 'Hassas metni kalıcı olarak kaldır';

  @override
  String get redactDescription =>
      'Kalıcı olarak kaldırmak istediğiniz satırlara dokunun, ardından onaylayın — yalnızca üzerini kapatan \"PDF Düzenle\" düzeltmesinin aksine, karartılan metin kurtarılamaz veya kopyalanamaz.';

  @override
  String get redactStepSelect => 'PDF seç';

  @override
  String get redactStepMark => 'İşaretlemek için dokun';

  @override
  String get redactStepConfirm => 'Kalıcı olarak karart';

  @override
  String redactMarkedCount(Object count) {
    return '$count satır karartma için işaretlendi';
  }

  @override
  String get redactConfirmTitle => 'Kalıcı olarak karartılsın mı?';

  @override
  String get redactConfirmBody =>
      'Bu işlem geri alınamaz. İşaretlenen metin yalnızca kapatılmaz, PDF\'den tamamen kaldırılır.';

  @override
  String get redactConfirmAction => 'Karart';

  @override
  String redactButtonLabel(Object count) {
    return 'Karart ($count)';
  }
}
