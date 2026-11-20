/// File metadata from the platform (size, modification time, location).
class DocumentStat {
  const DocumentStat({
    this.size,
    this.modified,
    this.created,
    this.documentId,
    this.authority,
  });

  final int? size;
  final DateTime? modified;

  /// Not provided by Android's Storage Access Framework.
  final DateTime? created;

  /// Storage Access Framework document id (e.g. `primary:Download/a.md`).
  final String? documentId;

  /// Content provider authority of the URI.
  final String? authority;
}

abstract interface class DocumentInspector {
  Future<DocumentStat?> stat(String uri);
}

/// Human-readable location of a document, when it can be derived.
class DocumentLocation {
  const DocumentLocation({required this.label, this.path});

  /// e.g. `內部儲存空間`, `SD 卡（1234-ABCD）`, `下載項目`, or the provider.
  final String label;

  /// Folder path and file name below [label], when known.
  final String? path;

  String get display => path == null ? label : '$label/$path';
}

/// Derives a readable location from a SAF document id / provider authority.
DocumentLocation? describeLocation({String? documentId, String? authority}) {
  final id = documentId;
  if (authority == 'com.android.externalstorage.documents' && id != null) {
    final colon = id.indexOf(':');
    final volume = colon < 0 ? id : id.substring(0, colon);
    final path = colon < 0 ? null : id.substring(colon + 1);
    return DocumentLocation(
      label: volume == 'primary' ? '內部儲存空間' : 'SD 卡（$volume）',
      path: path == null || path.isEmpty ? null : path,
    );
  }
  if (authority == 'com.android.providers.downloads.documents') {
    if (id != null && id.startsWith('raw:')) {
      final raw = id.substring(4);
      const root = '/storage/emulated/0/';
      return raw.startsWith(root)
          ? DocumentLocation(label: '內部儲存空間', path: raw.substring(root.length))
          : DocumentLocation(label: raw);
    }
    return const DocumentLocation(label: '下載項目');
  }
  if (authority == null || authority.isEmpty) return null;
  return DocumentLocation(label: '來源：$authority');
}
