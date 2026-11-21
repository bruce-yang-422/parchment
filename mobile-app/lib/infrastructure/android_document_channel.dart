import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:android_file_picker/android_file_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/models/local_document.dart';
import '../core/models/note_folder.dart';
import '../core/services/document_inspector.dart';
import '../core/services/document_picker.dart';
import '../core/services/folder_source.dart';
import '../core/services/incoming_documents.dart';
import '../core/services/large_document_policy.dart';
import '../core/l10n/tr.dart';

/// Android implementation backed by `MainActivity.kt`'s
/// `com.stackbase.parchment/documents` channel.
class AndroidDocumentChannel
    implements
        DocumentPicker,
        FolderSource,
        IncomingDocumentSource,
        DocumentInspector {
  AndroidDocumentChannel() {
    if (_supported) _channel.setMethodCallHandler(_handleCall);
  }

  static const _channel = MethodChannel('com.stackbase.parchment/documents');

  /// Reads, writes and folder listings; answered from background threads.
  static const _io = MethodChannel('com.stackbase.parchment/documents_io');
  static bool get _supported => !kIsWeb && Platform.isAndroid;

  final _incoming = StreamController<IncomingDocument>.broadcast();

  /* ──────────────── Single document picker ──────────────── */

  @override
  Future<LocalDocument?> pickDocument() async {
    if (!_supported) return null;
    final picked = await _channel.invokeMapMethod<String, Object?>(
      'pickDocument',
    );
    if (picked == null) return null;
    final name = picked['name'] as String? ?? 'document';
    if (!LocalDocument.supportsFileName(name)) {
      throw FormatException(
        tr('不支援的格式：{name}。請使用 .md 或 .txt 檔案。', {'name': name}),
      );
    }
    final size = picked['size'] as int?;
    if (size == null) throw const FileSizeUnavailableException();
    if (LargeDocumentPolicy.requiresPagedReading(size)) {
      throw PagedReadingRequiredException(size);
    }
    final uri = picked['uri'] as String?;
    if (uri == null) throw FormatException(tr('沒有收到可開啟的檔案'));
    final bytes = await _read(uri);
    return LocalDocument.decode(
      name: name,
      bytes: bytes,
      format: LocalDocument.formatForFileName(name),
      sourceUri: (picked['writable'] as bool? ?? false) ? uri : null,
      originUri: uri,
    );
  }

  Future<Object?> _handleCall(MethodCall call) async {
    if (call.method == 'incomingDocument') {
      final map = (call.arguments as Map).cast<String, Object?>();
      _incoming.add(_incomingFromMap(map));
    }
    return null;
  }

  /* ──────────────── Folder mode ──────────────── */

  @override
  bool get isSupported => _supported;

  @override
  Future<NoteFolder?> pickFolder() async {
    if (!_supported) return null;
    final tree = await FilePicker.pickDirectory(
      dialogTitle: tr('選擇筆記資料夾'),
      // Write access lets task-list edits be saved back; the grant is kept
      // so the folder can be reopened later.
      androidOptions: const FilePickerAndroidOptions(
        safOptions: AndroidSAFOptions(
          grant: AndroidSAFGrant.lifetime,
          accessMode: AndroidSAFAccessMode.readWrite,
        ),
      ),
    );
    if (tree == null) return null;
    return openFolderUri(tree.toString(), _folderName(tree));
  }

  @override
  Future<NoteFolder> openFolderUri(String uri, String name) async {
    final raw = await _io.invokeListMethod<Map>('listTree', {'uri': uri});
    final entries = [
      for (final item in raw ?? const <Map>[])
        FolderEntry(
          path: (item['path'] as String).split('/'),
          uri: item['uri'] as String,
          directory: item['directory'] as bool,
          size: item['size'] as int?,
          modified: item['modified'] == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(item['modified'] as int),
        ),
    ];
    return NoteFolder(name: name, uri: uri, entries: entries);
  }

  @override
  Future<Set<String>> grantedFolderUris() async {
    if (!_supported) return const {};
    final uris = await _channel.invokeListMethod<String>('persistedTrees');
    return {...?uris};
  }

  @override
  Future<void> releaseFolder(String uri) async {
    if (!_supported) return;
    await _channel.invokeMethod<void>('releaseTree', {'uri': uri});
  }

  static String _folderName(Uri tree) {
    // Tree document ids look like `primary:Download/Notes`; pathSegments
    // are already decoded, so they must not be decoded again (that fails
    // on names such as `筆記` or `100%`).
    final id = tree.pathSegments.isEmpty ? '' : tree.pathSegments.last;
    final path = id.contains(':') ? id.substring(id.indexOf(':') + 1) : id;
    final name = path.split('/').where((part) => part.isNotEmpty).lastOrNull;
    return name ?? tr('資料夾');
  }

  @override
  Future<Uint8List> readFile(FolderEntry entry) => _read(entry.uri);

  Future<Uint8List> _read(String uri) async {
    final bytes = await _io.invokeMethod<Uint8List>('read', {'uri': uri});
    if (bytes == null) throw StateError(tr('無法讀取檔案'));
    return bytes;
  }

  /* ──────────────── Metadata ──────────────── */

  @override
  Future<DocumentStat?> stat(String uri) async {
    if (!_supported || !uri.startsWith('content:')) return null;
    final map = await _io.invokeMapMethod<String, Object?>('stat', {
      'uri': uri,
    });
    if (map == null) return null;
    final modified = map['modified'] as int?;
    return DocumentStat(
      size: map['size'] as int?,
      modified: modified == null || modified <= 0
          ? null
          : DateTime.fromMillisecondsSinceEpoch(modified),
      documentId: map['documentId'] as String?,
      authority: map['authority'] as String?,
      storagePath: map['storagePath'] as String?,
      absolutePath: map['absolutePath'] as String?,
    );
  }

  /* ──────────────── Incoming files ──────────────── */

  @override
  Stream<IncomingDocument> get documents => _incoming.stream;

  @override
  Future<IncomingDocument?> takeInitial() async {
    if (!_supported) return null;
    final map = await _channel.invokeMapMethod<String, Object?>(
      'takeIncomingDocument',
    );
    return map == null ? null : _incomingFromMap(map);
  }

  static IncomingDocument _incomingFromMap(Map<String, Object?> map) {
    return IncomingDocument(
      name: map['name'] as String? ?? 'document',
      uri: map['uri'] as String?,
      mimeType: map['mimeType'] as String?,
      size: map['size'] as int?,
      writable: map['writable'] as bool? ?? false,
      text: map['text'] as String?,
    );
  }

  @override
  Future<LocalDocument> load(IncomingDocument incoming) async {
    if (incoming.text case final text?) {
      final bytes = utf8.encode(text);
      if (LargeDocumentPolicy.requiresPagedReading(bytes.length)) {
        throw PagedReadingRequiredException(bytes.length);
      }
      return LocalDocument(
        name: incoming.name,
        content: text,
        format: LocalDocument.supportsFileName(incoming.name)
            ? LocalDocument.formatForFileName(incoming.name)
            : DocumentFormat.plainText,
      );
    }
    final uri = incoming.uri;
    if (uri == null) throw FormatException(tr('沒有收到可開啟的檔案'));
    final format = LocalDocument.formatForIncoming(
      incoming.name,
      incoming.mimeType,
    );
    if (incoming.size case final size?
        when LargeDocumentPolicy.requiresPagedReading(size)) {
      throw PagedReadingRequiredException(size);
    }
    final Uint8List bytes;
    if (uri.startsWith('file:')) {
      try {
        bytes = await File.fromUri(Uri.parse(uri)).readAsBytes();
      } on FileSystemException {
        // Old-style file paths need a storage permission the app does
        // not ask for; the picker grants access to the same file.
        throw FormatException(
          tr('沒有權限讀取這個檔案，請在 Parchment 按「開啟檔案」選取它'),
        );
      }
    } else {
      bytes = await _read(uri);
    }
    if (LargeDocumentPolicy.requiresPagedReading(bytes.length)) {
      throw PagedReadingRequiredException(bytes.length);
    }
    return LocalDocument.decode(
      name: incoming.name,
      bytes: bytes,
      format: format,
      sourceUri: incoming.writable ? uri : null,
      originUri: uri,
    );
  }
}
