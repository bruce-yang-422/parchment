/// Reading statistics for the document info sheet.
library;

import '../markdown/frontmatter.dart';
import '../markdown/note_syntax.dart';

enum LineEnding { none, lf, crlf, mixed }

class DocumentStats {
  const DocumentStats({
    required this.cjkCharacters,
    required this.latinWords,
    required this.characters,
    required this.charactersWithoutSpaces,
    required this.lines,
    required this.paragraphs,
    required this.lineEnding,
    this.headings = 0,
    this.wikiLinks = 0,
    this.markdownLinks = 0,
    this.externalLinks = 0,
    this.images = 0,
    this.codeBlocks = 0,
    this.diagrams = 0,
    this.footnotes = 0,
    this.tasks = 0,
    this.completedTasks = 0,
    this.properties = 0,
  });

  /// Chinese, Japanese and Korean characters (each counts as a word).
  final int cjkCharacters;

  /// Runs of Latin letters or digits.
  final int latinWords;
  final int characters;
  final int charactersWithoutSpaces;
  final int lines;
  final int paragraphs;
  final LineEnding lineEnding;

  final int headings;
  final int wikiLinks;
  final int markdownLinks;
  final int externalLinks;
  final int images;
  final int codeBlocks;
  final int diagrams;
  final int footnotes;
  final int tasks;
  final int completedTasks;
  final int properties;

  int get words => cjkCharacters + latinWords;

  static final _cjk = RegExp(r'[぀-ヿ㐀-䶿一-鿿가-힯豈-﫿]');
  static final _latinWord = RegExp(r"[A-Za-z0-9À-ɏ]+(?:['’][A-Za-z]+)*");

  static DocumentStats of(String content, {required bool markdown}) {
    final text = content.startsWith('﻿') ? content.substring(1) : content;
    final crlf = '\r\n'.allMatches(text).length;
    final lf = '\n'.allMatches(text).length - crlf;
    final ending = crlf == 0 && lf == 0
        ? LineEnding.none
        : crlf == 0
        ? LineEnding.lf
        : lf == 0
        ? LineEnding.crlf
        : LineEnding.mixed;
    final lines = text.isEmpty ? 0 : '\n'.allMatches(text).length + 1;

    final frontmatter = markdown ? Frontmatter.parse(text) : null;
    final body = frontmatter?.body ?? text;
    final prose = markdown ? stripFencedCode(body) : body;
    final countable = markdown ? _plainMarkdown(prose) : prose;
    final paragraphs = body
        .split(RegExp(r'\r?\n[ \t]*\r?\n'))
        .where((block) => block.trim().isNotEmpty)
        .length;

    final base = (
      cjk: _cjk.allMatches(countable).length,
      latin: _latinWord.allMatches(countable.replaceAll(_cjk, ' ')).length,
      chars: text.runes.length,
      nonSpace: text.replaceAll(RegExp(r'\s'), '').runes.length,
    );
    if (!markdown) {
      return DocumentStats(
        cjkCharacters: base.cjk,
        latinWords: base.latin,
        characters: base.chars,
        charactersWithoutSpaces: base.nonSpace,
        lines: lines,
        paragraphs: paragraphs,
        lineEnding: ending,
      );
    }

    final fences = RegExp(
      r'^\s{0,3}(?:`{3,}|~{3,})[ \t]*([\w-]*)',
      multiLine: true,
    ).allMatches(body).toList();
    var codeBlocks = 0;
    var diagrams = 0;
    for (var i = 0; i < fences.length; i += 2) {
      final language = fences[i].group(1)!.toLowerCase();
      if (const {'mermaid', 'dot', 'graphviz'}.contains(language)) {
        diagrams++;
      } else {
        codeBlocks++;
      }
    }
    final tasks = RegExp(
      r'^(?:[ \t]*>[ \t]?)*[ \t]*(?:[-*+]|\d{1,9}[.)])[ \t]+\[([ xX])\][ \t]',
      multiLine: true,
    ).allMatches(prose).toList();

    return DocumentStats(
      cjkCharacters: base.cjk,
      latinWords: base.latin,
      characters: base.chars,
      charactersWithoutSpaces: base.nonSpace,
      lines: lines,
      paragraphs: paragraphs,
      lineEnding: ending,
      headings: extractHeadings(text).length,
      wikiLinks: RegExp(r'(?<!!)\[\[[^\[\]\n]+\]\]').allMatches(prose).length,
      markdownLinks: RegExp(
        r'(?<!!)\[[^\]\n]*\]\((?!https?:|mailto:)[^)\s]+\)',
      ).allMatches(prose).length,
      externalLinks: RegExp(r'https?://[^\s)\]>]+').allMatches(prose).length,
      images:
          RegExp(r'!\[[^\]\n]*\]\([^)\s]+').allMatches(prose).length +
          RegExp(
            r'!\[\[[^\]\n]+\.(?:png|jpe?g|gif|webp|svg|bmp|avif)(?:\|[^\]]*)?\]\]',
            caseSensitive: false,
          ).allMatches(prose).length,
      codeBlocks: codeBlocks,
      diagrams: diagrams,
      footnotes: RegExp(
        r'^\s{0,3}\[\^[^\]]+\]:',
        multiLine: true,
      ).allMatches(prose).length,
      tasks: tasks.length,
      completedTasks: tasks.where((m) => m.group(1) != ' ').length,
      properties: frontmatter?.data?.length ?? 0,
    );
  }

  /// Drops Markdown syntax that should not count as words (URLs, link
  /// targets, HTML tags).
  static String _plainMarkdown(String text) => text
      .replaceAll(RegExp(r'\]\([^)]*\)'), ']')
      .replaceAll(RegExp(r'https?://\S+'), ' ')
      .replaceAll(RegExp(r'<[^>\n]+>'), ' ');
}
