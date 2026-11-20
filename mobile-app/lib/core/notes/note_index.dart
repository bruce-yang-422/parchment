/// Folder-wide note index: titles, tags, links, backlinks and full-text
/// search. Built from note contents; contains no platform code.
library;

import '../markdown/frontmatter.dart';
import '../markdown/note_syntax.dart';
import '../models/note_folder.dart';

class IndexedNote {
  IndexedNote({
    required this.entry,
    required this.content,
    required this.title,
    required this.tags,
    required this.links,
  }) : _searchText = content.toLowerCase();

  /// Builds the index entry for [entry] with [content], resolving links
  /// against [folder].
  factory IndexedNote.fromContent(
    FolderEntry entry,
    String content,
    NoteFolder folder,
  ) {
    final markdown = entry.name.toLowerCase().endsWith('.md');
    final frontmatter = markdown ? Frontmatter.parse(content) : null;
    final body = markdown ? stripFencedCode(frontmatter!.body) : content;
    return IndexedNote(
      entry: entry,
      content: content,
      title: _title(entry, frontmatter, body),
      tags: markdown ? noteTags(content) : const [],
      links: markdown ? _links(body, entry, folder) : const {},
    );
  }

  final FolderEntry entry;
  final String content;
  final String title;

  /// Tags without `#`, as written.
  final List<String> tags;

  /// Path keys of notes this note links to (resolved inside the folder).
  final Set<String> links;

  final String _searchText;

  String get pathKey => entry.pathKey;

  static String _title(
    FolderEntry entry,
    Frontmatter? frontmatter,
    String body,
  ) {
    final title = frontmatter?.data?['title'];
    if (title is String && title.trim().isNotEmpty) return title.trim();
    final heading = RegExp(
      r'^\s{0,3}#[ \t]+(.+?)[ \t]*#*$',
      multiLine: true,
    ).firstMatch(body);
    if (heading != null) return heading.group(1)!.trim();
    return entry.name.replaceFirst(
      RegExp(r'\.(md|txt)$', caseSensitive: false),
      '',
    );
  }

  static Set<String> _links(String body, FolderEntry entry, NoteFolder folder) {
    final targets = <String>[
      for (final match in RegExp(r'!?\[\[([^\[\]\n]+)\]\]').allMatches(body))
        WikiTarget.parse(match.group(1)!).target,
      for (final match in RegExp(
        r'(?<!!)\[[^\]]*\]\(([^)\s]+\.md)(?:#[^)]*)?\)',
        caseSensitive: false,
      ).allMatches(body))
        match.group(1)!,
    ];
    final links = <String>{};
    for (final target in targets) {
      if (target.isEmpty) continue;
      final resolved =
          folder.resolveRelative(target, entry.path) ??
          folder.resolve(target, entry.path, markdown: true);
      if (resolved != null &&
          resolved.isNote &&
          resolved.pathKey != entry.pathKey) {
        links.add(resolved.pathKey);
      }
    }
    return links;
  }
}

/// Tags from frontmatter, `## tags:` headings and inline `#tags`
/// (code excluded), in first-seen order without duplicates.
List<String> noteTags(String content) {
  final frontmatter = Frontmatter.parse(content);
  final body = stripFencedCode(frontmatter.body);
  final seen = <String>{};
  final tags = <String>[];
  void add(String raw) {
    final tag = raw.trim().replaceFirst('#', '');
    if (tag.isEmpty || !seen.add(tag.toLowerCase())) return;
    tags.add(tag);
  }

  frontmatter.tags.forEach(add);
  for (final match in RegExp(
    r'^##[ \t]+tags[ \t]*:[ \t]*(.*)$',
    caseSensitive: false,
    multiLine: true,
  ).allMatches(body)) {
    var value = match.group(1)!.trim();
    if (value.startsWith('[') && value.endsWith(']')) {
      value = value.substring(1, value.length - 1);
    }
    for (final part in value.split(RegExp(r'[,，]'))) {
      add(part.trim().replaceAll(RegExp(r'''^['"]|['"]$'''), ''));
    }
  }
  final withoutTagHeadings = body.replaceAll(
    RegExp(r'^##[ \t]+tags[ \t]*:.*$', caseSensitive: false, multiLine: true),
    '',
  );
  for (final match in RegExp(
    r'(?<![\w/#&])#([\p{L}\p{N}_-]*[\p{L}_-][\p{L}\p{N}_-]*)',
    unicode: true,
  ).allMatches(withoutTagHeadings)) {
    add(match.group(1)!);
  }
  return tags;
}

