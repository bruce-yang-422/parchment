/// File metadata from the platform (size, modification time, location).
class DocumentStat {
  const DocumentStat({
    this.size,
    this.modified,
    this.created,
    this.documentId,
    this.authority,
    this.storagePath,
    this.absolutePath,
  });

  final int? size;
  final DateTime? modified;

  /// Not provided by Android's Storage Access Framework.
  final DateTime? created;

  /// Storage Access Framework document id (e.g. `primary:Download/a.md`).
  final String? documentId;

  /// Content provider authority of the URI.
  final String? authority;

  /// Path below the internal storage root from the media database
  /// (`Documents/Notes/a.md`), for files opened from a file manager.
  final String? storagePath;

  /// Absolute path on the phone from the media database, when known.
  final String? absolutePath;
}

abstract interface class DocumentInspector {
  Future<DocumentStat?> stat(String uri);
}

/// Human-readable location of a document, when it can be derived.
class DocumentLocation {
  const DocumentLocation({required this.label, this.path, this.absolute});

  /// e.g. `內部儲存空間`, `SD 卡（1234-ABCD）`, `下載項目`, or the provider.
  final String label;

  /// Folder path and file name below [label], when known.
  final String? path;

  /// Full path on the phone (`/storage/emulated/0/Documents/a.md`), when
  /// it can be derived.
  final String? absolute;

  String get display => path == null ? label : '$label/$path';
}

/// Derives a readable location from a SAF document id / provider authority.
DocumentLocation? describeLocation({
  String? documentId,
  String? authority,
  String? storagePath,
  String? absolutePath,
}) {
  final location = _describe(documentId, authority, storagePath);
  if (location == null) return null;
  final absolute =
      absolutePath ?? _absoluteFor(documentId, authority, location);
  return absolute == null
      ? location
      : DocumentLocation(
          label: location.label,
          path: location.path,
          absolute: absolute,
        );
}

/// Phone path for internal storage and SD cards (`primary:` / volume ids).
String? _absoluteFor(
  String? documentId,
  String? authority,
  DocumentLocation location,
) {
  const internal = '/storage/emulated/0';
  final id = documentId;
  if (authority == 'com.android.externalstorage.documents' && id != null) {
    final colon = id.indexOf(':');
    if (colon < 0) return null;
    final volume = id.substring(0, colon);
    final path = id.substring(colon + 1);
    return volume == 'primary' ? '$internal/$path' : '/storage/$volume/$path';
  }
  if (location.label == '內部儲存空間' && location.path != null) {
    return '$internal/${location.path}';
  }
  if (location.label.startsWith('/')) return location.label;
  return null;
}

DocumentLocation? _describe(
  String? documentId,
  String? authority,
  String? storagePath,
) {
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
  if (storagePath != null && storagePath.isNotEmpty) {
    return storagePath.startsWith('/')
        ? DocumentLocation(label: storagePath)
        : DocumentLocation(label: '內部儲存空間', path: storagePath);
  }
  if (authority == null || authority.isEmpty) return null;
  return DocumentLocation(label: _sourceApp(authority));
}

/// Plain name of the app that shared the file, when it is a common one.
String _sourceApp(String authority) {
  final value = authority.toLowerCase();
  if (value.contains('naver.line')) return '來自 LINE';
  if (value.startsWith('com.google.android.gm')) return '來自 Gmail';
  if (value.startsWith('com.google.android.apps.docs')) {
    return '來自 Google 雲端硬碟';
  }
  if (value.contains('telegram')) return '來自 Telegram';
  if (value.contains('whatsapp')) return '來自 WhatsApp';
  if (value.contains('facebook.orca')) return '來自 Messenger';
  if (value.contains('discord')) return '來自 Discord';
  if (value.contains('slack')) return '來自 Slack';
  if (value == 'media' || value.startsWith('com.android.providers.media')) {
    return '內部儲存空間';
  }
  return '來自其他 App';
}
