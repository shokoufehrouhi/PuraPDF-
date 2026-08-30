// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'PuraPDF+';

  @override
  String get appTagline =>
      'Tu kit de herramientas PDF — combina, divide, comprime y convierte, todo en el dispositivo.';

  @override
  String get categoryOrganize => 'Organizar';

  @override
  String get categoryEditProtect => 'Editar y Proteger';

  @override
  String get recentsTooltip => 'Recientes';

  @override
  String get backToToolsTooltip => 'Volver a herramientas';

  @override
  String get themeLightTooltip => 'Tema claro';

  @override
  String get themeDarkTooltip => 'Tema oscuro';

  @override
  String get languageTooltip => 'Idioma';

  @override
  String get featureMergeTitle => 'Combinar PDFs';

  @override
  String get featureMergeSubtitle => 'Combinar varios documentos';

  @override
  String get featureSplitTitle => 'Dividir PDF';

  @override
  String get featureSplitSubtitle => 'Separar en páginas o secciones';

  @override
  String get featureCompressTitle => 'Comprimir PDF';

  @override
  String get featureCompressSubtitle => 'Optimizar el tamaño para compartir';

  @override
  String get featureImagePdfTitle => 'Imagen ⇄ PDF';

  @override
  String get featureImagePdfSubtitle => 'Convertir entre formatos';

  @override
  String get featurePdfWordTitle => 'PDF ⇄ Word';

  @override
  String get featurePdfWordSubtitle => 'Convierte a Word y viceversa';

  @override
  String get featureScanTitle => 'Escanear documento';

  @override
  String get featureScanSubtitle => 'Captura documentos en papel con tu cámara';

  @override
  String get featurePageEditTitle => 'Editar páginas';

  @override
  String get featurePageEditSubtitle => 'Rotar, reordenar o eliminar páginas';

  @override
  String get featureContentEditTitle => 'Editar PDF';

  @override
  String get featureContentEditSubtitle =>
      'Corregir texto, eliminar una línea, añadir imagen';

  @override
  String get featureEncryptTitle => 'Proteger con contraseña';

  @override
  String get featureEncryptSubtitle => 'Añadir o quitar una contraseña de PDF';

  @override
  String get featureWatermarkTitle => 'Marca de agua';

  @override
  String get featureWatermarkSubtitle => 'Estampar texto en cada página';

  @override
  String get featureSignatureTitle => 'Firma digital';

  @override
  String get featureSignatureSubtitle =>
      'Dibuja o escribe una firma, colócala, guarda';

  @override
  String get recentsEmptyTitle => 'Aún no hay archivos';

  @override
  String get recentsEmptyBody =>
      'Los archivos que crees con Combinar, Dividir, Comprimir o Imagen ⇄ PDF aparecerán aquí.';

  @override
  String get browseTools => 'Explorar herramientas';

  @override
  String get clear => 'Borrar';

  @override
  String get clearAllTitle => '¿Borrar todos los recientes?';

  @override
  String get clearAllBody =>
      'Esto elimina todos los archivos listados aquí de tu dispositivo. Esta acción no se puede deshacer.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get clearAllConfirm => 'Borrar todo';

  @override
  String get opUnknown => 'Archivo';

  @override
  String get opMerge => 'Combinar';

  @override
  String get opSplit => 'Dividir';

  @override
  String get opCompress => 'Comprimir';

  @override
  String get opImageToPdf => 'Imagen → PDF';

  @override
  String get opPdfToImage => 'PDF → Imagen';

  @override
  String get opScan => 'Escaneo';

  @override
  String get opPageEdit => 'Editar páginas';

  @override
  String get opContentEdit => 'Editar PDF';

  @override
  String get opRedact => 'Ocultar texto';

  @override
  String get opFillSign => 'Rellenado';

  @override
  String get opLocked => 'Bloqueado';

  @override
  String get opUnlocked => 'Desbloqueado';

  @override
  String get opWatermark => 'Marca de agua';

  @override
  String get opSigned => 'Firmado';

  @override
  String get share => 'Compartir';

  @override
  String get download => 'Descargar';

  @override
  String get startOver => 'Empezar de nuevo';

  @override
  String get save => 'Guardar';

  @override
  String get remove => 'Quitar';

  @override
  String get selectAPdf => 'Seleccionar un PDF';

  @override
  String get selectPdf => 'Seleccionar PDF';

  @override
  String get tapToBrowseFiles => 'Toca para explorar tus archivos';

  @override
  String get tapToChangeFile => 'Toca para cambiar de archivo';

  @override
  String get previousPage => 'Página anterior';

  @override
  String get nextPage => 'Página siguiente';

  @override
  String downloadSavedToDownloads(Object fileName) {
    return 'Guardado en Descargas: $fileName';
  }

  @override
  String downloadSaved(Object fileName) {
    return 'Guardado: $fileName';
  }

  @override
  String get downloadCancelled => 'Cancelado';

  @override
  String get downloadNoDirectory => 'No hay carpeta de Descargas disponible';

  @override
  String get errorGeneric => 'Algo salió mal. Inténtalo de nuevo.';

  @override
  String get errorSelectPdfFirst => 'Selecciona primero un PDF.';

  @override
  String get errorEnterPassword => 'Introduce una contraseña.';

  @override
  String get errorEnterPdfPassword => 'Introduce la contraseña del PDF.';

  @override
  String get errorPasswordNoSpaces =>
      'La contraseña no puede contener espacios.';

  @override
  String errorPasswordTooShort(Object minLength) {
    return 'La contraseña debe tener al menos $minLength caracteres.';
  }

  @override
  String get errorPasswordsDontMatch => 'Las contraseñas no coinciden.';

  @override
  String get errorAtLeastOnePageMustRemain =>
      'Debe quedar al menos una página.';

  @override
  String get errorAtLeastOnePageMustRemainInPdf =>
      'Debe quedar al menos una página en el PDF.';

  @override
  String get errorMakeAChangeBeforeSaving =>
      'Haz al menos un cambio antes de guardar.';

  @override
  String get errorMarkAtLeastOneLineToRedact =>
      'Marca al menos una línea para tachar.';

  @override
  String get errorFillAtLeastOneFieldFirst =>
      'Rellena al menos un campo primero.';

  @override
  String get errorSelectAtLeastOneImage => 'Selecciona al menos una imagen.';

  @override
  String get errorMergeNeedsTwoFiles =>
      'Combinar requiere al menos 2 archivos PDF.';

  @override
  String get errorNewNameEmpty => 'El nuevo nombre no puede estar vacío.';

  @override
  String get errorScanAtLeastOnePage => 'Escanea al menos una página.';

  @override
  String get errorScanAtLeastOnePageFirst =>
      'Escanea primero al menos una página.';

  @override
  String get errorProvideAtLeastOneRange =>
      'Indica al menos un rango de páginas para dividir.';

  @override
  String errorInvalidPageRange(Object range) {
    return 'Rango de páginas no válido: $range';
  }

  @override
  String errorRangeExceedsPageCount(Object range, Object pageCount) {
    return 'El rango $range supera el número de páginas del documento ($pageCount).';
  }

  @override
  String get errorEnterWatermarkText =>
      'Introduce el texto de la marca de agua.';

  @override
  String get errorAddSignatureFirst => 'Añade primero una firma.';

  @override
  String errorPageIndexOutOfRange(Object index, Object max) {
    return 'Índice de página $index fuera de rango (0-$max).';
  }

  @override
  String get errorWrongPasswordOrNotProtected =>
      'Contraseña incorrecta, o este PDF no está protegido con contraseña.';

  @override
  String get errorUnsupportedImageFormat =>
      'Este formato de imagen no es compatible. Prueba con un JPEG o PNG.';

  @override
  String get mergeTitle => 'Combinar PDFs';

  @override
  String get mergeDescription =>
      'Combina varios archivos PDF en un solo documento, en el orden que prefieras.';

  @override
  String get mergeStepAdd => 'Añadir archivos';

  @override
  String get mergeStepReorder => 'Reordenar';

  @override
  String get mergeStepMerge => 'Combinar';

  @override
  String get mergeStepSave => 'Guardar';

  @override
  String get mergeAddFiles => 'Añadir archivos PDF';

  @override
  String get mergeAddFilesHint => 'Puedes seleccionar varios archivos a la vez';

  @override
  String mergeFileCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count archivos',
      one: '1 archivo',
    );
    return '$_temp0 — arrastra para reordenar';
  }

  @override
  String get addMore => 'Añadir más';

  @override
  String get mergeButtonNeedsMore => 'Añade al menos 2 archivos para combinar';

  @override
  String mergeButtonReady(Object count) {
    return 'Combinar $count archivos';
  }

  @override
  String get mergeSuccess => 'Combinado correctamente';

  @override
  String get splitTitle => 'Dividir PDF';

  @override
  String get splitDescription =>
      'Divide un PDF en archivos separados — por página o por rangos personalizados.';

  @override
  String get splitStepSelect => 'Seleccionar PDF';

  @override
  String get splitStepChoose => 'Elegir páginas';

  @override
  String get splitStepSplit => 'Dividir';

  @override
  String get splitStepSave => 'Guardar';

  @override
  String splitPageCountHint(Object count) {
    return '$count páginas — toca para cambiar de archivo';
  }

  @override
  String get splitOneFilePerPage => 'Dividir en un archivo por página';

  @override
  String get splitPageRanges => 'Rangos de páginas';

  @override
  String get splitPageRangesHint => 'p. ej. 1-3, 5, 7-9';

  @override
  String get splitButton => 'Dividir';

  @override
  String splitFilesCreated(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count archivos creados',
      one: '1 archivo creado',
    );
    return '$_temp0';
  }

  @override
  String get shareZip => 'Compartir ZIP';

  @override
  String get downloadZip => 'Descargar ZIP';

  @override
  String get compressTitle => 'Comprimir PDF';

  @override
  String get compressDescription =>
      'Reduce el tamaño de un PDF para compartirlo más fácilmente, con tres niveles de calidad.';

  @override
  String get compressStepSelect => 'Seleccionar PDF';

  @override
  String get compressStepLevel => 'Elegir nivel';

  @override
  String get compressStepCompress => 'Comprimir';

  @override
  String get compressStepSave => 'Guardar';

  @override
  String compressOriginalSizeHint(Object size) {
    return 'Tamaño original: $size — toca para cambiar de archivo';
  }

  @override
  String get compressLow => 'Bajo';

  @override
  String get compressMedium => 'Medio';

  @override
  String get compressHigh => 'Alto';

  @override
  String get compressHighWarning =>
      'Alto reconstruye cada página como una imagen — la mejor reducción de tamaño para escaneos/fotos, pero el resultado pierde el texto seleccionable/buscable. En PDFs con mucho texto donde esto sería contraproducente, se cambia automáticamente a otro método para que el resultado nunca sea más grande que el original.';

  @override
  String get compressButton => 'Comprimir';

  @override
  String compressReductionPercent(Object percent) {
    return '$percent% más pequeño';
  }

  @override
  String compressBeforeAfter(Object before, Object after) {
    return 'Antes: $before  →  Después: $after';
  }

  @override
  String get beforeLabel => 'Antes';

  @override
  String get afterLabel => 'Después';

  @override
  String get imagePdfTitle => 'Imagen ⇄ PDF';

  @override
  String get imagesToPdfDescription =>
      'Convierte una o varias fotos en un solo documento PDF.';

  @override
  String get pdfToImagesDescription =>
      'Exporta cada página de un PDF como un archivo de imagen independiente.';

  @override
  String get imagePdfStepAddImages => 'Añadir imágenes';

  @override
  String get imagePdfStepConvert => 'Convertir';

  @override
  String get imagePdfStepSave => 'Guardar';

  @override
  String get imagePdfStepSelect => 'Seleccionar PDF';

  @override
  String get imagePdfStepFormat => 'Elegir formato';

  @override
  String get imagesToPdfSegment => 'Imágenes → PDF';

  @override
  String get pdfToImagesSegment => 'PDF → Imágenes';

  @override
  String get imagesWord => 'Imágenes';

  @override
  String get pdfWordTitle => 'PDF ⇄ Word';

  @override
  String get pdfToWordDescription =>
      'Extrae el texto de un PDF a un documento de Word editable.';

  @override
  String get wordToPdfDescription =>
      'Convierte el texto de un documento de Word en un PDF.';

  @override
  String get pdfWordStepSelect => 'Seleccionar archivo';

  @override
  String get pdfWordStepConvert => 'Convertir';

  @override
  String get pdfWordStepSave => 'Guardar';

  @override
  String get wordWord => 'Word';

  @override
  String get selectAWordFile => 'Selecciona un archivo de Word';

  @override
  String get docCreatedSuccess => 'Documento de Word creado correctamente';

  @override
  String get errorSelectWordFirst => 'Selecciona primero un archivo de Word.';

  @override
  String get errorPdfHasNoExtractableText =>
      'Este PDF no tiene texto para extraer.';

  @override
  String get errorWordHasNoExtractableText =>
      'Este documento de Word no tiene texto para extraer.';

  @override
  String get addImages => 'Añadir imágenes';

  @override
  String get addImagesHint => 'Puedes seleccionar varias fotos a la vez';

  @override
  String imagesSelectedCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count imágenes seleccionadas',
      one: '1 imagen seleccionada',
    );
    return '$_temp0';
  }

  @override
  String get pdfCreatedSuccess => 'PDF creado correctamente';

  @override
  String get convertButton => 'Convertir';

  @override
  String get convertButtonEmpty => 'Añade imágenes para convertir';

  @override
  String convertButtonReady(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Convertir $count imágenes',
      one: 'Convertir 1 imagen',
    );
    return '$_temp0';
  }

  @override
  String imagesCreatedCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count imágenes creadas',
      one: '1 imagen creada',
    );
    return '$_temp0';
  }

  @override
  String get scanTitle => 'Escanear documento';

  @override
  String get scanDescription =>
      'Convierte fotos de documentos en papel en un PDF nítido — la detección de bordes y el recorte se hacen automáticamente al escanear.';

  @override
  String get scanStepScan => 'Escanear';

  @override
  String get scanStepReorder => 'Reordenar';

  @override
  String get scanStepCreatePdf => 'Crear PDF';

  @override
  String get scanStepSave => 'Guardar';

  @override
  String get scanADocument => 'Escanear un documento';

  @override
  String get scanHint =>
      'Usa tu cámara — los bordes se detectan y recortan automáticamente';

  @override
  String get openingCamera => 'Abriendo cámara…';

  @override
  String get scanMore => 'Escanear más';

  @override
  String get scanOcrToggleLabel => 'Hacer el texto buscable';

  @override
  String get scanOcrToggleHint =>
      'Reconocimiento de texto en el dispositivo (solo alfabeto latino)';

  @override
  String scanPageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count páginas',
      one: '1 página',
    );
    return '$_temp0 — arrastra para reordenar';
  }

  @override
  String pageNumberLabel(Object number) {
    return 'Página $number';
  }

  @override
  String get createPdfButton => 'Crear PDF';

  @override
  String createPdfButtonReady(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Crear PDF de $count páginas',
      one: 'Crear PDF de 1 página',
    );
    return '$_temp0';
  }

  @override
  String get pageEditTitle => 'Editar páginas';

  @override
  String get pageEditDescription =>
      'Rota, reordena o elimina páginas de un PDF — el resto del documento permanece intacto.';

  @override
  String get pageEditStepSelect => 'Seleccionar PDF';

  @override
  String get pageEditStepEdit => 'Editar páginas';

  @override
  String get pageEditStepSave => 'Guardar cambios';

  @override
  String get rotate => 'Rotar';

  @override
  String get removePage => 'Eliminar página';

  @override
  String get saveChanges => 'Guardar cambios';

  @override
  String get pdfSavedSuccess => 'PDF guardado correctamente';

  @override
  String get contentEditTitle => 'Editar PDF';

  @override
  String get contentEditDescription =>
      'Toca una línea para corregirla o eliminarla, o añade una imagen — las ediciones cubren el lugar original en lugar de reajustar la página.';

  @override
  String get contentEditStepSelect => 'Seleccionar PDF';

  @override
  String get contentEditStepEdit => 'Toca para editar';

  @override
  String get contentEditStepSave => 'Guardar cambios';

  @override
  String get editLine => 'Editar línea';

  @override
  String get lineText => 'Texto de la línea';

  @override
  String get delete => 'Eliminar';

  @override
  String get addImageToPage => 'Añadir imagen a esta página';

  @override
  String get addImage => 'Añadir imagen';

  @override
  String get thisPdfHasNoPages => 'Este PDF no tiene páginas.';

  @override
  String get thisPdfHasNoFormFields =>
      'Este PDF no tiene campos de formulario rellenables.';

  @override
  String get encryptTitle => 'Proteger con contraseña';

  @override
  String get encryptDescription =>
      'Bloquea un PDF con una contraseña para que solo quienes la conozcan puedan abrirlo.';

  @override
  String get addPasswordSegment => 'Añadir contraseña';

  @override
  String get removePasswordSegment => 'Quitar contraseña';

  @override
  String get password => 'Contraseña';

  @override
  String get currentPassword => 'Contraseña actual';

  @override
  String get confirmPassword => 'Confirmar contraseña';

  @override
  String passwordHelperText(Object minLength) {
    return 'Al menos $minLength caracteres, sin espacios';
  }

  @override
  String get showPassword => 'Mostrar contraseña';

  @override
  String get hidePassword => 'Ocultar contraseña';

  @override
  String get lockButton => 'Bloquear';

  @override
  String get unlockButton => 'Desbloquear';

  @override
  String get passwordAdded => 'Contraseña añadida';

  @override
  String get passwordRemoved => 'Contraseña eliminada';

  @override
  String get watermarkTitle => 'Marca de agua';

  @override
  String get watermarkDescription =>
      'Estampa texto en diagonal en cada página — ideal para \"BORRADOR\", \"CONFIDENCIAL\" o el nombre de una empresa.';

  @override
  String get watermarkStepSelect => 'Seleccionar PDF';

  @override
  String get watermarkStepText => 'Definir texto';

  @override
  String get watermarkStepStamp => 'Estampar';

  @override
  String get watermarkStepSave => 'Guardar';

  @override
  String get watermarkText => 'Texto de la marca de agua';

  @override
  String get watermarkTextHint => 'p. ej. CONFIDENCIAL';

  @override
  String get color => 'Color';

  @override
  String opacityPercent(Object percent) {
    return 'Opacidad: $percent%';
  }

  @override
  String sizeValue(Object size) {
    return 'Tamaño: $size';
  }

  @override
  String get watermarkButton => 'Estampar';

  @override
  String get watermarkAdded => 'Marca de agua añadida';

  @override
  String get signatureTitle => 'Firma digital';

  @override
  String get signatureDescription =>
      'Dibuja o escribe una firma, colócala en cualquier página y guarda.';

  @override
  String get signatureStepSelect => 'Seleccionar PDF';

  @override
  String get signatureStepCreate => 'Definir firma';

  @override
  String get signatureStepPlace => 'Colocar';

  @override
  String get signatureStepSave => 'Guardar PDF firmado';

  @override
  String get addSignature => 'Añadir firma';

  @override
  String get changeSignature => 'Cambiar firma';

  @override
  String get placeButton => 'Colocar';

  @override
  String get signButton => 'Firmar';

  @override
  String get pdfSignedSuccess => 'PDF firmado correctamente';

  @override
  String get signaturePadDraw => 'Dibujar';

  @override
  String get signaturePadType => 'Escribir';

  @override
  String get signaturePadCreateTitle => 'Crear firma';

  @override
  String get signaturePadDrawHint => 'Firma con el dedo o el ratón';

  @override
  String get signaturePadClear => 'Borrar';

  @override
  String get signaturePadColor => 'Color';

  @override
  String get signaturePadStyle => 'Estilo';

  @override
  String get signaturePadYourName => 'Tu nombre';

  @override
  String get signaturePadTypeYourName => 'Escribe tu nombre';

  @override
  String get signaturePadDone => 'Listo';

  @override
  String get signaturePadFontCasual => 'Informal';

  @override
  String get signaturePadFontElegant => 'Elegante';

  @override
  String get signaturePadFontBold => 'Negrita';

  @override
  String get colorBlack => 'Negro';

  @override
  String get colorBlue => 'Azul';

  @override
  String get colorRed => 'Rojo';

  @override
  String get colorGreen => 'Verde';

  @override
  String get languagePickerTitle => 'Elige tu idioma';

  @override
  String get languagePickerSubtitle =>
      'Puedes cambiarlo más tarde desde la pantalla principal.';

  @override
  String get languagePickerContinue => 'Continuar';

  @override
  String get changeFile => 'Cambiar archivo';

  @override
  String pageOfTotal(Object current, Object total) {
    return 'Página $current de $total';
  }

  @override
  String get encryptRemoveDescription =>
      'Elimina la contraseña de un PDF, si conoces la correcta.';

  @override
  String get encryptStepSetPassword => 'Definir contraseña';

  @override
  String get encryptStepEnterPassword => 'Introducir contraseña';

  @override
  String get featureRedactTitle => 'Ocultar texto';

  @override
  String get featureRedactSubtitle =>
      'Elimina texto sensible de forma permanente';

  @override
  String get redactDescription =>
      'Toca las líneas que quieras eliminar de forma permanente y confirma — a diferencia del arreglo de Editar PDF (que solo cubre), el texto ocultado no se puede recuperar ni copiar.';

  @override
  String get redactStepSelect => 'Selecciona un PDF';

  @override
  String get redactStepMark => 'Toca para marcar';

  @override
  String get redactStepConfirm => 'Ocultar de forma permanente';

  @override
  String redactMarkedCount(Object count) {
    return '$count marcada(s) para ocultar';
  }

  @override
  String get redactConfirmTitle => '¿Ocultar de forma permanente?';

  @override
  String get redactConfirmBody =>
      'Esto no se puede deshacer. El texto marcado se eliminará por completo del PDF, no solo se cubrirá.';

  @override
  String get redactConfirmAction => 'Ocultar';

  @override
  String redactButtonLabel(Object count) {
    return 'Ocultar ($count)';
  }

  @override
  String get featureFillSignTitle => 'Rellenar y firmar';

  @override
  String get featureFillSignSubtitle => 'Rellena campos reales del formulario';

  @override
  String get fillSignDescription =>
      'Toca los campos de texto y casillas reales de un formulario para rellenarlos y luego guarda — los valores rellenados se integran de forma permanente en la página, no quedan como una capa editable aparte.';

  @override
  String get fillSignStepSelect => 'Selecciona un PDF';

  @override
  String get fillSignStepFill => 'Toca para rellenar';

  @override
  String get fillSignStepConfirm => 'Guardar de forma permanente';

  @override
  String fillSignButtonLabel(Object count) {
    return 'Rellenar y firmar ($count)';
  }
}
