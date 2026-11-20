/// Obsidian / Parchment note syntax for the `markdown` package.
///
/// Mirrors the web reader (`assets/js/noteSyntax.js` and the markdown-it
/// plugins): frontmatter properties, callouts, wiki links and embeds, KaTeX
/// math, abbreviations, definition lists, `==mark==`, `++ins++`, `^sup^`,
/// `~sub~`, `## tags:` properties, emoji and footnotes.
library;

import 'dart:convert';

import 'package:markdown/markdown.dart' as md;

import 'frontmatter.dart';

/// Fenced-code language used to carry frontmatter into the Markdown AST.
const String propertiesFenceLanguage = 'parchment-properties';

final RegExp _fencePattern = RegExp(r'^\s{0,3}(`{3,}|~{3,})');
final RegExp _abbreviationPattern = RegExp(
  r'^\s{0,3}\*\[([^\]]+)\]:[ \t]*(.*)$',
);
final RegExp _blockIdPattern = RegExp(r'[ \t]\^[A-Za-z0-9-]+[ \t]*$');
final RegExp _footnoteDefPattern = RegExp(
  r'^\s{0,3}\[\^([^\]]+)\]:[ \t]*(.*)$',
);

/// A note prepared for rendering.
class PreparedNote {
  PreparedNote({
    required this.frontmatter,
    required this.markdown,
    required this.abbreviations,
    required this.footnotes,
  });

  final Frontmatter frontmatter;

  /// Markdown passed to the renderer. Frontmatter becomes a fenced
  /// [propertiesFenceLanguage] block; abbreviation definitions and `^block`
  /// markers are removed.
  final String markdown;

  final Map<String, String> abbreviations;

  /// Footnote label → raw Markdown, used for the footnote preview sheet.
  final Map<String, String> footnotes;

  static PreparedNote prepare(String source) {
    final frontmatter = Frontmatter.parse(source);
    final abbreviations = <String, String>{};
    final footnotes = <String, String>{};
    final output = <String>[];
    String? fence;
    String? footnoteLabel;

    // Windows line endings would leave `\r` before `$` in every pattern.
    final lines = frontmatter.body.replaceAll('\r\n', '\n').split('\n');
    for (final line in lines) {
      final fenceMatch = _fencePattern.firstMatch(line);
      if (fenceMatch != null) {
        final marker = fenceMatch.group(1)![0];
        if (fence == null) {
          fence = marker;
        } else if (marker == fence) {
          fence = null;
        }
        output.add(line);
        footnoteLabel = null;
        continue;
      }
      if (fence != null) {
        output.add(line);
        continue;
      }

      final abbreviation = _abbreviationPattern.firstMatch(line);
      if (abbreviation != null) {
        final key = abbreviation.group(1)!.trim();
        if (key.isNotEmpty) abbreviations[key] = abbreviation.group(2)!.trim();
        continue;
      }

      final footnote = _footnoteDefPattern.firstMatch(line);
      if (footnote != null) {
        footnoteLabel = footnote.group(1)!.trim();
        footnotes[footnoteLabel] = footnote.group(2)!;
      } else if (footnoteLabel != null) {
        if (line.startsWith(RegExp(r'( {2,}|\t)')) && line.trim().isNotEmpty) {
          footnotes[footnoteLabel] =
              '${footnotes[footnoteLabel]}\n${line.trim()}';
        } else {
          footnoteLabel = null;
        }
      }

      output.add(line.replaceFirst(_blockIdPattern, ''));
    }

    var body = output.join('\n');
    if (frontmatter.data != null && frontmatter.data!.isNotEmpty) {
      body = '~~~~$propertiesFenceLanguage\n${frontmatter.raw}\n~~~~\n\n$body';
    }
    return PreparedNote(
      frontmatter: frontmatter,
      markdown: body,
      abbreviations: abbreviations,
      footnotes: footnotes,
    );
  }

  late final md.ExtensionSet extensionSet = md.ExtensionSet(
    md.ExtensionSet.gitHubFlavored.blockSyntaxes,
    md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
  );

  late final List<md.BlockSyntax> blockSyntaxes = const [
    TagsPropertySyntax(),
    CalloutSyntax(),
    MathBlockSyntax(),
    DefinitionListSyntax(),
  ];

