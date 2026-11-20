import '../markdown/wiki_paths.dart';

/// One file or directory inside an opened folder.
class FolderEntry {
  const FolderEntry({
    required this.path,
    required this.uri,
    required this.directory,
    this.size,
    this.modified,
  });

  /// Path segments relative to the folder root.
  final List<String> path;

  /// Platform URI used to read (and, when permitted, write) the file.
  final String uri;
  final bool directory;
  final int? size;
  final DateTime? modified;

  String get name => path.last;
  String get pathKey => path.join('/');

  bool get isNote {
    final lower = name.toLowerCase();
    return !directory && (lower.endsWith('.md') || lower.endsWith('.txt'));
  }
}

/// A folder the user opened, with every file it contains (hidden files and
/// folders excluded).
class NoteFolder {
  NoteFolder({
    required this.name,
    required this.uri,
    required List<FolderEntry> entries,
  }) : entries = List.unmodifiable(entries),
       _byKey = {
         for (final entry in entries)
           if (!entry.directory) entry.pathKey.toLowerCase(): entry,
       };

  final String name;
  final String uri;
  final List<FolderEntry> entries;
  final Map<String, FolderEntry> _byKey;

  late final List<FolderEntry> files = [
    for (final entry in entries)
      if (!entry.directory) entry,
  ];

  late final List<FolderEntry> notes = [
    for (final entry in files)
      if (entry.isNote) entry,
  ];

  late final List<List<String>> _filePaths = [
    for (final entry in files) entry.path,
  ];

  FolderEntry? entryAt(List<String> path) =>
      _byKey[path.join('/').toLowerCase()];

  /// Resolves a wiki target or relative link from the note at [sourcePath].
  FolderEntry? resolve(
    String target,
    List<String>? sourcePath, {
    bool markdown = false,
  }) {
    final path = resolveWikiPath(
      target,
      sourcePath ?? const [],
      _filePaths,
      markdown: markdown,
    );
    return path == null ? null : entryAt(path);
  }

  /// Resolves a Markdown relative URL (`../img.png`) against [sourcePath].
  FolderEntry? resolveRelative(String href, List<String>? sourcePath) {
    var value = href.split('#').first.split('?').first;
    try {
      value = Uri.decodeComponent(value);
    } on ArgumentError {
      // Keep the raw value.
    }
    final directory = (sourcePath ?? const <String>[]).isEmpty
        ? const <String>[]
        : sourcePath!.sublist(0, sourcePath.length - 1);
    final normalized = normalizePath(
      value.startsWith('/')
          ? value.split('/')
          : [...directory, ...value.split('/')],
    );
    return normalized == null ? null : entryAt(normalized);
  }
}
