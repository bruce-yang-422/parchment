import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/models/local_document.dart';
import '../core/services/document_writer.dart';
import '../core/l10n/tr.dart';

/// Android writes back through the SAF URI granted at pick time; other
/// platforms (iOS opens picked files as copies) only offer "save as".
class PlatformDocumentWriter implements DocumentWriter {
  static const _channel = MethodChannel('com.stackbase.parchment/documents');

  @override
  bool canWriteInPlace(LocalDocument document) =>
      !kIsWeb &&
      Platform.isAndroid &&
      document.sourceUri != null &&
      document.lossless;

  @override
  Future<void> writeInPlace(LocalDocument document, String content) async {
    if (!canWriteInPlace(document)) {
      throw UnsupportedError(tr('這個檔案無法直接存回，請改用「另存新檔」。'));
    }
    final uri = document.sourceUri!;
    final current = await _channel.invokeMethod<Uint8List>('read', {
      'uri': uri,
    });
    if (current == null ||
        !listEquals(current, utf8.encode(document.content))) {
      throw const DocumentChangedException();
    }
    await _channel.invokeMethod<void>('write', {
      'uri': uri,
      'bytes': Uint8List.fromList(utf8.encode(content)),
    });
  }

  @override
  Future<bool> saveAs(LocalDocument document, String content) async {
    final uri = await FilePicker.saveFile(
      dialogTitle: tr('另存新檔'),
      fileName: document.name,
      bytes: Uint8List.fromList(utf8.encode(content)),
      mimeType: document.format == DocumentFormat.markdown
          ? 'text/markdown'
          : 'text/plain',
    );
    return uri != null;
  }
}
