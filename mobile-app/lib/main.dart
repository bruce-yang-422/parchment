import 'package:flutter/material.dart';

import 'app/parchment_app.dart';
import 'infrastructure/android_document_channel.dart';
import 'infrastructure/file_picker_document_picker.dart';
import 'infrastructure/platform_document_writer.dart';
import 'infrastructure/preferences_recent_folders.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final documents = AndroidDocumentChannel();
  runApp(
    ParchmentApp(
      documentPicker: FilePickerDocumentPicker(),
      documentWriter: PlatformDocumentWriter(),
      folderSource: documents,
      incomingSource: documents,
      recentFoldersStore: PreferencesRecentFolders(),
      documentInspector: documents,
    ),
  );
}
