/// Safe HTML inside Markdown, the way Obsidian's reading view shows it.
///
/// Nothing is ever executed or loaded as HTML: an allowlist of tags is
/// turned into the same AST elements Markdown produces (`<b>` → `strong`,
/// `<kbd>` → `kbd`, `<details>` → `html-details` …). Dangerous tags
/// (`<script>`, `<style>`, `<iframe>` …) are dropped with their content,
/// comments are hidden, and wrapper tags such as `<div>` or `<span>` keep
/// only their text. Unknown tags (for example `List<String>`) are left as
/// typed.
library;

import 'package:markdown/markdown.dart' as md;

/// Inline tags and the AST element they become.
const Map<String, String> _inlineTags = {
  'b': 'strong',
  'strong': 'strong',
  'i': 'em',
  'em': 'em',
  'cite': 'em',
  'dfn': 'em',
  'var': 'em',
  'u': 'ins',
  'ins': 'ins',
  's': 'del',
  'del': 'del',
  'strike': 'del',
  'mark': 'mark',
  'sup': 'sup-text',
  'sub': 'sub-text',
};

/// Tags whose text is kept literally (no Markdown inside).
const Map<String, String> _literalTags = {
  'kbd': 'kbd',
  'code': 'code',
  'samp': 'code',
  'tt': 'code',
};

/// Wrappers that only keep their content.
const Set<String> _transparentTags = {
  'span', 'font', 'small', 'big', 'time', 'label', 'q', 'abbr', 'a', //
  'div', 'p', 'center', 'section', 'article', 'header', 'footer', 'main',
  'aside', 'nav', 'figure', 'figcaption', 'picture', 'details', 'summary',
  'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'blockquote',
};

/// Dropped together with everything inside them.
const Set<String> _droppedTags = {
  'script', 'style', 'iframe', 'noscript', 'template', 'object', 'embed', //
  'frame', 'frameset', 'applet', 'form', 'button', 'select', 'textarea',
  'svg', 'math', 'video', 'audio', 'canvas',
};

/// Tags without a closing tag.
const Set<String> _voidTags = {'br', 'wbr', 'img', 'hr', 'input', 'source'};

final Set<String> _knownTags = {
  ..._inlineTags.keys,
  ..._literalTags.keys,
  ..._transparentTags,
  ..._droppedTags,
  ..._voidTags,
};

String _tagAlternation() =>
    (_knownTags.toList()..sort((a, b) => b.length.compareTo(a.length))).join(
      '|',
    );

final RegExp _attributePattern = RegExp(
  r'''([A-Za-z_:][-\w:.]*)\s*(?:=\s*(?:"([^"]*)"|'([^']*)'|([^\s"'=<>`]+)))?''',
);

/// Attributes of a start tag, lower-cased names.
Map<String, String> parseHtmlAttributes(String source) {
  final attributes = <String, String>{};
  for (final match in _attributePattern.allMatches(source)) {
    attributes[match.group(1)!.toLowerCase()] = decodeHtmlEntities(
      match.group(2) ?? match.group(3) ?? match.group(4) ?? '',
    );
  }
  return attributes;
}

/// Decodes the common named entities and numeric references.
String decodeHtmlEntities(String text) => text.replaceAllMapped(
  RegExp(r'&(#[xX][0-9a-fA-F]+|#[0-9]+|[A-Za-z]+);'),
  (match) {
    final entity = match.group(1)!;
    if (entity.startsWith('#')) {
      final hex = entity.length > 1 && (entity[1] == 'x' || entity[1] == 'X');
      final code = int.tryParse(
        entity.substring(hex ? 2 : 1),
        radix: hex ? 16 : 10,
      );
      return code == null || code > 0x10FFFF
          ? match.group(0)!
          : String.fromCharCode(code);
    }
    return switch (entity) {
      'amp' => '&',
      'lt' => '<',
      'gt' => '>',
      'quot' => '"',
      'apos' => "'",
      'nbsp' => ' ',
      'copy' => '©',
      'reg' => '®',
      'trade' => '™',
      'hellip' => '…',
      'mdash' => '—',
      'ndash' => '–',
      _ => match.group(0)!,
    };
  },
);

