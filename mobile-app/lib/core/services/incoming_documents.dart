import '../models/local_document.dart';

/// A file another app asked Parchment to open ("Open with" or share).
class IncomingDocument {
  const IncomingDocument({
    required this.name,
    this.uri,
    this.mimeType,
    this.size,
    this.writable = false,
    this.text,
  });

  final String name;
  final String? uri;
  final String? mimeType;
  final int? size;

  /// Whether the sending app granted write access to [uri].
  final bool writable;

  /// Shared plain text, when no file was sent.
  final String? text;
}

abstract interface class IncomingDocumentSource {
  /// The document the app was launched with, if any.
  Future<IncomingDocument?> takeInitial();

  /// Documents received while the app is running.
  Stream<IncomingDocument> get documents;

  /// Reads and validates [incoming] (format and size).
  Future<LocalDocument> load(IncomingDocument incoming);
}
