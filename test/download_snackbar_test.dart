import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purapdf/l10n/app_localizations.dart';
import 'package:purapdf/presentation/shared_widgets/download_file.dart';

class _FakePicker extends FilePickerPlatform {
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
  }) async => Uri.parse('content://downloads/$fileName');
}

void main() {
  late String sourcePath;
  final List<MethodCall> folderCalls = [];

  setUpAll(() {
    FilePickerPlatform.instance = _FakePicker();
    final dir = Directory.systemTemp.createTempSync('download_snackbar');
    sourcePath = '${dir.path}/report.pdf';
    File(sourcePath).writeAsBytesSync([1, 2, 3]);
  });

  setUp(() {
    folderCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('purapdf/file_location'),
          (call) async {
            folderCalls.add(call);
            return true;
          },
        );
  });

  Future<void> showSaved(WidgetTester tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [downloadSnackBarObserver],
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                ElevatedButton(
                  onPressed: () => downloadFile(context, sourcePath),
                  child: const Text('download'),
                ),
                ElevatedButton(onPressed: () {}, child: const Text('other')),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const Scaffold(body: Text('next')),
                    ),
                  ),
                  child: const Text('push'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      await tester.tap(find.text('download'));
      // Let the real file read in downloadFile finish.
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(find.text('Show in folder'), findsOneWidget);
  }

  testWidgets('closes by itself after 5 seconds', (tester) async {
    await showSaved(tester);
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('Show in folder'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Show in folder'), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('closes on a tap anywhere else', (tester) async {
    await showSaved(tester);
    await tester.tap(find.text('other'));
    await tester.pumpAndSettle();
    expect(find.text('Show in folder'), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('closes when navigating to another page', (tester) async {
    await showSaved(tester);
    await tester.tap(find.text('push'));
    await tester.pumpAndSettle();
    expect(find.text('Show in folder'), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Show in folder still works', (tester) async {
    await showSaved(tester);
    await tester.tap(find.text('Show in folder'));
    await tester.pumpAndSettle();
    expect(folderCalls.map((c) => c.method), ['showInFolder']);
    debugDefaultTargetPlatformOverride = null;
  });
}
