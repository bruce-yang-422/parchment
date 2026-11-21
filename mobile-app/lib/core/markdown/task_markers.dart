/// Locates task-list checkbox markers (`- [ ]`, `1. [x]`) in Markdown source
/// so reader-side toggles can be written back by changing exactly one
/// character per task.
///
/// The order matches the top-level reader, which numbers tasks as the
/// Markdown parser emits them: fenced code and frontmatter are skipped, and
/// callouts are excluded because their bodies are rendered separately with
/// read-only checkboxes.
library;

import 'frontmatter.dart';
import '../l10n/tr.dart';

final RegExp _fence = RegExp(r'^\s{0,3}(?:>\s?)*\s{0,3}(`{3,}|~{3,})');
final RegExp _calloutStart = RegExp(r'^[ ]{0,3}>[ \t]?\[![A-Za-z][\w-]*\]');
final RegExp _quoted = RegExp(r'^[ ]{0,3}>');
final RegExp _task = RegExp(
  r'^(?:[ ]{0,3}>[ \t]?)*[ \t]*(?:[-*+]|\d{1,9}[.)])[ \t]+\[([ xX])\](?=[ \t])',
);

/// Character offsets of the state character inside each task's brackets.
List<int> findTaskMarkerOffsets(String content) {
  final frontmatter = Frontmatter.parse(content);
  var offset = content.length - frontmatter.body.length;
  final offsets = <int>[];
  String? fence;
  var inCallout = false;

  for (final line in frontmatter.body.split('\n')) {
    final fenceMatch = _fence.firstMatch(line);
    if (fenceMatch != null) {
      final marker = fenceMatch.group(1)![0];
      if (fence == null) {
        fence = marker;
      } else if (marker == fence) {
        fence = null;
      }
    } else if (fence == null) {
      if (inCallout && !_quoted.hasMatch(line)) inCallout = false;
      if (!inCallout && _calloutStart.hasMatch(line)) inCallout = true;
      if (!inCallout) {
        final match = _task.firstMatch(line);
        if (match != null) offsets.add(offset + match.end - 2);
      }
    }
    offset += line.length + 1;
  }
  return offsets;
}

class TaskMarkerMismatchException implements Exception {
  const TaskMarkerMismatchException();

  @override
  String toString() => tr('找不到要更新的勾選位置，檔案沒有被修改。');
}

/// Returns [content] with each task in [changes] (task index → checked) set,
/// changing only the single state character. Unchanged tasks keep their
/// original marker (`x` or `X`).
///
/// Throws [TaskMarkerMismatchException] when the source scan does not find
/// [expectedTaskCount] tasks, so a mismatch never writes to the wrong line.
String applyTaskChanges(
  String content,
  Map<int, bool> changes, {
  required int expectedTaskCount,
}) {
  final offsets = findTaskMarkerOffsets(content);
  if (offsets.length != expectedTaskCount) {
    throw const TaskMarkerMismatchException();
  }
  final buffer = StringBuffer();
  var cursor = 0;
  final indexes = changes.keys.toList()..sort();
  for (final index in indexes) {
    if (index < 0 || index >= offsets.length) {
      throw const TaskMarkerMismatchException();
    }
    final position = offsets[index];
    final current = content[position];
    final checked = changes[index]!;
    final next = checked ? (current == ' ' ? 'x' : current) : ' ';
    buffer
      ..write(content.substring(cursor, position))
      ..write(next);
    cursor = position + 1;
  }
  buffer.write(content.substring(cursor));
  return buffer.toString();
}