/// Link targets that are safe to open: web, mail, phone, and relative paths.
bool isSafeHref(String href) {
  final value = href.trim();
  if (value.isEmpty) return false;
  final scheme = RegExp(r'^([A-Za-z][A-Za-z0-9+.-]*):').firstMatch(value);
  if (scheme == null) return true;
  return const {
    'http',
    'https',
    'mailto',
    'tel',
  }.contains(scheme.group(1)!.toLowerCase());
}

/// Image sources that may be shown: web, data images, and relative paths.
bool isSafeImageSource(String src) {
  final value = src.trim();
  if (value.toLowerCase().startsWith('data:image/')) return true;
  return isSafeHref(value) &&
      !RegExp(r'^(mailto|tel):', caseSensitive: false).hasMatch(value);
}

/// Index just past the closing tag that matches an opening [tag] whose
/// content starts at [from], or `null` when it is not closed.
({int contentEnd, int end})? findClosingTag(
  String source,
  String tag,
  int from,
) {
  final pattern = RegExp('<(/?)$tag(?=[\\s/>])[^<>]*>', caseSensitive: false);
  var depth = 1;
  for (final match in pattern.allMatches(source, from)) {
    final text = match.group(0)!;
    if (match.group(1)!.isNotEmpty) {
      depth--;
    } else if (!text.endsWith('/>')) {
      depth++;
    }
    if (depth == 0) return (contentEnd: match.start, end: match.end);
  }
  return null;
}

/* ──────────────────── Inline ──────────────────── */

/// Allowlisted inline HTML: `<kbd>`, `<u>`, `<sup>`, `<br>`, `<a>`, `<img>` …
class InlineHtmlSyntax extends md.InlineSyntax {
  InlineHtmlSyntax()
    : super(
        '<!--[\\s\\S]*?-->|<(/?)(${_tagAlternation()})(?=[\\s/>])([^<>]*)>',
        startCharacter: 0x3C,
        caseSensitive: false,
      );

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final whole = match.group(0)!;
    if (whole.startsWith('<!--')) return true;
    final closing = match.group(1)!.isNotEmpty;
    final tag = match.group(2)!.toLowerCase();
    var rawAttributes = match.group(3)!;
    final selfClosing = rawAttributes.trimRight().endsWith('/');
    if (selfClosing) {
      rawAttributes = rawAttributes.substring(
        0,
        rawAttributes.lastIndexOf('/'),
      );
    }
    // Stray closing tags are hidden.
    if (closing) return true;

    final attributes = parseHtmlAttributes(rawAttributes);
    if (_voidTags.contains(tag) || selfClosing) {
      final node = _voidElement(tag, attributes);
      if (node != null) parser.addNode(node);
      return true;
    }

    final contentStart = parser.pos + whole.length;
    final close = findClosingTag(parser.source, tag, contentStart);
    if (close == null) {
      // An opening tag without its end: hide just the tag.
      return true;
    }
    final inner = parser.source.substring(contentStart, close.contentEnd);
    parser.consume(close.end - parser.pos);

