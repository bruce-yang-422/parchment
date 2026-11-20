import 'dart:convert';

enum DocumentFormat { markdown, plainText }

class LocalDocument {
  LocalDocument({
    required this.name,
    required this.content,
    required this.format,
    this.sourceUri,
    this.lossless = true,
    this.folderPath,
    this.byteLength,
    this.hasBom = false,
    int? id,
  }) : id = id ?? ++_nextId;

  /// Decodes UTF-8 [bytes]; invalid sequences are replaced for display and
  /// mark the document as not [lossless].
  factory LocalDocument.decode({
    required String name,
    required List<int> bytes,
    required DocumentFormat format,
    String? sourceUri,
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
      lossless: lossless,
      folderPath: folderPath,
      byteLength: bytes.length,
      hasBom:
          bytes.length >= 3 &&
          bytes[0] == 0xEF &&
          bytes[1] == 0xBB &&
          bytes[2] == 0xBF,
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

  LocalDocument copyWith({required String content}) {
    return LocalDocument(
      id: id,
      name: name,
      content: content,
      format: format,
      sourceUri: sourceUri,
      lossless: lossless,
      folderPath: folderPath,
      byteLength: utf8.encode(content).length,
      hasBom: hasBom,
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
