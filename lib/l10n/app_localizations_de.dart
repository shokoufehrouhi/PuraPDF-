// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'PuraPDF+';

  @override
  String get appTagline =>
      'Ihr PDF-Werkzeug — zusammenführen, teilen, komprimieren und konvertieren, alles auf dem Gerät.';

  @override
  String get categoryOrganize => 'Organisieren';

  @override
  String get categoryEditProtect => 'Bearbeiten & Schützen';

  @override
  String get recentsTooltip => 'Zuletzt verwendet';

  @override
  String get backToToolsTooltip => 'Zurück zu Werkzeugen';

  @override
  String get themeLightTooltip => 'Helles Design';

  @override
  String get themeDarkTooltip => 'Dunkles Design';

  @override
  String get languageTooltip => 'Sprache';

  @override
  String get featureMergeTitle => 'PDFs zusammenführen';

  @override
  String get featureMergeSubtitle => 'Mehrere Dokumente kombinieren';

  @override
  String get featureSplitTitle => 'PDF teilen';

  @override
  String get featureSplitSubtitle => 'In Seiten oder Abschnitte trennen';

  @override
  String get featureCompressTitle => 'PDF komprimieren';

  @override
  String get featureCompressSubtitle =>
      'Dateigröße für die Freigabe optimieren';

  @override
  String get featureImagePdfTitle => 'Bild ⇄ PDF';

  @override
  String get featureImagePdfSubtitle => 'Zwischen Formaten konvertieren';

  @override
  String get featurePdfWordTitle => 'PDF ⇄ Word';

  @override
  String get featurePdfWordSubtitle => 'In Word umwandeln und zurück';

  @override
  String get featureScanTitle => 'Dokument scannen';

  @override
  String get featureScanSubtitle => 'Papierdokumente mit der Kamera erfassen';

  @override
  String get featurePageEditTitle => 'Seiten bearbeiten';

  @override
  String get featurePageEditSubtitle =>
      'Seiten drehen, neu anordnen oder entfernen';

  @override
  String get featureContentEditTitle => 'PDF bearbeiten';

  @override
  String get featureContentEditSubtitle =>
      'Text korrigieren, Zeile entfernen, Bild hinzufügen';

  @override
  String get featureEncryptTitle => 'Passwortschutz';

  @override
  String get featureEncryptSubtitle => 'PDF-Passwort hinzufügen oder entfernen';

  @override
  String get featureWatermarkTitle => 'Wasserzeichen';

  @override
  String get featureWatermarkSubtitle => 'Text auf jeder Seite einfügen';

  @override
  String get featureSignatureTitle => 'Digitale Signatur';

  @override
  String get featureSignatureSubtitle =>
      'Signatur zeichnen oder eingeben, platzieren, speichern';

  @override
  String get recentsEmptyTitle => 'Noch keine Dateien';

  @override
  String get recentsEmptyBody =>
      'Dateien, die Sie mit Zusammenführen, Teilen, Komprimieren oder Bild ⇄ PDF erstellen, erscheinen hier.';

  @override
  String get browseTools => 'Werkzeuge durchsuchen';

  @override
  String get clear => 'Löschen';

  @override
  String get clearAllTitle => 'Alle zuletzt verwendeten Dateien löschen?';

  @override
  String get clearAllBody =>
      'Dadurch werden alle hier aufgeführten Dateien von Ihrem Gerät gelöscht. Dies kann nicht rückgängig gemacht werden.';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get clearAllConfirm => 'Alle löschen';

  @override
  String get opUnknown => 'Datei';

  @override
  String get opMerge => 'Zusammenführen';

  @override
  String get opSplit => 'Teilen';

  @override
  String get opCompress => 'Komprimieren';

  @override
  String get opImageToPdf => 'Bild → PDF';

  @override
  String get opPdfToImage => 'PDF → Bild';

  @override
  String get opScan => 'Scan';

  @override
  String get opPageEdit => 'Seiten bearbeiten';

  @override
  String get opContentEdit => 'PDF bearbeiten';

  @override
  String get opLocked => 'Gesperrt';

  @override
  String get opUnlocked => 'Entsperrt';

  @override
  String get opWatermark => 'Wasserzeichen';

  @override
  String get opSigned => 'Signiert';

  @override
  String get share => 'Teilen';

  @override
  String get download => 'Herunterladen';

  @override
  String get startOver => 'Neu beginnen';

  @override
  String get save => 'Speichern';

  @override
  String get remove => 'Entfernen';

  @override
  String get selectAPdf => 'PDF auswählen';

  @override
  String get selectPdf => 'PDF auswählen';

  @override
  String get tapToBrowseFiles => 'Tippen, um Dateien zu durchsuchen';

  @override
  String get tapToChangeFile => 'Tippen, um Datei zu ändern';

  @override
  String get previousPage => 'Vorherige Seite';

  @override
  String get nextPage => 'Nächste Seite';

  @override
  String downloadSavedToDownloads(Object fileName) {
    return 'In Downloads gespeichert: $fileName';
  }

  @override
  String downloadSaved(Object fileName) {
    return 'Gespeichert: $fileName';
  }

  @override
  String get downloadCancelled => 'Abgebrochen';

  @override
  String get downloadNoDirectory => 'Kein Downloads-Ordner verfügbar';

  @override
  String get errorGeneric =>
      'Etwas ist schiefgelaufen. Bitte versuchen Sie es erneut.';

  @override
  String get errorSelectPdfFirst => 'Wählen Sie zuerst ein PDF aus.';

  @override
  String get errorEnterPassword => 'Geben Sie ein Passwort ein.';

  @override
  String get errorEnterPdfPassword => 'Geben Sie das Passwort des PDFs ein.';

  @override
  String get errorPasswordNoSpaces =>
      'Das Passwort darf keine Leerzeichen enthalten.';

  @override
  String errorPasswordTooShort(Object minLength) {
    return 'Das Passwort muss mindestens $minLength Zeichen lang sein.';
  }

  @override
  String get errorPasswordsDontMatch => 'Die Passwörter stimmen nicht überein.';

  @override
  String get errorAtLeastOnePageMustRemain =>
      'Mindestens eine Seite muss erhalten bleiben.';

  @override
  String get errorAtLeastOnePageMustRemainInPdf =>
      'Mindestens eine Seite muss im PDF erhalten bleiben.';

  @override
  String get errorMakeAChangeBeforeSaving =>
      'Nehmen Sie vor dem Speichern mindestens eine Änderung vor.';

  @override
  String get errorSelectAtLeastOneImage =>
      'Wählen Sie mindestens ein Bild aus.';

  @override
  String get errorMergeNeedsTwoFiles =>
      'Zum Zusammenführen sind mindestens 2 PDF-Dateien erforderlich.';

  @override
  String get errorNewNameEmpty => 'Der neue Name darf nicht leer sein.';

  @override
  String get errorScanAtLeastOnePage => 'Scannen Sie mindestens eine Seite.';

  @override
  String get errorScanAtLeastOnePageFirst =>
      'Scannen Sie zuerst mindestens eine Seite.';

  @override
  String get errorProvideAtLeastOneRange =>
      'Geben Sie mindestens einen Seitenbereich zum Teilen an.';

  @override
  String errorInvalidPageRange(Object range) {
    return 'Ungültiger Seitenbereich: $range';
  }

  @override
  String errorRangeExceedsPageCount(Object range, Object pageCount) {
    return 'Bereich $range überschreitet die Seitenzahl des Dokuments ($pageCount).';
  }

  @override
  String get errorEnterWatermarkText =>
      'Geben Sie einen Wasserzeichentext ein.';

  @override
  String get errorAddSignatureFirst => 'Fügen Sie zuerst eine Signatur hinzu.';

  @override
  String errorPageIndexOutOfRange(Object index, Object max) {
    return 'Seitenindex $index außerhalb des Bereichs (0-$max).';
  }

  @override
  String get errorWrongPasswordOrNotProtected =>
      'Falsches Passwort, oder dieses PDF ist nicht passwortgeschützt.';

  @override
  String get errorUnsupportedImageFormat =>
      'Dieses Bildformat wird nicht unterstützt. Versuchen Sie stattdessen JPEG oder PNG.';

  @override
  String get mergeTitle => 'PDFs zusammenführen';

  @override
  String get mergeDescription =>
      'Kombinieren Sie mehrere PDF-Dateien in einer beliebigen Reihenfolge zu einem einzigen Dokument.';

  @override
  String get mergeStepAdd => 'Dateien hinzufügen';

  @override
  String get mergeStepReorder => 'Neu anordnen';

  @override
  String get mergeStepMerge => 'Zusammenführen';

  @override
  String get mergeStepSave => 'Speichern';

  @override
  String get mergeAddFiles => 'PDF-Dateien hinzufügen';

  @override
  String get mergeAddFilesHint =>
      'Sie können mehrere Dateien gleichzeitig auswählen';

  @override
  String mergeFileCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Dateien',
      one: '1 Datei',
    );
    return '$_temp0 — zum Neuanordnen ziehen';
  }

  @override
  String get addMore => 'Mehr hinzufügen';

  @override
  String get mergeButtonNeedsMore =>
      'Mindestens 2 Dateien zum Zusammenführen hinzufügen';

  @override
  String mergeButtonReady(Object count) {
    return '$count Dateien zusammenführen';
  }

  @override
  String get mergeSuccess => 'Erfolgreich zusammengeführt';

  @override
  String get splitTitle => 'PDF teilen';

  @override
  String get splitDescription =>
      'Teilen Sie ein PDF in separate Dateien — nach Seite oder nach benutzerdefinierten Bereichen.';

  @override
  String get splitStepSelect => 'PDF auswählen';

  @override
  String get splitStepChoose => 'Seiten wählen';

  @override
  String get splitStepSplit => 'Teilen';

  @override
  String get splitStepSave => 'Speichern';

  @override
  String splitPageCountHint(Object count) {
    return '$count Seiten — tippen, um die Datei zu ändern';
  }

  @override
  String get splitOneFilePerPage => 'In eine Datei pro Seite teilen';

  @override
  String get splitPageRanges => 'Seitenbereiche';

  @override
  String get splitPageRangesHint => 'z. B. 1-3, 5, 7-9';

  @override
  String get splitButton => 'Teilen';

  @override
  String splitFilesCreated(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Dateien erstellt',
      one: '1 Datei erstellt',
    );
    return '$_temp0';
  }

  @override
  String get shareZip => 'ZIP teilen';

  @override
  String get downloadZip => 'ZIP herunterladen';

  @override
  String get compressTitle => 'PDF komprimieren';

  @override
  String get compressDescription =>
      'Verkleinern Sie die Dateigröße eines PDFs für einfacheres Teilen, mit drei Qualitätsstufen.';

  @override
  String get compressStepSelect => 'PDF auswählen';

  @override
  String get compressStepLevel => 'Stufe wählen';

  @override
  String get compressStepCompress => 'Komprimieren';

  @override
  String get compressStepSave => 'Speichern';

  @override
  String compressOriginalSizeHint(Object size) {
    return 'Originalgröße: $size — tippen, um die Datei zu ändern';
  }

  @override
  String get compressLow => 'Niedrig';

  @override
  String get compressMedium => 'Mittel';

  @override
  String get compressHigh => 'Hoch';

  @override
  String get compressHighWarning =>
      '\"Hoch\" baut jede Seite als Bild neu auf — beste Größenreduzierung bei Scans/Fotos, aber das Ergebnis verliert auswähl-/durchsuchbaren Text. Bei textlastigen PDFs, bei denen das nach hinten losgehen würde, wird automatisch auf eine Alternative umgeschaltet, damit das Ergebnis nie größer als das Original ist.';

  @override
  String get compressButton => 'Komprimieren';

  @override
  String compressReductionPercent(Object percent) {
    return '$percent% kleiner';
  }

  @override
  String compressBeforeAfter(Object before, Object after) {
    return 'Vorher: $before  →  Nachher: $after';
  }

  @override
  String get beforeLabel => 'Vorher';

  @override
  String get afterLabel => 'Nachher';

  @override
  String get imagePdfTitle => 'Bild ⇄ PDF';

  @override
  String get imagesToPdfDescription =>
      'Verwandeln Sie ein oder mehrere Fotos in ein einziges PDF-Dokument.';

  @override
  String get pdfToImagesDescription =>
      'Exportieren Sie jede Seite eines PDFs als separate Bilddatei.';

  @override
  String get imagePdfStepAddImages => 'Bilder hinzufügen';

  @override
  String get imagePdfStepConvert => 'Konvertieren';

  @override
  String get imagePdfStepSave => 'Speichern';

  @override
  String get imagePdfStepSelect => 'PDF auswählen';

  @override
  String get imagePdfStepFormat => 'Format wählen';

  @override
  String get imagesToPdfSegment => 'Bilder → PDF';

  @override
  String get pdfToImagesSegment => 'PDF → Bilder';

  @override
  String get imagesWord => 'Bilder';

  @override
  String get pdfWordTitle => 'PDF ⇄ Word';

  @override
  String get pdfToWordDescription =>
      'Extrahieren Sie den Text eines PDFs in ein bearbeitbares Word-Dokument.';

  @override
  String get wordToPdfDescription =>
      'Wandeln Sie den Text eines Word-Dokuments in ein PDF um.';

  @override
  String get pdfWordStepSelect => 'Datei auswählen';

  @override
  String get pdfWordStepConvert => 'Umwandeln';

  @override
  String get pdfWordStepSave => 'Speichern';

  @override
  String get wordWord => 'Word';

  @override
  String get selectAWordFile => 'Word-Datei auswählen';

  @override
  String get docCreatedSuccess => 'Word-Dokument erfolgreich erstellt';

  @override
  String get errorSelectWordFirst => 'Wählen Sie zuerst eine Word-Datei aus.';

  @override
  String get errorPdfHasNoExtractableText =>
      'Dieses PDF enthält keinen extrahierbaren Text.';

  @override
  String get errorWordHasNoExtractableText =>
      'Dieses Word-Dokument enthält keinen extrahierbaren Text.';

  @override
  String get addImages => 'Bilder hinzufügen';

  @override
  String get addImagesHint => 'Sie können mehrere Fotos gleichzeitig auswählen';

  @override
  String imagesSelectedCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bilder ausgewählt',
      one: '1 Bild ausgewählt',
    );
    return '$_temp0';
  }

  @override
  String get pdfCreatedSuccess => 'PDF erfolgreich erstellt';

  @override
  String get convertButton => 'Konvertieren';

  @override
  String get convertButtonEmpty => 'Bilder zum Konvertieren hinzufügen';

  @override
  String convertButtonReady(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bilder konvertieren',
      one: '1 Bild konvertieren',
    );
    return '$_temp0';
  }

  @override
  String imagesCreatedCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bilder erstellt',
      one: '1 Bild erstellt',
    );
    return '$_temp0';
  }

  @override
  String get scanTitle => 'Dokument scannen';

  @override
  String get scanDescription =>
      'Verwandeln Sie Fotos von Papierdokumenten in ein sauberes PDF — Kantenerkennung und Zuschnitt erfolgen automatisch beim Scannen.';

  @override
  String get scanStepScan => 'Scannen';

  @override
  String get scanStepReorder => 'Neu anordnen';

  @override
  String get scanStepCreatePdf => 'PDF erstellen';

  @override
  String get scanStepSave => 'Speichern';

  @override
  String get scanADocument => 'Ein Dokument scannen';

  @override
  String get scanHint =>
      'Nutzt Ihre Kamera — Kanten werden automatisch erkannt und zugeschnitten';

  @override
  String get openingCamera => 'Kamera wird geöffnet…';

  @override
  String get scanMore => 'Mehr scannen';

  @override
  String get scanOcrToggleLabel => 'Text durchsuchbar machen';

  @override
  String get scanOcrToggleHint =>
      'Texterkennung auf dem Gerät (nur lateinische Schrift)';

  @override
  String scanPageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Seiten',
      one: '1 Seite',
    );
    return '$_temp0 — zum Neuanordnen ziehen';
  }

  @override
  String pageNumberLabel(Object number) {
    return 'Seite $number';
  }

  @override
  String get createPdfButton => 'PDF erstellen';

  @override
  String createPdfButtonReady(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'PDF aus $count Seiten erstellen',
      one: 'PDF aus 1 Seite erstellen',
    );
    return '$_temp0';
  }

  @override
  String get pageEditTitle => 'Seiten bearbeiten';

  @override
  String get pageEditDescription =>
      'Drehen, ordnen Sie Seiten eines PDFs neu an oder entfernen Sie sie — der Rest des Dokuments bleibt unverändert.';

  @override
  String get pageEditStepSelect => 'PDF auswählen';

  @override
  String get pageEditStepEdit => 'Seiten bearbeiten';

  @override
  String get pageEditStepSave => 'Änderungen speichern';

  @override
  String get rotate => 'Drehen';

  @override
  String get removePage => 'Seite entfernen';

  @override
  String get saveChanges => 'Änderungen speichern';

  @override
  String get pdfSavedSuccess => 'PDF erfolgreich gespeichert';

  @override
  String get contentEditTitle => 'PDF bearbeiten';

  @override
  String get contentEditDescription =>
      'Tippen Sie auf eine Zeile, um sie zu korrigieren oder zu entfernen, oder fügen Sie ein Bild ein — Änderungen überdecken die ursprüngliche Stelle, ohne die Seite neu fließen zu lassen.';

  @override
  String get contentEditStepSelect => 'PDF auswählen';

  @override
  String get contentEditStepEdit => 'Zum Bearbeiten tippen';

  @override
  String get contentEditStepSave => 'Änderungen speichern';

  @override
  String get editLine => 'Zeile bearbeiten';

  @override
  String get lineText => 'Zeilentext';

  @override
  String get delete => 'Löschen';

  @override
  String get addImageToPage => 'Bild zu dieser Seite hinzufügen';

  @override
  String get addImage => 'Bild hinzufügen';

  @override
  String get thisPdfHasNoPages => 'Dieses PDF hat keine Seiten.';

  @override
  String get encryptTitle => 'Passwortschutz';

  @override
  String get encryptDescription =>
      'Schützen Sie ein PDF mit einem Passwort, sodass es nur von Personen geöffnet werden kann, die es kennen.';

  @override
  String get addPasswordSegment => 'Passwort hinzufügen';

  @override
  String get removePasswordSegment => 'Passwort entfernen';

  @override
  String get password => 'Passwort';

  @override
  String get currentPassword => 'Aktuelles Passwort';

  @override
  String get confirmPassword => 'Passwort bestätigen';

  @override
  String passwordHelperText(Object minLength) {
    return 'Mindestens $minLength Zeichen, keine Leerzeichen';
  }

  @override
  String get showPassword => 'Passwort anzeigen';

  @override
  String get hidePassword => 'Passwort verbergen';

  @override
  String get lockButton => 'Sperren';

  @override
  String get unlockButton => 'Entsperren';

  @override
  String get passwordAdded => 'Passwort hinzugefügt';

  @override
  String get passwordRemoved => 'Passwort entfernt';

  @override
  String get watermarkTitle => 'Wasserzeichen';

  @override
  String get watermarkDescription =>
      'Stempeln Sie Text diagonal auf jede Seite — ideal für \"ENTWURF\", \"VERTRAULICH\" oder einen Firmennamen.';

  @override
  String get watermarkStepSelect => 'PDF auswählen';

  @override
  String get watermarkStepText => 'Text festlegen';

  @override
  String get watermarkStepStamp => 'Stempeln';

  @override
  String get watermarkStepSave => 'Speichern';

  @override
  String get watermarkText => 'Wasserzeichentext';

  @override
  String get watermarkTextHint => 'z. B. VERTRAULICH';

  @override
  String get color => 'Farbe';

  @override
  String opacityPercent(Object percent) {
    return 'Deckkraft: $percent%';
  }

  @override
  String sizeValue(Object size) {
    return 'Größe: $size';
  }

  @override
  String get watermarkButton => 'Stempeln';

  @override
  String get watermarkAdded => 'Wasserzeichen hinzugefügt';

  @override
  String get signatureTitle => 'Digitale Signatur';

  @override
  String get signatureDescription =>
      'Zeichnen oder tippen Sie eine Signatur, platzieren Sie sie auf einer beliebigen Seite und speichern Sie.';

  @override
  String get signatureStepSelect => 'PDF auswählen';

  @override
  String get signatureStepCreate => 'Signatur festlegen';

  @override
  String get signatureStepPlace => 'Platzieren';

  @override
  String get signatureStepSave => 'Signiertes PDF speichern';

  @override
  String get addSignature => 'Signatur hinzufügen';

  @override
  String get changeSignature => 'Signatur ändern';

  @override
  String get placeButton => 'Platzieren';

  @override
  String get signButton => 'Signieren';

  @override
  String get pdfSignedSuccess => 'PDF erfolgreich signiert';

  @override
  String get signaturePadDraw => 'Zeichnen';

  @override
  String get signaturePadType => 'Tippen';

  @override
  String get signaturePadCreateTitle => 'Signatur erstellen';

  @override
  String get signaturePadDrawHint =>
      'Signieren Sie mit dem Finger oder der Maus';

  @override
  String get signaturePadClear => 'Löschen';

  @override
  String get signaturePadColor => 'Farbe';

  @override
  String get signaturePadStyle => 'Stil';

  @override
  String get signaturePadYourName => 'Ihr Name';

  @override
  String get signaturePadTypeYourName => 'Geben Sie Ihren Namen ein';

  @override
  String get signaturePadDone => 'Fertig';

  @override
  String get signaturePadFontCasual => 'Locker';

  @override
  String get signaturePadFontElegant => 'Elegant';

  @override
  String get signaturePadFontBold => 'Fett';

  @override
  String get colorBlack => 'Schwarz';

  @override
  String get colorBlue => 'Blau';

  @override
  String get colorRed => 'Rot';

  @override
  String get colorGreen => 'Grün';

  @override
  String get languagePickerTitle => 'Wählen Sie Ihre Sprache';

  @override
  String get languagePickerSubtitle =>
      'Sie können dies später über den Startbildschirm ändern.';

  @override
  String get languagePickerContinue => 'Weiter';

  @override
  String get changeFile => 'Datei ändern';

  @override
  String pageOfTotal(Object current, Object total) {
    return 'Seite $current von $total';
  }

  @override
  String get encryptRemoveDescription =>
      'Entfernen Sie das Passwort eines PDFs, wenn Sie das richtige kennen.';

  @override
  String get encryptStepSetPassword => 'Passwort festlegen';

  @override
  String get encryptStepEnterPassword => 'Passwort eingeben';
}
