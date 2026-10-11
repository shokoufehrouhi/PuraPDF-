// Walks every screen and step of the app and saves a PNG of each one, for
// documentation / store assets. Not a correctness test. Run with:
//   flutter test integration_test/screenshots_test.dart -d macos
//
// Runs on macOS (no emulator needed) but renders at a phone-sized logical
// viewport with the platform overridden to Android, so the screens look
// like the Play build. System pickers and the document scanner are
// replaced by fakes that hand back generated sample files; ads are stubbed.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cross_file/cross_file.dart';
import 'package:doclens/doclens.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:purapdf/l10n/app_localizations.dart';
import 'package:purapdf/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

final GlobalKey _shotKey = GlobalKey();
late Directory _outDir;
late Directory _dataDir;
final AppLocalizations l = lookupAppLocalizations(const Locale('en'));

// ---------------------------------------------------------------- fakes --

final class _FakeFile extends PlatformFile {
  _FakeFile(this._path);
  final String _path;

  @override
  String get name => _path.split('/').last;
  @override
  Uri get uri => Uri.file(_path);
  @override
  XFile get xFile => XFile(_path);
  @override
  Future<int> length() => File(_path).length();
  @override
  Future<Uint8List> readAsBytes() => File(_path).readAsBytes();
  @override
  Stream<Uint8List> readAsByteStream() =>
      File(_path).openRead().map(Uint8List.fromList);
}

class _FakePicker extends FilePickerPlatform {
  List<String> next = [];
  String? lastSaved;

  @override
  Future<List<PlatformFile>> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    final files = [for (final p in next) _FakeFile(p)];
    next = [];
    return files;
  }

  @override
  Future<PlatformFile?> pickFile({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    final files = await pickFiles();
    return files.isEmpty ? null : files.first;
  }

  @override
  Future<Uri?> saveFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    String? dialogTitle,
    String? initialDirectory,
    Function(FilePickerStatus)? onFileSaving,
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    final dir = Directory('${_dataDir.path}/saved')..createSync();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    lastSaved = file.path;
    return file.uri;
  }
}

class _FakeDoclens extends DoclensPlatform {
  List<String> pages = [];