  late final List<md.InlineSyntax> inlineSyntaxes = [
    WikiEmbedSyntax(),
    WikiLinkSyntax(),
    InlineMathSyntax(),
    _SimpleWrapSyntax(r'==(?=\S)(.+?)(?<=\S)==', 'mark', startCharacter: 0x3D),
    _SimpleWrapSyntax(
      r'\+\+(?=\S)(.+?)(?<=\S)\+\+',
      'ins',
      startCharacter: 0x2B,
    ),
    _SimpleWrapSyntax(
      r'(?<!\[)\^([^\^\s\[\]]+)\^',
      'sup-text',
      startCharacter: 0x5E,
    ),
    _SimpleWrapSyntax(
      r'(?<!~)~([^~\s]+)~(?!~)',
      'sub-text',
      startCharacter: 0x7E,
    ),
    if (abbreviations.isNotEmpty) AbbreviationSyntax(abbreviations),
    md.EmojiSyntax(),
  ];

  /// Parses [markdown] into AST nodes with the note syntax enabled.
  List<md.Node> parse(String markdown) {
    final document = md.Document(
      extensionSet: extensionSet,
      blockSyntaxes: blockSyntaxes,
      inlineSyntaxes: inlineSyntaxes,
      encodeHtml: false,
    );
    return document.parse(markdown);
  }
}

/* ──────────────────── Wiki links ──────────────────── */

class WikiTarget {
  const WikiTarget({
    required this.target,
    required this.heading,
    required this.blockId,
    required this.alias,
  });

  final String target;
  final String heading;
  final String blockId;
  final String alias;

  static WikiTarget parse(String raw) {
    final text = raw.trim();
    final pipe = text.indexOf('|');
    final linkPart = (pipe >= 0 ? text.substring(0, pipe) : text)
        .replaceFirst(RegExp(r'\\$'), '')
        .trim();
    final alias = pipe >= 0 ? text.substring(pipe + 1).trim() : '';
    final hash = linkPart.indexOf('#');
    final target = (hash >= 0 ? linkPart.substring(0, hash) : linkPart).trim();
    final subpath = hash >= 0 ? linkPart.substring(hash + 1).trim() : '';
    var heading = '';
    var blockId = '';
    if (subpath.startsWith('^')) {
      blockId = subpath.substring(1).trim();
    } else if (subpath.isNotEmpty) {
      final parts = subpath
          .split('#')
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty);
      heading = parts.isEmpty ? '' : parts.last;
    }
    return WikiTarget(
      target: target,
      heading: heading,
      blockId: blockId,
      alias: alias,
    );
  }

  String get name => target
      .split('/')
      .last
      .replaceFirst(RegExp(r'\.md$', caseSensitive: false), '');

  String get displayText {
    if (alias.isNotEmpty) return alias;
    if (heading.isNotEmpty) return name.isEmpty ? heading : '$name > $heading';
    if (blockId.isNotEmpty) {
      return name.isEmpty ? '^$blockId' : '$name > ^$blockId';
    }
    return name;
  }

  bool get isImage => RegExp(
    r'\.(?:png|jpe?g|gif|webp|svg|bmp|avif|ico)$',
    caseSensitive: false,
  ).hasMatch(target);
}

class WikiLinkSyntax extends md.InlineSyntax {
  WikiLinkSyntax() : super(r'\[\[([^\[\]\n]+)\]\]', startCharacter: 0x5B);

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final raw = match.group(1)!;
    final target = WikiTarget.parse(raw);
    parser.addNode(
      md.Element('wikilink', [md.Text(target.displayText)])
        ..attributes['raw'] = raw,
    );
    return true;
  }
}

class WikiEmbedSyntax extends md.InlineSyntax {
  WikiEmbedSyntax() : super(r'!\[\[([^\[\]\n]+)\]\]', startCharacter: 0x21);

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(
      md.Element('wiki-embed', [md.Text('')])
        ..attributes['raw'] = match.group(1)!,
    );
    return true;
  }
}

/* ──────────────────── Inline formatting ──────────────────── */

class _SimpleWrapSyntax extends md.InlineSyntax {
  _SimpleWrapSyntax(super.pattern, this.tag, {super.startCharacter});

  final String tag;

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text(tag, match.group(1)!));
    return true;
  }
}

class InlineMathSyntax extends md.InlineSyntax {
  InlineMathSyntax()
    : super(
        r'\$(?![\s$])((?:\\.|[^$\\\n])+?)(?<!\s)\$(?!\d)',
        startCharacter: 0x24,
      );

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('math-inline', match.group(1)!));
    return true;
  }
}

