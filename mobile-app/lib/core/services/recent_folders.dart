/// A folder the user opened before.
class RecentFolder {
  const RecentFolder({
    required this.uri,
    required this.name,
    required this.openedAt,
  });

  final String uri;
  final String name;
  final DateTime openedAt;

  Map<String, Object> toJson() => {
    'uri': uri,
    'name': name,
    'openedAt': openedAt.millisecondsSinceEpoch,
  };

  static RecentFolder? fromJson(Object? value) {
    if (value is! Map) return null;
    final uri = value['uri'];
    final name = value['name'];
    final openedAt = value['openedAt'];
    if (uri is! String || name is! String || openedAt is! int) return null;
    return RecentFolder(
      uri: uri,
      name: name,
      openedAt: DateTime.fromMillisecondsSinceEpoch(openedAt),
    );
  }
}

abstract interface class RecentFoldersStore {
  Future<List<RecentFolder>> load();
  Future<void> save(List<RecentFolder> folders);
}

/// Keeps the most recent folders first, without duplicates.
List<RecentFolder> rememberFolder(
  List<RecentFolder> current,
  RecentFolder folder, {
  int limit = 16,
}) {
  return [
    folder,
    for (final item in current)
      if (item.uri != folder.uri) item,
  ].take(limit).toList();
}