  @override
  Future<List<String>?> scanWithNativeUI({
    int pageLimit = 100,
    bool allowGalleryImport = false,
    int jpegQuality = 100,
  }) async => pages;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

// ---------------------------------------------------------- sample data --

const _paragraphs = [
  'This proposal outlines the plan to redesign the customer portal and '
      'move our document workflow fully online.',
  'Phase one covers research and interviews with twelve key customers. '
      'Phase two delivers the new dashboard and reporting tools.',
  'The total budget is 48,500 USD, split evenly across both phases, with '
      'a final review scheduled for the end of the second quarter.',
  'Contact: Sarah Miller, Project Lead - sarah.miller@example.com',
];

Future<String> _writeTextPdf(
  String name, {
  required String title,
  int pages = 3,
  PdfColor? accent,
}) async {
  accent ??= PdfColor(76, 61, 220);
  final doc = PdfDocument();
  doc.pageSettings.size = PdfPageSize.a4;
  doc.pageSettings.margins.all = 0;
  final titleFont = PdfStandardFont(
    PdfFontFamily.helvetica,
    26,
    style: PdfFontStyle.bold,
  );
  final headFont = PdfStandardFont(
    PdfFontFamily.helvetica,
    16,
    style: PdfFontStyle.bold,
  );
  final bodyFont = PdfStandardFont(PdfFontFamily.helvetica, 12);
  for (int i = 0; i < pages; i++) {
    final page = doc.pages.add();
    final g = page.graphics;
    final w = page.getClientSize().width;
    g.drawRectangle(
      brush: PdfSolidBrush(accent),
      bounds: Rect.fromLTWH(0, 0, w, 14),
    );
    g.drawString(
      i == 0 ? title : '$title - Part ${i + 1}',
      titleFont,
      bounds: Rect.fromLTWH(50, 50, w - 100, 40),
    );
    double y = 110;
    for (int s = 0; s < 3; s++) {
      g.drawString(
        'Section ${i * 3 + s + 1}',
        headFont,
        brush: PdfSolidBrush(accent),
        bounds: Rect.fromLTWH(50, y, w - 100, 24),
      );
      y += 30;
      for (final p in _paragraphs.take(s == 2 ? 2 : 3)) {
        g.drawString(
          p,
          bodyFont,
          bounds: Rect.fromLTWH(50, y, w - 100, 80),
          format: PdfStringFormat(lineSpacing: 4),
        );
        final height = bodyFont
            .measureString(
              p,
              layoutArea: Size(w - 100, 0),
              format: PdfStringFormat(lineSpacing: 4),
            )
            .height;
        y += height + 14;
      }
      y += 14;
    }
    g.drawString(
      'Page ${i + 1} of $pages',
      bodyFont,
      brush: PdfBrushes.gray,
      bounds: Rect.fromLTWH(50, 800, w - 100, 20),
    );
  }
  final path = '${_dataDir.path}/$name';
  await File(path).writeAsBytes(await doc.save(), flush: true);
  doc.dispose();
  return path;
}

Future<String> _writeFormPdf() async {
  final doc = PdfDocument();
  doc.pageSettings.size = PdfPageSize.a4;
  doc.pageSettings.margins.all = 0;
  final page = doc.pages.add();
  final g = page.graphics;
  final w = page.getClientSize().width;
  final titleFont = PdfStandardFont(
    PdfFontFamily.helvetica,
    24,
    style: PdfFontStyle.bold,
  );
  final labelFont = PdfStandardFont(PdfFontFamily.helvetica, 12);
  g.drawRectangle(
    brush: PdfSolidBrush(PdfColor(16, 150, 120)),
    bounds: Rect.fromLTWH(0, 0, w, 14),
  );
  g.drawString(
    'Membership Application',
    titleFont,
    bounds: Rect.fromLTWH(50, 50, w - 100, 40),
  );
  final labels = ['Full name', 'Email', 'Phone', 'City'];
  double y = 120;
  for (int i = 0; i < labels.length; i++) {
    g.drawString(labels[i], labelFont, bounds: Rect.fromLTWH(50, y, 200, 18));
    final field = PdfTextBoxField(
      page,
      'field$i',
      Rect.fromLTWH(50, y + 18, w - 100, 26),
      borderColor: PdfColor(160, 160, 160),
    );
    doc.form.fields.add(field);
    y += 64;
  }
  final cbLabels = ['I agree to the terms', 'Send me the newsletter'];
  for (int i = 0; i < cbLabels.length; i++) {
    final cb = PdfCheckBoxField(
      page,
      'check$i',
      Rect.fromLTWH(50, y, 18, 18),
      borderColor: PdfColor(120, 120, 120),
    );
    doc.form.fields.add(cb);
    g.drawString(
      cbLabels[i],
      labelFont,
      bounds: Rect.fromLTWH(78, y + 2, 300, 18),
    );
    y += 34;
  }
  final path = '${_dataDir.path}/Membership_Form.pdf';
  await File(path).writeAsBytes(await doc.save(), flush: true);
  doc.dispose();
  return path;
}

Future<String> _writePhoto(String name, img.Color top, img.Color bottom) async {
  const width = 1200, height = 900;
  final image = img.Image(width: width, height: height);
  for (int y = 0; y < height; y++) {
    final t = y / height;
    final c = img.ColorRgb8(
      (top.r * (1 - t) + bottom.r * t).round(),
      (top.g * (1 - t) + bottom.g * t).round(),
      (top.b * (1 - t) + bottom.b * t).round(),
    );
    img.drawLine(image, x1: 0, y1: y, x2: width, y2: y, color: c);
  }
  img.fillCircle(
    image,
    x: 880,
    y: 260,
    radius: 110,
    color: img.ColorRgb8(255, 236, 170),
  );
  for (int i = 0; i < 3; i++) {
    img.fillPolygon(
      image,
      vertices: [
        img.Point(-200 + i * 520, height),
        img.Point(200 + i * 520, 420 + i * 40),
        img.Point(600 + i * 520, height),
      ],
      color: img.ColorRgb8(40 + i * 30, 90 + i * 20, 80 + i * 10),
    );
  }
  final path = '${_dataDir.path}/$name';
  await File(path).writeAsBytes(img.encodeJpg(image, quality: 88));
  return path;
}

Future<String> _writeScanPage(String name, int pageNo) async {
  const width = 1240, height = 1754;
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(250, 250, 247));
  img.drawString(
    image,
    pageNo == 1 ? 'INVOICE #2026-0417' : 'TERMS & NOTES',
    font: img.arial48,
    x: 90,
    y: 110,
    color: img.ColorRgb8(30, 30, 30),
  );
  int y = 230;
  for (int i = 0; i < 22; i++) {
    final len = 700 + (i * 137) % 350;
    img.fillRect(
      image,
      x1: 90,
      y1: y,
      x2: 90 + len,
      y2: y + 16,
      color: img.ColorRgb8(120, 120, 125),
    );
    y += i % 5 == 4 ? 80 : 50;
  }
  final path = '${_dataDir.path}/$name';
  await File(path).writeAsBytes(img.encodeJpg(image, quality: 90));
  return path;
}

