import 'package:android_file_picker/android_file_picker.dart';
import 'package:file_picker/file_picker.dart';

import '../core/models/local_document.dart';
import '../core/services/document_picker.dart';
import '../core/services/large_document_policy.dart';

class FilePickerDocumentPicker implements DocumentPicker {
  @override
  Future<LocalDocument?> pickDocument() async {
    final file = await FilePicker.pickFile(
      dialogTitle: '選擇要開啟的文件',
      type: FileType.custom,
      allowedExtensions: const ['md', 'txt'],
      // Ask for write access so task-list edits can be saved back when the
      // user chooses to. The grant lasts only while the app is running.
      androidOptions: const FilePickerAndroidOptions(
        safOptions: AndroidSAFOptions(
          accessMode: AndroidSAFAccessMode.readWrite,
          persistGrant: false,
        ),
      ),
    );
    if (file == null) return null;
    if (!LocalDocument.supportsFileName(file.name)) {
      throw FormatException('不支援的格式：${file.name}。請使用 .md 或 .txt 檔案。');
    }

    final byteLength = await file.length();
    if (byteLength == null) {
      throw const FileSizeUnavailableException();
    }
    if (LargeDocumentPolicy.requiresPagedReading(byteLength)) {
      throw PagedReadingRequiredException(byteLength);
    }

    final bytes = await file.readAsBytes();
    final safHandle = file is AndroidPlatformFile ? file.safHandle : null;
    return LocalDocument.decode(
      name: file.name,
      bytes: bytes,
      format: LocalDocument.formatForFileName(file.name),
      sourceUri: safHandle?.accessMode == AndroidSAFAccessMode.readWrite
          ? safHandle!.uri.toString()
          : null,
    );
  }
}