class AbbreviationSyntax extends md.InlineSyntax {
  AbbreviationSyntax(this.abbreviations)
    : _unicodePattern = RegExp(
        _source(abbreviations),
        multiLine: true,
        unicode: true,
      ),
      super(_source(abbreviations));

  final Map<String, String> abbreviations;
  final RegExp _unicodePattern;

  static String _source(Map<String, String> abbreviations) {
    final keys = abbreviations.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    return '(?<![\\p{L}\\p{N}_])(${keys.map(RegExp.escape).join('|')})'
        '(?![\\p{L}\\p{N}_])';
  }

  @override
  RegExp get pattern => _unicodePattern;

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final word = match.group(1)!;
    parser.addNode(
      md.Element.text('abbr', word)
        ..attributes['title'] = abbreviations[word] ?? '',
    );
    return true;
  }
}

/* ──────────────────── Block syntaxes ──────────────────── */

/// `> [!type]± title` callouts, including GitHub `> [!NOTE]` alerts.
class CalloutSyntax extends md.BlockquoteSyntax {
  const CalloutSyntax();

  static final RegExp _start = RegExp(
    r'^[ ]{0,3}>[ \t]?\[!([A-Za-z][\w-]*)\]([+-]?)[ \t]*(.*)$',
  );

  @override
  bool canParse(md.BlockParser parser) =>
      _start.hasMatch(parser.current.content);

  @override
  md.Node parse(md.BlockParser parser) {
    final first = _start.firstMatch(parser.current.content)!;
    final lines = parseChildLines(parser);
    final body = lines.skip(1).map((line) => line.content).join('\n');
    return md.Element('callout', [md.Text('')])
      ..attributes['type'] = first.group(1)!.toLowerCase()
      ..attributes['fold'] = first.group(2)!
      ..attributes['title'] = first.group(3)!.trim()
      ..attributes['body'] = body;
  }
}

/// `$$ … $$` display math.
class MathBlockSyntax extends md.BlockSyntax {
  const MathBlockSyntax();

  static final RegExp _pattern = RegExp(r'^[ ]{0,3}\$\$');

  @override
  RegExp get pattern => _pattern;

  @override
  md.Node? parse(md.BlockParser parser) {
    final first = parser.current.content.trim().substring(2);
    final buffer = <String>[];
    parser.advance();
    if (first.trimRight().endsWith(r'$$')) {
      buffer.add(first.trimRight().substring(0, first.trimRight().length - 2));
    } else {
      if (first.trim().isNotEmpty) buffer.add(first);
      while (!parser.isDone) {
        final line = parser.current.content;
        parser.advance();
        final trimmed = line.trimRight();
        if (trimmed.endsWith(r'$$')) {
          buffer.add(trimmed.substring(0, trimmed.length - 2));
          break;
        }
        buffer.add(line);
      }
    }
    return md.Element('math-block', [md.Text('')])
      ..attributes['tex'] = buffer.join('\n').trim();
  }
}

/// `## tags: [a, b]` heading rendered as a tag property.
class TagsPropertySyntax extends md.BlockSyntax {
  const TagsPropertySyntax();

  static final RegExp _pattern = RegExp(
    r'^##[ \t]+tags[ \t]*:[ \t]*(.*)$',
    caseSensitive: false,
  );

  @override
  RegExp get pattern => _pattern;

  @override
  md.Node? parse(md.BlockParser parser) {
    final match = pattern.firstMatch(parser.current.content)!;
    parser.advance();
    var value = match.group(1)!.trim();
    if (value.startsWith('[') && value.endsWith(']')) {
      value = value.substring(1, value.length - 1);
    }
    final tags = value
        .split(RegExp(r'[,，]'))
        .map(
          (tag) => tag
              .trim()
              .replaceAllMapped(
                RegExp(r'''^(['"])(.*)\1$'''),
                (m) => m.group(2)!,
              )
              .replaceFirst('#', '')
              .trim(),
        )
        .where((tag) => tag.isNotEmpty)
        .toList();
    return md.Element('properties', [md.Text('')])
      ..attributes['json'] = jsonEncode({'tags': tags});
  }
}

/// Definition lists:
///
/// ```markdown
/// Term
/// : Definition
/// ```
class DefinitionListSyntax extends md.BlockSyntax {
  const DefinitionListSyntax();

  static final RegExp _definition = RegExp(r'^[ ]{0,3}:[ \t]+(.*)$');
  static final RegExp _notTerm = RegExp(
    r'^\s{0,3}(?:[#>|:`~]|[-*+][ \t]|\d+[.)][ \t]|\$\$)',
  );