// -------------------------------------------------------------- helpers --

Future<void> _wait(WidgetTester t, [int ms = 350]) async {
  await Future<void>.delayed(Duration(milliseconds: ms));
  await t.pump();
}

Future<void> _waitFor(WidgetTester t, Finder f, {int seconds = 60}) async {
  final end = DateTime.now().add(Duration(seconds: seconds));
  while (DateTime.now().isBefore(end)) {
    await _wait(t, 200);
    if (f.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Timed out waiting for $f');
}

Future<void> _shot(WidgetTester t, String name) async {
  await _wait(t, 500);
  await t.pump();
  final boundary =
      _shotKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final ui.Image image = await boundary.toImage(pixelRatio: 2.5);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File('${_outDir.path}/$name.png');
  file.parent.createSync(recursive: true);
  await file.writeAsBytes(data!.buffer.asUint8List());
  debugPrint('SHOT ${file.path}');
}

Future<void> _tap(WidgetTester t, Finder f, {int wait = 400}) async {
  await t.ensureVisible(f.first);
  await t.pump();
  await t.tap(f.first, warnIfMissed: false);
  await _wait(t, wait);
}

Future<void> _scrollTo(WidgetTester t, Finder f) async {
  await t.ensureVisible(f.first);
  await _wait(t, 300);
}

Future<void> _home(WidgetTester t) async {
  rootNavigatorKey.currentState!.popUntil((r) => r.isFirst);
  await _wait(t, 600);
}

Future<void> _openTool(WidgetTester t, String title, {int category = 0}) async {
  await _home(t);
  await _tap(
    t,
    find.text(category == 0 ? l.categoryOrganize : l.categoryEditProtect),
  );
  await _tap(t, find.text(title), wait: 900);
}

Future<void> _tapSegment(WidgetTester t, int index, int count) async {
  final f = find.byWidgetPredicate((w) => w is SegmentedButton).first;
  await t.ensureVisible(f);
  final rect = t.getRect(f);
  await t.tapAt(
    Offset(rect.left + rect.width * (index + 0.5) / count, rect.center.dy),
  );
  await _wait(t, 500);
}

Finder _primaryButton() => find.byWidgetPredicate(
  (w) => w is ElevatedButton && w.onPressed != null,
);

Finder _pageImage() => find
    .byWidgetPredicate((w) => w is Image && w.image is MemoryImage)
    .first;

Finder _byTypeName(String name) =>
    find.byWidgetPredicate((w) => w.runtimeType.toString() == name);

Future<void> _download(WidgetTester t, String shotName) async {
  final f = find.text(l.download).evaluate().isNotEmpty
      ? find.text(l.download).last
      : find.text(l.downloadZip).last;
  await _tap(t, f, wait: 900);
  await _shot(t, shotName);
}

// ----------------------------------------------------------------- test --

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final picker = _FakePicker();
  final scanner = _FakeDoclens();

  testWidgets('capture every screen', (t) async {
    final root = await getApplicationSupportDirectory();
    _outDir = Directory('${root.path}/screenshots');
    if (_outDir.existsSync()) _outDir.deleteSync(recursive: true);
    _outDir.createSync(recursive: true);
    _dataDir = Directory('${root.path}/screenshot_data')
      ..createSync(recursive: true);

    FilePickerPlatform.instance = picker;
    DoclensPlatform.instance = scanner;
    for (final name in [
      'plugins.flutter.io/google_mobile_ads',
      'dev.britannica.in_app_review',
      'purapdf/native_theme',
    ]) {
      // Raw handler: google_mobile_ads uses its own codec, so decoding the
      // call would fail - a null success envelope reads the same in any.
      binding.defaultBinaryMessenger.setMockMessageHandler(
        name,
        (_) async => const StandardMethodCodec().encodeSuccessEnvelope(null),
      );
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    final proposal = await _writeTextPdf(
      'Project_Proposal.pdf',
      title: 'Project Proposal',
      pages: 4,
    );
    final report = await _writeTextPdf(
      'Annual_Report.pdf',
      title: 'Annual Report 2026',
      pages: 2,
      accent: PdfColor(220, 80, 60),
    );
    final form = await _writeFormPdf();
    final photos = [
      await _writePhoto(
        'Beach.jpg',
        img.ColorRgb8(90, 170, 240),
        img.ColorRgb8(250, 210, 160),
      ),
      await _writePhoto(
        'Mountains.jpg',
        img.ColorRgb8(60, 70, 160),
        img.ColorRgb8(240, 140, 120),
      ),
      await _writePhoto(
        'Forest.jpg',
        img.ColorRgb8(150, 210, 190),
        img.ColorRgb8(230, 240, 200),
      ),
    ];
    scanner.pages = [
      await _writeScanPage('scan_1.jpg', 1),
      await _writeScanPage('scan_2.jpg', 2),
    ];

    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    t.view.devicePixelRatio = 2.625;
    t.view.physicalSize = const Size(412 * 2.625, 892 * 2.625);
    t.view.padding = const FakeViewPadding(top: 24 * 2.625);
    t.view.viewPadding = const FakeViewPadding(top: 24 * 2.625);
    t.platformDispatcher.platformBrightnessTestValue = Brightness.light;

    await t.pumpWidget(
      RepaintBoundary(
        key: _shotKey,
        child: const ProviderScope(child: PuraPdfApp()),
      ),
    );
    await _wait(t, 1200);

    // ---- start: language picker, home, menus
    await _shot(t, '00_home/01_language_picker');
    await _tap(t, find.text('English'), wait: 1200);
    await _shot(t, '00_home/02_home_organize');
    await _tap(t, find.text(l.categoryEditProtect));
    await _shot(t, '00_home/03_home_edit_protect');
    await _tap(t, find.text(l.categoryOrganize));
    await _tap(t, find.byTooltip(l.languageTooltip), wait: 700);
    await _shot(t, '00_home/04_language_menu');
    await _tap(t, find.text('فارسی'), wait: 1000);
    await _shot(t, '00_home/05_home_persian');
    await _tap(t, find.byTooltip(lookupAppLocalizations(const Locale('fa'))
        .languageTooltip), wait: 700);
    await _tap(t, find.text('English'), wait: 1000);
    Finder themeButton() => find.byWidgetPredicate(
      (w) =>
          w is Icon &&
          (w.icon == Icons.dark_mode_outlined ||
              w.icon == Icons.light_mode_outlined),
    );
    for (int i = 0;
        i < 3 && find.byIcon(Icons.light_mode_outlined).evaluate().isEmpty;
        i++) {
      await _tap(t, themeButton(), wait: 700);
    }
    await _shot(t, '00_home/06_home_light');
    for (int i = 0;
        i < 3 && find.byIcon(Icons.dark_mode_outlined).evaluate().isEmpty;
        i++) {
      await _tap(t, themeButton(), wait: 700);
    }
    await _tap(t, find.byTooltip(l.recentsTooltip), wait: 700);
    await _shot(t, '00_home/07_recents_empty');
    await _tap(t, find.byTooltip(l.backToToolsTooltip));

    // ---- scan
    await _openTool(t, l.featureScanTitle);
    await _shot(t, '01_scan/1_start');
    await _tap(t, _byTypeName('PickerCard'), wait: 1500);
    await _shot(t, '01_scan/2_pages_scanned');
    await _tap(t, find.byType(Switch));
    await _scrollTo(t, _primaryButton());
    await _shot(t, '01_scan/3_options');
    await _tap(t, _primaryButton());
    await _waitFor(t, find.text(l.share));
    await _shot(t, '01_scan/4_result');
    await _download(t, '01_scan/5_downloaded');

    // ---- images <-> pdf
    await _openTool(t, l.featureImagePdfTitle);
    await _shot(t, '02_image_pdf/1_start');
    picker.next = photos;
    await _tap(t, _byTypeName('PickerCard'), wait: 1500);
    await _shot(t, '02_image_pdf/2_images_added');
    await _tap(t, _primaryButton());
    await _waitFor(t, find.text(l.share));
    await _shot(t, '02_image_pdf/3_result');
    await _download(t, '02_image_pdf/4_downloaded');
    final imagesPdf = picker.lastSaved!;
    await _openTool(t, l.featureImagePdfTitle);
    await _tapSegment(t, 1, 2);
    await _shot(t, '02_image_pdf/5_pdf_to_images_start');
    picker.next = [imagesPdf];
    await _tap(t, _byTypeName('PickerCard'), wait: 1500);
    await _shot(t, '02_image_pdf/6_pdf_selected');
    await _tap(t, _primaryButton());
    await _waitFor(t, find.text(l.downloadZip));
    await _shot(t, '02_image_pdf/7_images_result');
    await _download(t, '02_image_pdf/8_zip_downloaded');

    // ---- pdf <-> word
    await _openTool(t, l.featurePdfWordTitle);
    await _shot(t, '03_pdf_word/1_start');
    picker.next = [proposal];
    await _tap(t, _byTypeName('PickerCard'), wait: 1500);
    await _shot(t, '03_pdf_word/2_pdf_selected');
    await _tap(t, _primaryButton());
    await _waitFor(t, find.text(l.share));
    await _shot(t, '03_pdf_word/3_result');
    await _download(t, '03_pdf_word/4_downloaded');
    final docx = picker.lastSaved!;
    await _openTool(t, l.featurePdfWordTitle);
    await _tapSegment(t, 1, 2);
    await _shot(t, '03_pdf_word/5_word_to_pdf_start');
    picker.next = [docx];
    await _tap(t, _byTypeName('PickerCard'), wait: 1500);
    await _shot(t, '03_pdf_word/6_word_selected');
    await _tap(t, _primaryButton());
    await _waitFor(t, find.text(l.share));
    await _shot(t, '03_pdf_word/7_result');
    await _download(t, '03_pdf_word/8_downloaded');

    // ---- merge
    await _openTool(t, l.featureMergeTitle);
    await _shot(t, '04_merge/1_start');
    picker.next = [proposal, report];
    await _tap(t, _byTypeName('PickerCard'), wait: 1500);
    await _shot(t, '04_merge/2_files_added');
    await _tap(t, _primaryButton());
    await _waitFor(t, find.text(l.share));
    await _shot(t, '04_merge/3_result');
    await _download(t, '04_merge/4_downloaded');

    // ---- split
    await _openTool(t, l.featureSplitTitle);
    await _shot(t, '05_split/1_start');
    picker.next = [proposal];
    await _tap(t, _byTypeName('PickerCard'), wait: 1500);
    await _shot(t, '05_split/2_pdf_selected');
    final ranges = find.byType(TextField);
    if (ranges.evaluate().isNotEmpty) {
      await t.ensureVisible(ranges.first);
      await t.enterText(ranges.first, '1-2, 3-4');
      await _wait(t);
    }
    await _scrollTo(t, _primaryButton());
    await _shot(t, '05_split/3_options');
    await _tap(t, _primaryButton());
    await _waitFor(t, find.text(l.downloadZip));
    await _shot(t, '05_split/4_result');
    await _download(t, '05_split/5_downloaded');

    // ---- compress
    await _openTool(t, l.featureCompressTitle);
    await _shot(t, '06_compress/1_start');
    picker.next = [imagesPdf];
    await _tap(t, _byTypeName('PickerCard'), wait: 1500);
    await _shot(t, '06_compress/2_pdf_selected');
    await _tap(t, find.text(l.compressHigh));
    await _scrollTo(t, _primaryButton());
    await _shot(t, '06_compress/3_level_high');
    await _tap(t, _primaryButton());
    await _waitFor(t, find.text(l.download), seconds: 120);
    await _shot(t, '06_compress/4_result');
    await _download(t, '06_compress/5_downloaded');

    // ---- content edit
    await _openTool(t, l.featureContentEditTitle, category: 1);
    await _shot(t, '07_content_edit/1_start');
    picker.next = [proposal];
    await _tap(t, _byTypeName('PickerCard'), wait: 1500);
    await _waitFor(t, _byTypeName('_LineOverlay'));
    await _wait(t, 800);
    await _shot(t, '07_content_edit/2_pdf_opened');
    await _tap(t, _byTypeName('_LineOverlay').at(1), wait: 700);
    await _shot(t, '07_content_edit/3_edit_line_dialog');
    final dialogField = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await t.enterText(dialogField.last, 'Section 1 - Updated Plan');
    await _wait(t);
    await _tap(t, find.text(l.save).last, wait: 700);
    await _tap(t, find.text(l.addTextToPage), wait: 600);
    await _shot(t, '07_content_edit/4_add_text_mode');
    final pageRect = t.getRect(_pageImage());
    await t.tapAt(Offset(pageRect.center.dx, pageRect.top + pageRect.height * .9));
    await _wait(t, 700);
    if (find.byType(AlertDialog).evaluate().isNotEmpty) {
      await t.tap(find.byType(TextField).last);
      await t.enterText(find.byType(TextField).last, 'Approved - Oct 2026');
      await _wait(t);
      await _shot(t, '07_content_edit/5_add_text_dialog');
      await _tap(t, find.text(l.save).last, wait: 700);
    }
    await _shot(t, '07_content_edit/6_edited');
    await _tap(t, _primaryButton());
    await _waitFor(t, find.text(l.share));
    await _shot(t, '07_content_edit/7_result');
    await _download(t, '07_content_edit/8_downloaded');

    // ---- redact
    await _openTool(t, l.featureRedactTitle, category: 1);
    await _shot(t, '08_redact/1_start');
    picker.next = [proposal];
    await _tap(t, _byTypeName('PickerCard'), wait: 1500);
    await _waitFor(t, _pageImage());
    await _wait(t, 1500);
    await _shot(t, '08_redact/2_pdf_opened');
    final rr = t.getRect(_pageImage());
    // A4 is 595x842pt; the contact line of section 1 sits ~y=296pt and the
    // budget line of section 1 ~y=245pt in the generated PDF.
    for (final yPt in [252.0, 302.0]) {
      final y = rr.top + rr.height * yPt / 842;
      await t.dragFrom(
        Offset(rr.left + rr.width * 52 / 595, y),
        Offset(rr.width * 0.75, 0),
      );
      await _wait(t, 500);
    }
    await _shot(t, '08_redact/3_lines_marked');
    await _tap(t, _primaryButton(), wait: 700);
    await _shot(t, '08_redact/4_confirm_dialog');
    await _tap(t, find.text(l.redactConfirmAction).last);
    await _waitFor(t, find.text(l.share));
    await _shot(t, '08_redact/5_result');
    await _download(t, '08_redact/6_downloaded');

    // ---- page edit
    await _openTool(t, l.featurePageEditTitle, category: 1);
    await _shot(t, '09_page_edit/1_start');
    picker.next = [proposal];
    await _tap(t, _byTypeName('PickerCard'), wait: 1500);
    await _waitFor(t, find.byTooltip(l.rotate));
    await _wait(t, 1500);
    await _shot(t, '09_page_edit/2_pages');
    await _tap(t, find.byTooltip(l.rotate).at(0));
    await _tap(t, find.byTooltip(l.removePage).at(2));
    await _wait(t, 800);
    await _shot(t, '09_page_edit/3_rotated_and_removed');
    await _tap(t, _primaryButton());
    await _waitFor(t, find.text(l.share));
    await _shot(t, '09_page_edit/4_result');
    await _download(t, '09_page_edit/5_downloaded');

    // ---- encrypt / decrypt
    await _openTool(t, l.featureEncryptTitle, category: 1);
    await _shot(t, '10_password/1_start');
    picker.next = [report];
    await _tap(t, _byTypeName('PickerCard'), wait: 1500);
    await _shot(t, '10_password/2_pdf_selected');
    final pw = find.byType(TextField);
    await t.enterText(pw.at(0), 'Secret123');
    await t.enterText(pw.at(1), 'Secret123');
    await _wait(t);
    await _scrollTo(t, _primaryButton());
    await _shot(t, '10_password/3_password_entered');
    await _tap(t, _primaryButton());
    await _waitFor(t, find.text(l.share));
    await _shot(t, '10_password/4_locked');
    await _download(t, '10_password/5_downloaded');
    final locked = picker.lastSaved!;
    await _openTool(t, l.featureEncryptTitle, category: 1);
    await _tapSegment(t, 1, 2);
    await _shot(t, '10_password/6_remove_start');
    picker.next = [locked];
    await _tap(t, _byTypeName('PickerCard'), wait: 1500);
    await t.enterText(find.byType(TextField).first, 'Secret123');
    await _wait(t);
    await _scrollTo(t, _primaryButton());
    await _shot(t, '10_password/7_current_password');
    await _tap(t, _primaryButton());
    await _waitFor(t, find.text(l.share));
    await _shot(t, '10_password/8_unlocked');
    await _download(t, '10_password/9_downloaded');

    // ---- watermark
    await _openTool(t, l.featureWatermarkTitle, category: 1);
    await _shot(t, '11_watermark/1_start');
    picker.next = [report];
    await _tap(t, _byTypeName('PickerCard'), wait: 1500);
    await _shot(t, '11_watermark/2_pdf_selected');
    await t.enterText(find.byType(TextField).first, 'CONFIDENTIAL');
    await _wait(t);
    await _scrollTo(t, _primaryButton());
    await _shot(t, '11_watermark/3_options');
    await _tap(t, _primaryButton());
    await _waitFor(t, find.text(l.share));
    await _shot(t, '11_watermark/4_result');
    await _download(t, '11_watermark/5_downloaded');

    // ---- signature
    await _openTool(t, l.featureSignatureTitle, category: 1);
    await _shot(t, '12_signature/1_start');
    picker.next = [proposal];
    await _tap(t, _byTypeName('PickerCard'), wait: 1500);
    await _waitFor(t, find.text(l.addSignature));
    await _wait(t, 1200);
    await _shot(t, '12_signature/2_pdf_opened');
    await _tap(t, find.text(l.addSignature), wait: 900);
    await _shot(t, '12_signature/3_signature_pad_draw');
    await _tap(t, find.text(l.signaturePadType), wait: 600);
    await t.enterText(find.byType(TextField).first, 'Sarah Miller');
    await _wait(t, 600);
    await _shot(t, '12_signature/4_signature_pad_type');
    await _tap(t, find.text(l.signaturePadDone).last, wait: 1200);
    await _shot(t, '12_signature/5_signature_placed');
    await _tap(t, _primaryButton());
    await _waitFor(t, find.text(l.share));
    await _shot(t, '12_signature/6_result');
    await _download(t, '12_signature/7_downloaded');

    // ---- fill & sign
    await _openTool(t, l.featureFillSignTitle, category: 1);
    await _shot(t, '13_fill_sign/1_start');
    picker.next = [form];
    await _tap(t, _byTypeName('PickerCard'), wait: 1500);
    await _waitFor(t, find.byType(TextField));
    await _wait(t, 1200);
    await _shot(t, '13_fill_sign/2_form_opened');
    final values = ['Sarah Miller', 'sarah@example.com', '+1 555 0142', 'Berlin'];
    final fields = find.byType(TextField);
    for (int i = 0; i < values.length && i < fields.evaluate().length; i++) {
      await t.enterText(fields.at(i), values[i]);
      await _wait(t, 200);
    }
    final boxes = _byTypeName('_CheckboxOverlay');
    if (boxes.evaluate().isNotEmpty) await _tap(t, boxes.first);
    FocusManager.instance.primaryFocus?.unfocus();
    await _wait(t, 500);
    await _shot(t, '13_fill_sign/3_filled');
    await _tap(t, _primaryButton());
    await _waitFor(t, find.text(l.share));
    await _shot(t, '13_fill_sign/4_result');
    await _download(t, '13_fill_sign/5_downloaded');

    // ---- recents, now populated
    await _home(t);
    await _tap(t, find.byTooltip(l.recentsTooltip), wait: 900);
    await _shot(t, '00_home/08_recents_filled');

    debugPrint('SCREENSHOTS_DIR ${_outDir.path}');
    debugDefaultTargetPlatformOverride = null;
  });
}