    if (_droppedTags.contains(tag)) return false;
    if (_literalTags[tag] case final element?) {
      parser.addNode(md.Element.text(element, decodeHtmlEntities(inner)));
      return false;
    }
    final children = md.InlineParser(inner, parser.document).parse();
    if (_inlineTags[tag] case final element?) {
      parser.addNode(md.Element(element, children));
    } else if (tag == 'a' && isSafeHref(attributes['href'] ?? '')) {
      parser.addNode(
        md.Element('a', children)
          ..attributes['href'] = attributes['href']!.trim(),
      );
    } else if (tag == 'abbr' && (attributes['title'] ?? '').isNotEmpty) {
      parser.addNode(
        md.Element('abbr', children)
          ..attributes['title'] = attributes['title']!,
      );
    } else if (tag == 'q') {
      parser
        ..addNode(md.Text('“'))
        ..addNode(md.Element('html-group', children))
        ..addNode(md.Text('”'));
    } else {
      parser.addNode(md.Element('html-group', children));
    }
    return false;
  }

  static md.Node? _voidElement(String tag, Map<String, String> attributes) {
    switch (tag) {
      case 'br':
        return md.Element.empty('br');
      case 'img':
        final src = attributes['src'] ?? '';
        if (!isSafeImageSource(src)) return null;
        final image = md.Element.empty('html-img')
          ..attributes['src'] = src.trim();
        for (final name in const ['alt', 'title', 'width', 'height']) {
          if (attributes[name] case final value? when value.isNotEmpty) {
            image.attributes[name] = value;
          }
        }
        return image;
      default:
        return null;
    }
  }
}

/* ──────────────────── Blocks ──────────────────── */

final RegExp _blockStart = RegExp(
  '^ {0,3}(?:<!--|</?(${_tagAlternation()})(?=[\\s/>]|\$))',
  caseSensitive: false,
);

/// Block HTML that starts a line: `<details>`, `<div align="center">`,
/// comments, `<script>` … Inline and void tags such as a lone `<img>` must
/// fall through to [InlineHtmlSyntax]. Wrapping those in another `html-block`
/// would feed the identical source back into the nested Markdown renderer and
/// recurse until the app runs out of stack.
class HtmlBlockSyntax extends md.BlockSyntax {
  const HtmlBlockSyntax();

  @override
  RegExp get pattern => _blockStart;

  @override
  bool canParse(md.BlockParser parser) {
    final match = _blockStart.firstMatch(parser.current.content);
    if (match == null) return false;
    final tag = match.group(1)?.toLowerCase();
    // Inline-level tags at the start of a paragraph stay in the paragraph.
    return tag == null ||
        _droppedTags.contains(tag) ||
        _transparentTags.contains(tag) && !_inlineWrappers.contains(tag) ||
        tag == 'hr' ||
        _voidTags.contains(tag) && _loneTag.hasMatch(parser.current.content);
  }

  static final _loneTag = RegExp(r'^ {0,3}<[^<>]+>\s*$');

  static const _inlineWrappers = {
    'span', 'font', 'small', 'big', 'time', 'label', 'q', 'abbr', 'a', //
  };

  @override
  md.Node? parse(md.BlockParser parser) {
    final first = parser.current.content;
    final match = _blockStart.firstMatch(first)!;
    final tag = match.group(1)?.toLowerCase();

    if (tag == null) {
      _consumeUntil(parser, (line) => line.contains('-->'));
      return null;
    }
    if (_droppedTags.contains(tag)) {
      _consumeBalanced(parser, tag);
      return null;
    }
    if (tag == 'details' && !first.trimLeft().startsWith('</')) {
      return _details(_consumeBalanced(parser, tag));
    }
    if (tag == 'hr') {
      parser.advance();
      return md.Element.empty('hr');
    }
    // A void tag on its own line is a block to CommonMark, so the inline
    // parser never sees it. Convert it directly; do not wrap its unchanged
    // source in `html-block`, which would recursively render forever.
    if (_voidTags.contains(tag) && _loneTag.hasMatch(first)) {
      final rawAttributes = RegExp(
        '<$tag(?=[\\s/>])([^<>]*)>',
        caseSensitive: false,
      ).firstMatch(first)?.group(1) ?? '';
      parser.advance();
      return InlineHtmlSyntax._voidElement(
        tag,
        parseHtmlAttributes(rawAttributes.replaceFirst(RegExp(r'/\s*$'), '')),
      );
    }

    // Other wrappers: up to the next blank line (CommonMark HTML block).
    final lines = <String>[];
    while (!parser.isDone && !_isBlank(parser.current.content)) {
      lines.add(parser.current.content);
      parser.advance();
    }
    return htmlWrapperToMarkdown(lines.join('\n'));
  }