  static final RegExp _pattern = RegExp(r'^(?!\s*$).+$');

  @override
  RegExp get pattern => _pattern;

  @override
  bool canParse(md.BlockParser parser) {
    final line = parser.current;
    if (line.isBlankLine || _notTerm.hasMatch(line.content)) return false;
    final next = parser.peek(1);
    return next != null && _definition.hasMatch(next.content);
  }

  @override
  md.Node? parse(md.BlockParser parser) {
    final items = <Map<String, Object>>[];
    while (!parser.isDone) {
      final line = parser.current;
      final next = parser.peek(1);
      if (line.isBlankLine ||
          _notTerm.hasMatch(line.content) ||
          next == null ||
          !_definition.hasMatch(next.content)) {
        break;
      }
      final term = line.content.trim();
      parser.advance();
      final definitions = <String>[];
      while (!parser.isDone) {
        final match = _definition.firstMatch(parser.current.content);
        if (match != null) {
          definitions.add(match.group(1)!);
          parser.advance();
          continue;
        }
        final content = parser.current.content;
        if (definitions.isNotEmpty &&
            !parser.current.isBlankLine &&
            content.startsWith(RegExp(r'( {2,}|\t)'))) {
          definitions[definitions.length - 1] += '\n${content.trim()}';
          parser.advance();
          continue;
        }
        break;
      }
      items.add({'term': term, 'definitions': definitions});
      // A single blank line may separate entries of the same list.
      if (!parser.isDone && parser.current.isBlankLine) {
        final after = parser.peek(1);
        final afterNext = parser.peek(2);
        if (after != null &&
            afterNext != null &&
            !after.isBlankLine &&
            _definition.hasMatch(afterNext.content)) {
          parser.advance();
        }
      }
    }
    return md.Element('definition-list', [md.Text('')])
      ..attributes['json'] = jsonEncode(items);
  }
}

/* ──────────────────── Outline & relations ──────────────────── */

class NoteHeading {
  const NoteHeading({
    required this.level,
    required this.title,
    required this.offset,
  });

  final int level;
  final String title;

  /// Character offset in the original document.
  final int offset;
}

/// Extracts ATX headings outside fenced code and frontmatter.
List<NoteHeading> extractHeadings(String content) {
  final frontmatter = Frontmatter.parse(content);
  var offset = content.length - frontmatter.body.length;
  final headings = <NoteHeading>[];
  final pattern = RegExp(r'^\s{0,3}(#{1,6})[ \t]+(.+?)[ \t]*#*[ \t]*$');
  String? fence;
  for (final line in frontmatter.body.split('\n')) {
    final fenceMatch = _fencePattern.firstMatch(line);
    if (fenceMatch != null) {
      final marker = fenceMatch.group(1)![0];
      if (fence == null) {
        fence = marker;
      } else if (marker == fence) {
        fence = null;
      }
    } else if (fence == null) {
      final match = pattern.firstMatch(
        line.endsWith('\r') ? line.substring(0, line.length - 1) : line,
      );
      if (match != null &&
          !RegExp(
            r'^tags[ \t]*:',
            caseSensitive: false,
          ).hasMatch(match.group(2)!)) {
        headings.add(
          NoteHeading(
            level: match.group(1)!.length,
            title: _plainHeading(match.group(2)!),
            offset: offset,
          ),
        );
      }
    }
    offset += line.length + 1;
  }
  return headings;
}

String _plainHeading(String text) => text
    .replaceAllMapped(
      RegExp(r'\[\[([^\]|]*\|)?([^\]]*)\]\]'),
      (m) => m.group(2)!,
    )
    .replaceAll(RegExp(r'[*_`=]'), '')
    .replaceAll(RegExp(r'\s\^[A-Za-z0-9-]+$'), '')
    .trim();

/// Removes fenced code so tag and link scans ignore code samples.
String stripFencedCode(String content) {
  final output = <String>[];
  String? fence;
  for (final line in content.split('\n')) {
    final fenceMatch = _fencePattern.firstMatch(line);
    if (fenceMatch != null) {
      final marker = fenceMatch.group(1)![0];
      if (fence == null) {
        fence = marker;
      } else if (marker == fence) {
        fence = null;
      }
      continue;
    }
    if (fence == null) {
      output.add(
        line
            .replaceFirst(RegExp(r'\r$'), '')
            .replaceAll(RegExp(r'`[^`\n]*`'), ''),
      );
    }
  }
  return output.join('\n');
}
