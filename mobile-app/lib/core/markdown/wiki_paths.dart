/// Wiki link path resolution and note section extraction, ported from the
/// web reader's `noteSyntax.js` so both resolve links the same way.
library;

import 'dart:convert';

import 'frontmatter.dart';

/// Resolves a wiki link target:
/// 1. relative to the source note, 2. relative to the root,
/// 3. by file name anywhere (same folder first, then the shortest path).
///
/// With [markdown], a target without an extension also tries `.md`.
/// Decodes valid `%XX` escapes (UTF-8) and leaves everything else as it is.
///
/// [Uri.decodeComponent] throws on text that is already decoded, such as
/// `筆記.md`, and on a lone `%` (`100%`); links in notes often mix both.
String decodePercent(String value) {
  if (!value.contains('%')) return value;
  return value.replaceAllMapped(RegExp(r'(?:%[0-9A-Fa-f]{2})+'), (match) {
    final escaped = match.group(0)!;
    final bytes = [
      for (var i = 0; i < escaped.length; i += 3)
        int.parse(escaped.substring(i + 1, i + 3), radix: 16),
    ];
    return utf8.decode(bytes, allowMalformed: true);
  });
}

List<String>? resolveWikiPath(
  String target,
  List<String> sourcePath,
  List<List<String>> filePaths, {
  bool markdown = false,
}) {
  var value = target.trim().replaceFirst(RegExp(r'^/+'), '');
  value = decodePercent(value);
  if (value.isEmpty) return null;

  final byKey = {for (final path in filePaths) _key(path): path};
  final variants = [
    if (markdown &&
        !RegExp(r'\.[a-z0-9]{1,8}$', caseSensitive: false).hasMatch(value))
      '$value.md',
    value,
  ];

  final sourceDirectory = sourcePath.isEmpty
      ? const <String>[]
      : sourcePath.sublist(0, sourcePath.length - 1);
  for (final variant in variants) {
    final parts = variant.split('/');
    for (final candidate in [
      [...sourceDirectory, ...parts],
      parts,
    ]) {
      final normalized = normalizePath(candidate);
      if (normalized == null) continue;
      final found = byKey[_key(normalized)];
      if (found != null) return found;
    }
  }

  final sourceKey = _key(sourceDirectory);
  for (final variant in variants) {
    final suffix = normalizePath(variant.split('/'));
    if (suffix == null || suffix.isEmpty) continue;
    final suffixKey = _key(suffix);
    final matches = filePaths.where((path) {
      if (path.length < suffix.length) return false;
      return _key(path.sublist(path.length - suffix.length)) == suffixKey;
    }).toList();
    if (matches.isEmpty) continue;
    int sameFolder(List<String> path) =>
        _key(path.sublist(0, path.length - 1)) == sourceKey ? 0 : 1;
    matches.sort((a, b) {
      final folder = sameFolder(a) - sameFolder(b);
      if (folder != 0) return folder;
      final length = a.length - b.length;
      if (length != 0) return length;
      return _key(a).compareTo(_key(b));
    });
    return matches.first;
  }
  return null;
}

/// Normalizes `.` and `..` segments; returns `null` when escaping the root.
List<String>? normalizePath(List<String> parts) {
  final output = <String>[];
  for (final raw in parts) {
    final part = raw.trim();
    if (part.isEmpty || part == '.') continue;
    if (part == '..') {
      if (output.isEmpty) return null;
      output.removeLast();
    } else {
      output.add(part);
    }
  }
  return output;
}

String _key(List<String> path) => path.join('/').toLowerCase();

/// Extracts a heading section (from the heading to the next heading of the
/// same or higher level) or a `^block`. Without either, returns the whole
/// body. Returns `null` when the section does not exist.
String? extractNoteSection(
  String markdown, {
  String heading = '',
  String blockId = '',
}) {
  final body = Frontmatter.parse(markdown).body;
  if (heading.isEmpty && blockId.isEmpty) return body;
  final lines = body.split(RegExp(r'\r?\n'));

  if (heading.isNotEmpty) {
    final wanted = headingKey(heading);
    String? fence;
    var start = -1;
    var level = 0;
    final fencePattern = RegExp(r'^\s{0,3}(`{3,}|~{3,})');
    final headingPattern = RegExp(
      r'^\s{0,3}(#{1,6})[ \t]+(.*?)[ \t]*#*[ \t]*$',
    );
    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      final fenceMatch = fencePattern.firstMatch(line);
      if (fenceMatch != null) {
        final marker = fenceMatch.group(1)![0];
        if (fence == null) {
          fence = marker;
        } else if (marker == fence) {
          fence = null;
        }
        continue;
      }
      if (fence != null) continue;
      final match = headingPattern.firstMatch(line);
      if (match == null) continue;
      if (start < 0) {
        if (headingKey(match.group(2)!) == wanted) {
          start = index;
          level = match.group(1)!.length;
        }
      } else if (match.group(1)!.length <= level) {
        return lines.sublist(start, index).join('\n').trimRight();
      }
    }
    return start >= 0 ? lines.sublist(start).join('\n').trimRight() : null;
  }

  final marker = RegExp('(?:^|\\s)\\^${RegExp.escape(blockId)}\\s*\$');
  final index = lines.indexWhere(marker.hasMatch);
  if (index < 0) return null;
  String strip(String line) => line.replaceFirst(marker, '').trimRight();
  if (RegExp(r'^\s*(?:[-*+]|\d+[.)])\s').hasMatch(lines[index])) {
    return strip(lines[index]);
  }
  bool isBoundary(String line) =>
      line.trim().isEmpty ||
      RegExp(
        r'^\s{0,3}(?:#{1,6}[ \t]|`{3,}|~{3,}|[-*+][ \t]|\d+[.)][ \t])',
      ).hasMatch(line);
  var start = index;
  var end = index;
  while (start > 0 && !isBoundary(lines[start - 1])) {
    start--;
  }
  while (end < lines.length - 1 && !isBoundary(lines[end + 1])) {
    end++;
  }
  return lines.sublist(start, end + 1).map(strip).join('\n');
}

/// Normalized heading text used to match `[[note#heading]]`.
String headingKey(String text) => text
    .replaceAllMapped(
      RegExp(r'\[\[([^\]|]*\|)?([^\]]*)\]\]'),
      (match) => match.group(2)!,
    )
    .replaceAll(RegExp(r'[*_`~=]'), '')
    .trim()
    .toLowerCase();

/// GitHub-style anchor for a heading, as used by `[text](#8-表格-tables)`:
/// lower case, punctuation removed and spaces turned into hyphens.
String headingSlug(String text) => headingKey(text)
    .replaceAll(RegExp(r'[^\p{L}\p{N}\p{M}\s_-]', unicode: true), '')
    .replaceAll(RegExp(r'\s'), '-');

/// Whether the link target [wanted] (heading text or anchor) names [title].
bool headingMatches(String title, String wanted) {
  final key = headingKey(wanted);
  return headingKey(title) == key || headingSlug(title) == key;
}