  static bool _isBlank(String line) => line.trim().isEmpty;

  static void _consumeUntil(md.BlockParser parser, bool Function(String) end) {
    while (!parser.isDone) {
      final line = parser.current.content;
      parser.advance();
      if (end(line)) return;
    }
  }

  /// Lines up to the end of the outermost [tag], nesting included.
  static String _consumeBalanced(md.BlockParser parser, String tag) {
    final open = RegExp('<$tag(?=[\\s/>]|\$)', caseSensitive: false);
    final close = RegExp('</$tag\\s*>', caseSensitive: false);
    final lines = <String>[];
    var depth = 0;
    while (!parser.isDone) {
      final line = parser.current.content;
      lines.add(line);
      parser.advance();
      depth += open.allMatches(line).length - close.allMatches(line).length;
      if (depth <= 0) break;
    }
    return lines.join('\n');
  }

  static md.Node _details(String source) {
    final start = RegExp(
      r'<details([^<>]*)>',
      caseSensitive: false,
    ).firstMatch(source)!;
    final attributes = parseHtmlAttributes(start.group(1)!);
    final close = findClosingTag(source, 'details', start.end);
    var inner = source.substring(start.end, close?.contentEnd ?? source.length);
    var summary = '';
    final summaryMatch = RegExp(
      r'^\s*<summary[^<>]*>([\s\S]*?)</summary\s*>',
      caseSensitive: false,
    ).firstMatch(inner);
    if (summaryMatch != null) {
      summary = summaryMatch.group(1)!.trim();
      inner = inner.substring(summaryMatch.end);
    }
    return md.Element('html-details', [md.Text('')])
      ..attributes['summary'] = summary
      ..attributes['open'] = attributes.containsKey('open') ? 'true' : ''
      ..attributes['body'] = _dedent(inner).trim();
  }

  /// Removes indentation shared by all lines, so indented HTML content is
  /// not read as a code block.
  static String _dedent(String text) {
    final lines = text.split('\n');
    final indents = [
      for (final line in lines)
        if (line.trim().isNotEmpty) line.length - line.trimLeft().length,
    ];
    if (indents.isEmpty) return text;
    final shared = indents.reduce((a, b) => a < b ? a : b);
    return [
      for (final line in lines)
        line.length >= shared ? line.substring(shared) : line.trimLeft(),
    ].join('\n');
  }
}

/// Turns a block of wrapper HTML (`<div>`, `<p align="center">`, `<h1>` …)
/// into an `html-block` element holding plain Markdown, or `null` when
/// nothing is left to show.
md.Node? htmlWrapperToMarkdown(String source) {
  final centered = RegExp(
    r'''<center\b|align\s*=\s*["']?center''',
    caseSensitive: false,
  ).hasMatch(source);
  var text = source;
  // Headings become Markdown headings on their own line.
  text = text.replaceAllMapped(
    RegExp(r'<h([1-6])\b[^<>]*>([\s\S]*?)</h\1\s*>', caseSensitive: false),
    (match) =>
        '\n\n${'#' * int.parse(match.group(1)!)} '
        '${match.group(2)!.replaceAll('\n', ' ').trim()}\n\n',
  );
  text = text.replaceAll(
    RegExp(
      r'</?(?:div|p|center|section|article|header|footer|main|aside|nav|'
      r'figure|figcaption|picture|blockquote)(?=[\s/>])[^<>]*>',
      caseSensitive: false,
    ),
    '\n\n',
  );
  text = text.replaceAll(RegExp(r'<!--[\s\S]*?-->'), '');
  final lines = [for (final line in text.split('\n')) line.trim()];
  final markdown = lines
      .join('\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
  if (markdown.isEmpty) return null;
  return md.Element('html-block', [md.Text('')])
    ..attributes['markdown'] = markdown
    ..attributes['center'] = centered ? 'true' : '';
}
