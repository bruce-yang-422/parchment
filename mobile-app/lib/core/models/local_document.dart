import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;

enum DocumentFormat { markdown, plainText }

class LocalDocument {
  LocalDocument({
    required this.name,
    required this.content,
    required this.format,
    this.sourceUri,
    String? originUri,
    this.lossless = true,
    this.folderPath,
    this.byteLength,
    this.hasBom = false,
    this.sha256,
    int? id,
  }) : id = id ?? ++_nextId,
       originUri = originUri ?? sourceUri;

  /// Decodes UTF-8 [bytes]; invalid sequences are replaced for display and
  /// mark the document as not [lossless].
  factory LocalDocument.decode({
    required String name,
    required List<int> bytes,
    required DocumentFormat format,
    String? sourceUri,
    String? originUri,
    List<String>? folderPath,
  }) {
    final content = utf8.decode(bytes, allowMalformed: true);
    final encoded = utf8.encode(content);
    var lossless = encoded.length == bytes.length;
    for (var i = 0; lossless && i < encoded.length; i++) {
      lossless = encoded[i] == bytes[i];
    }
    return LocalDocument(
      name: name,
      content: content,
      format: format,
      sourceUri: sourceUri,
      originUri: originUri,
      lossless: lossless,
      folderPath: folderPath,
      byteLength: bytes.length,
      hasBom:
          bytes.length >= 3 &&
          bytes[0] == 0xEF &&
          bytes[1] == 0xBB &&
          bytes[2] == 0xBF,
      sha256: crypto.sha256.convert(bytes).toString(),
    );
  }

  static int _nextId = 0;

  /// Stable identity for one opened document; kept when the content is
  /// replaced after saving so the reader keeps its scroll position.
  final int id;

  final String name;
  final String content;
  final DocumentFormat format;

  /// Platform URI with write permission (Android SAF), or `null` when the
  /// document was opened as a read-only copy.
  final String? sourceUri;

  /// URI the file was read from, also when it is read-only (files shared
  /// from LINE or a file manager); used to look up its location and times.
  final String? originUri;

  /// Whether [content] re-encodes to exactly the original bytes. Documents
  /// with invalid UTF-8 are never written in place.
  final bool lossless;

  /// Path inside the opened folder, used to resolve wiki links, embeds and
  /// relative resources; `null` in single-file mode.
  final List<String>? folderPath;

  /// Size of the file as read, when known.
  final int? byteLength;

  /// Whether the file starts with a UTF-8 byte order mark.
  final bool hasBom;

  /// SHA-256 of the file as read (lower-case hex), when known.
  final String? sha256;

  LocalDocument copyWith({required String content}) {
    // A byte order mark stays in [content] as U+FEFF, so re-encoding gives
    // exactly the bytes that were saved.
    final bytes = utf8.encode(content);
    return LocalDocument(
      id: id,
      name: name,
      content: content,
      format: format,
      sourceUri: sourceUri,
      originUri: originUri,
      lossless: lossless,
      folderPath: folderPath,
      byteLength: bytes.length,
      hasBom: hasBom,
      sha256: crypto.sha256.convert(bytes).toString(),
    );
  }

  static bool supportsFileName(String name) {
    final normalized = name.toLowerCase();
    return normalized.endsWith('.md') || normalized.endsWith('.txt');
  }

  static DocumentFormat formatForFileName(String name) {
    if (!supportsFileName(name)) {
      throw const FormatException('只支援 .md 與 .txt 檔案');
    }
    return name.toLowerCase().endsWith('.md')
        ? DocumentFormat.markdown
        : DocumentFormat.plainText;
  }

  /// Format for a file received from another app. The name decides when it
  /// has a supported extension; otherwise a Markdown or plain-text MIME type
  /// is accepted. Anything else is rejected.
  static DocumentFormat formatForIncoming(String name, String? mimeType) {
    if (supportsFileName(name)) return formatForFileName(name);
    final hasExtension = RegExp(r'\.[A-Za-z0-9]{1,8}$').hasMatch(name);
    if (!hasExtension) {
      switch (mimeType) {
        case 'text/markdown' || 'text/x-markdown':
          return DocumentFormat.markdown;
        case 'text/plain':
          return DocumentFormat.plainText;
      }
    }
    throw FormatException('無法開啟「$name」：Parchment 只支援 .md 與 .txt 檔案。');
  }
}
