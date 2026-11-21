import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/parchment_app.dart';
import 'infrastructure/android_document_channel.dart';
import 'infrastructure/file_picker_document_picker.dart';
import 'infrastructure/platform_document_writer.dart';
import 'infrastructure/preferences_reader_settings.dart';
import 'infrastructure/preferences_recent_folders.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // In release builds a failing widget is a plain grey box; show a short
  // note instead so the rest of the screen stays usable and readable.
  if (kReleaseMode) {
    ErrorWidget.builder = (details) => const Directionality(
      textDirection: TextDirection.ltr,
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Text(
          '這部分內容無法顯示',
          style: TextStyle(color: Color(0xFF9E3B2E), fontSize: 14),
        ),
      ),
    );
  }
  final settingsStore = PreferencesReaderSettings();
  final initialSettings = await settingsStore.load().catchError(
    (Object _) => null,
  );
  final documents = AndroidDocumentChannel();
  runApp(
    ParchmentApp(
      documentPicker: !kIsWeb && Platform.isAndroid
          ? documents
          : FilePickerDocumentPicker(),
      documentWriter: PlatformDocumentWriter(),
      folderSource: documents,
      incomingSource: documents,
      recentFoldersStore: PreferencesRecentFolders(),
      documentInspector: documents,
      settingsStore: settingsStore,
      initialSettings: initialSettings,
    ),
  );
}
