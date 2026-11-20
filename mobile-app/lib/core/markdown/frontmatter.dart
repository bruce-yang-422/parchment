/// YAML Frontmatter parsing, ported from the web reader's `noteSyntax.js`.
///
/// Supports the YAML subset used by note properties: scalars, quoted strings,
/// inline arrays, block lists and `|` / `>` multi-line strings. Nested objects
/// are kept as raw text.
library;

final RegExp _frontmatterPattern = RegExp(
  r'^﻿?---[ \t]*\r?\n(?:([\s\S]*?)\r?\n)?(?:---|\.\.\.)[ \t]*(?:\r?\n|$)',
);

class Frontmatter {
  const Frontmatter({
    required this.data,
    required this.raw,
    required this.body,
  });

  /// Parsed properties, or `null` when the document has no frontmatter.
  final Map<String, Object?>? data;

  /// The YAML text between the fences.
  final String raw;

  /// Document content after the frontmatter.
  final String body;

  static Frontmatter parse(String source) {
    final match = _frontmatterPattern.firstMatch(source);
    if (match == null) return Frontmatter(data: null, raw: '', body: source);
    final raw = match.group(1) ?? '';
    return Frontmatter(
      data: parseYamlSubset(raw),
      raw: raw,
      body: source.substring(match.end),
    );
  }

  List<String> get tags {
    final values = data;
    if (values == null) return const [];
    final raw = values['tags'] ?? values['tag'] ?? values['Tags'];
    final list = switch (raw) {
      null => const <Object?>[],
      final List<Object?> items => items,
      _ => raw.toString().split(RegExp(r'[,，\s]+')),
    };
    return list
        .map((tag) => (tag ?? '').toString().trim().replaceFirst('#', ''))
        .where((tag) => tag.isNotEmpty)
        .toList();
  }
}

Map<String, Object?> parseYamlSubset(String raw) {
  final data = <String, Object?>{};
  final lines = raw.split(RegExp(r'\r?\n'));
  final keyPattern = RegExp(r'^([^:#][^:]*?)[ \t]*:(?:[ \t]+(.*?))?[ \t]*$');
  var index = 0;

  bool isIndented(String line) => line.startsWith(RegExp(r'\s'));

  while (index < lines.length) {
    final line = lines[index];
    if (line.trim().isEmpty ||
        RegExp(r'^\s*#').hasMatch(line) ||
        isIndented(line)) {
      index++;
      continue;
    }
    final match = keyPattern.firstMatch(line);
    if (match == null) {
      index++;
      continue;
    }
    final key = _unquote(match.group(1)!.trim());
    final value = match.group(2) ?? '';
    index++;

    final block = <String>[];
    while (index < lines.length &&
        (lines[index].trim().isEmpty ||
            isIndented(lines[index]) ||
            RegExp(r'^-(\s|$)').hasMatch(lines[index]))) {
      block.add(lines[index]);
      index++;
    }
    while (block.isNotEmpty && block.last.trim().isEmpty) {
      block.removeLast();
    }

    if (RegExp(r'^[|>][+-]?\d*$').hasMatch(value)) {
      final content = _dedent(block);
      data[key] = value.startsWith('|')
          ? content.join('\n')
          : content.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    } else if (value.isNotEmpty) {
      data[key] = _parseScalarOrFlow(value);
    } else if (block.isNotEmpty &&
        block.every(
          (l) => l.trim().isEmpty || RegExp(r'^\s*-(\s|$)').hasMatch(l),
        )) {
      data[key] = block
          .where((l) => l.trim().isNotEmpty)
          .map((l) => _parseScalar(l.replaceFirst(RegExp(r'^\s*-\s?'), '')))
          .toList();
    } else if (block.isNotEmpty) {
      data[key] = _dedent(block).join('\n');
    } else {
      data[key] = null;
    }
  }
  return data;
}

List<String> _dedent(List<String> lines) {
  final indents = lines
      .where((line) => line.trim().isNotEmpty)
      .map((line) => RegExp(r'^\s*').firstMatch(line)!.group(0)!.length);
  final indent = indents.isEmpty ? 0 : indents.reduce((a, b) => a < b ? a : b);
  return lines
      .map((line) => line.length >= indent ? line.substring(indent) : '')
      .toList();
}

Object? _parseScalarOrFlow(String value) {
  final trimmed = value.trim();
  if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
    return _splitFlow(
      trimmed.substring(1, trimmed.length - 1),
    ).map(_parseScalar).where((item) => item != '').toList();
  }
  return _parseScalar(trimmed);
}

List<String> _splitFlow(String text) {
  final items = <String>[];
  final current = StringBuffer();
  String? quote;
  var depth = 0;
  for (final char in text.split('')) {
    if (quote != null) {
      current.write(char);
      if (char == quote) quote = null;
    } else if (char == '"' || char == "'") {
      quote = char;
      current.write(char);
    } else if (char == '[') {
      depth++;
      current.write(char);
    } else if (char == ']') {
      depth--;
      current.write(char);
    } else if (char == ',' && depth == 0) {
      items.add(current.toString());
      current.clear();
    } else {
      current.write(char);
    }
  }
  if (current.toString().trim().isNotEmpty) items.add(current.toString());
  return items;
}

Object? _parseScalar(String value) {
  final text = value.trim();
  if (text.isEmpty) return '';
  if (text == '~' || text == 'null') return null;
  if (RegExp(r'^"(?:[^"\\]|\\.)*"$').hasMatch(text)) {
    return text
        .substring(1, text.length - 1)
        .replaceAllMapped(
          RegExp(r'\\(.)'),
          (m) => switch (m.group(1)) {
            'n' => '\n',
            't' => '\t',
            final other => other!,
          },
        );
  }
  if (RegExp(r"^'(?:[^']|'')*'$").hasMatch(text)) {
    return text.substring(1, text.length - 1).replaceAll("''", "'");
  }
  // Unquoted values drop trailing comments.
  final unquoted = text.replaceFirst(RegExp(r'\s+#.*$'), '');
  return switch (unquoted) {
    'true' || 'True' || 'TRUE' => true,
    'false' || 'False' || 'FALSE' => false,
    _ => unquoted,
  };
}

String _unquote(String text) {
  return RegExp(r'''^(["']).*\1$''').hasMatch(text)
      ? text.substring(1, text.length - 1)
      : text;
}