class SearchHit {
  const SearchHit({
    required this.note,
    required this.offset,
    required this.snippet,
    required this.matchStart,
    required this.matchLength,
    required this.matchCount,
  });

  final IndexedNote note;

  /// Character offset of the first match in the note.
  final int offset;

  /// Context around the first match, on one line.
  final String snippet;
  final int matchStart;
  final int matchLength;
  final int matchCount;
}

class NoteIndex {
  NoteIndex(List<IndexedNote> notes, {this.skipped = const []})
    : notes = List.unmodifiable(notes),
      _byPath = {for (final note in notes) note.pathKey: note};

  final List<IndexedNote> notes;

  /// Notes left out (too large or unreadable).
  final List<FolderEntry> skipped;
  final Map<String, IndexedNote> _byPath;

  IndexedNote? operator [](String pathKey) => _byPath[pathKey];

  /// Notes that link to [pathKey].
  List<IndexedNote> backlinks(String pathKey) => [
    for (final note in notes)
      if (note.links.contains(pathKey)) note,
  ]..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

  /// Notes carrying [tag] (case-insensitive).
  List<IndexedNote> withTag(String tag) {
    final wanted = tag.replaceFirst('#', '').toLowerCase();
    return [
      for (final note in notes)
        if (note.tags.any((item) => item.toLowerCase() == wanted)) note,
    ]..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
  }

  /// Every tag with its note count, most used first.
  List<MapEntry<String, int>> get tagCounts {
    final counts = <String, int>{};
    final display = <String, String>{};
    for (final note in notes) {
      for (final tag in note.tags) {
        final key = tag.toLowerCase();
        counts[key] = (counts[key] ?? 0) + 1;
        display.putIfAbsent(key, () => tag);
      }
    }
    final entries =
        [
          for (final entry in counts.entries)
            MapEntry(display[entry.key]!, entry.value),
        ]..sort((a, b) {
          final count = b.value.compareTo(a.value);
          return count != 0 ? count : a.key.compareTo(b.key);
        });
    return entries;
  }

  /// Case-insensitive search across titles, paths and contents. Title
  /// matches rank first, then by match count.
  List<SearchHit> search(String query, {int limit = 100}) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return const [];
    final hits = <(SearchHit, bool)>[];
    for (final note in notes) {
      final inTitle =
          note.title.toLowerCase().contains(needle) ||
          note.pathKey.toLowerCase().contains(needle);
      final first = note._searchText.indexOf(needle);
      if (first < 0 && !inTitle) continue;
      var count = 0;
      for (
        var at = first;
        at >= 0 && count < 999;
        at = note._searchText.indexOf(needle, at + needle.length)
      ) {
        count++;
      }
      hits.add((_hit(note, first, needle.length, count), inTitle));
    }
    hits.sort((a, b) {
      if (a.$2 != b.$2) return a.$2 ? -1 : 1;
      return b.$1.matchCount.compareTo(a.$1.matchCount);
    });
    return [for (final hit in hits.take(limit)) hit.$1];
  }

  static SearchHit _hit(IndexedNote note, int offset, int length, int count) {
    if (offset < 0) {
      final preview = note.content.trim().replaceAll(RegExp(r'\s+'), ' ');
      return SearchHit(
        note: note,
        offset: 0,
        snippet: preview.length > 80 ? '${preview.substring(0, 80)}…' : preview,
        matchStart: 0,
        matchLength: 0,
        matchCount: count,
      );
    }
    const before = 24;
    const after = 56;
    final start = (offset - before).clamp(0, note.content.length);
    final end = (offset + length + after).clamp(0, note.content.length);
    final prefix = start > 0 ? '…' : '';
    final suffix = end < note.content.length ? '…' : '';
    final raw = note.content.substring(start, end);
    final leading = raw
        .substring(0, offset - start)
        .replaceAll(RegExp(r'\s+'), ' ');
    final snippet = '$prefix$leading${raw.substring(offset - start)}'
        .replaceAll(RegExp(r'\s+'), ' ');
    return SearchHit(
      note: note,
      offset: offset,
      snippet: '$snippet$suffix',
      matchStart: prefix.length + leading.length,
      matchLength: length,
      matchCount: count,
    );
  }
}
