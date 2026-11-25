import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:highlight/highlight.dart' show highlight, Node;
import 'package:markdown/markdown.dart' as md;

import '../../core/markdown/frontmatter.dart';
import '../../core/markdown/html_syntax.dart';
import '../../core/markdown/note_syntax.dart';
import '../../infrastructure/diagram_render_service.dart';
import '../theme/parchment_theme.dart';
import 'callout_styles.dart';
import 'diagram_view.dart';
import '../../core/l10n/tr.dart';

/// Resolves wiki links and embeds against the opened folder.
abstract interface class NoteResolver {
  /// Opens the note a wiki link points to (and scrolls to its heading).
  void openWiki(WikiTarget target);

  /// The embedded section's Markdown, or `null` when it cannot be found.
  Future<String?> loadEmbed(WikiTarget target);
}

/// URI handed to the image builder for `![[image.png|width]]` embeds.
Uri wikiImageUri(WikiTarget target) {
  final size = RegExp(r'^(\d+)(?:x(\d+))?$').firstMatch(target.alias);
  return Uri(
    scheme: 'parchment-wiki',
    path: 'image',
    queryParameters: {
      'target': target.target,
      if (size != null) 'width': size.group(1)!,
      if (size?.group(2) != null) 'height': size!.group(2)!,
    },
  );
}

/// Shared rendering configuration so nested Markdown (callouts, footnotes,
/// definition lists) uses exactly the same syntax, builders and styles.
class NoteMarkdownConfig {
  NoteMarkdownConfig({
    required this.note,
    required this.styleSheet,
    required this.onTapLink,
    required this.imageBuilder,
    required this.showMessage,
    this.resolver,
    this.onTagTap,
    required this.taskStates,
    this.codeLineNumbers = false,
  });

  final PreparedNote note;
  final MarkdownStyleSheet styleSheet;
  final MarkdownTapLinkCallback onTapLink;
  final MarkdownImageBuilder imageBuilder;
  final void Function(String message) showMessage;

  /// Folder-mode link resolution; `null` in single-file mode.
  final NoteResolver? resolver;

  /// Filters notes by a tag (folder mode only).
  final ValueChanged<String>? onTagTap;

  /// Task toggles keyed by task order. The file only changes when the user
  /// explicitly saves.
  final TaskStateStore taskStates;
  final bool codeLineNumbers;

  /// Task indexes waiting for their list item's checkbox. Inputs are visited
  /// before their `li` finishes, and nested items finish first, so a stack
  /// pairs every checkbox with its own task.
  final List<int> _pendingTasks = [];
  int _taskCount = 0;

  /// Checkboxes in the whole document. The config is kept across rebuilds,
  /// and the Markdown widget may parse the same document again (theme or
  /// dependency changes); numbering wraps here so every parse starts at 0.
  late final int _taskTotal = _countTasks(note.parse(note.markdown));

  static int _countTasks(Iterable<md.Node> nodes) {
    var count = 0;
    for (final node in nodes) {
      if (node is! md.Element) continue;
      if (node.tag == 'input' && node.attributes['type'] == 'checkbox') {
        count++;
      }
      count += _countTasks(node.children ?? const []);
    }
    return count;
  }

  int _nextTaskIndex() {
    final total = _taskTotal;
    final index = total == 0 ? _taskCount : _taskCount % total;
    _taskCount++;
    return index;
  }

  final Map<String, GlobalKey> _footnoteReferenceKeys = {};
  final GlobalKey _footnoteListKey = GlobalKey();
  ScrollController? _documentController;
  int _footnoteJump = 0;

  late final _footnoteBlocks = _indexFootnoteBlocks();

  ({int count, Map<String, int> references}) _indexFootnoteBlocks() {
    final references = <String, int>{};
    if (note.footnotes.isEmpty) return (count: 0, references: references);
    final blocks = note.parse(note.markdown);
    void index(md.Node node, int block) {
      if (node is! md.Element || node.attributes['class'] == 'footnotes') {
        return;
      }
      final id = node.attributes['id'];
      if (node.tag == 'a' && id != null && id.startsWith('fnref-')) {
        references.putIfAbsent(id, () => block);
      }
      for (final child in node.children ?? const <md.Node>[]) {
        index(child, block);
      }
    }

    for (var i = 0; i < blocks.length; i++) {
      index(blocks[i], i);
    }
    return (count: blocks.length, references: references);
  }

  GlobalKey footnoteReferenceKey(String id) =>
      _footnoteReferenceKeys.putIfAbsent(id, GlobalKey.new);

  Future<void> scrollToFootnoteReference(String id) async {
    final jump = ++_footnoteJump;
    final targetBlock = _footnoteBlocks.references[id];
    double? before;
    double? after;
    for (var attempt = 0; attempt < 40 && jump == _footnoteJump; attempt++) {
      final reference = _footnoteReferenceKeys[id]?.currentContext;
      if (reference != null &&
          reference.mounted &&
          reference.findRenderObject()?.attached == true) {
        await Scrollable.ensureVisible(
          reference,
          alignment: 0.24,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
        return;
      }
      final list = _footnoteListKey.currentContext?.findRenderObject();
      final position = _documentController?.positions.lastOrNull;
      if (targetBlock == null ||
          list is! RenderSliverList ||
          position == null) {
        return;
      }
      final first = list.firstChild;
      final last = list.lastChild;
      if (first == null || last == null) return;
      // The Markdown renderer inserts a spacing child between blocks.
      final target = targetBlock * 2;
      final firstIndex = list.indexOf(first);
      final lastIndex = list.indexOf(last);
      if (target >= firstIndex && target <= lastIndex) return;

      // Estimate the distance using the blocks that are laid out. If a
      // variable-height block makes us overshoot, narrow the search range.
      final forward = target > lastIndex;
      final pixels = position.pixels;
      if (forward) {
        before = pixels;
      } else {
        after = pixels;
      }
      final nearest = forward ? lastIndex : firstIndex;
      final laidOutExtent =
          list.childScrollOffset(last)! -
          list.childScrollOffset(first)! +
          last.size.height;
      final estimate =
          (target - nearest).abs() *
          laidOutExtent /
          (lastIndex - firstIndex + 1);
      final step = math.max(estimate, position.viewportDimension * 0.5);
      var next = pixels + (forward ? step : -step);
      if (before != null &&
          after != null &&
          (next <= before || next >= after)) {
        next = (before + after) / 2;
      }
      next = next.clamp(position.minScrollExtent, position.maxScrollExtent);
      if ((next - pixels).abs() < 0.5) return;
      position.jumpTo(next);
      await WidgetsBinding.instance.endOfFrame;
    }
  }

  late final Map<String, MarkdownElementBuilder> _documentBuilders = {
    ...builders,
    'input': _TaskInputBuilder(this),
  };

  Widget _taskCheckbox(bool checked) {
    if (_pendingTasks.isEmpty) return _StaticTaskBox(checked: checked);
    final index = _pendingTasks.removeLast();
    taskStates.register(index, checked);
    return TaskCheckbox(
      key: ValueKey('task-$index'),
      store: taskStates,
      index: index,
    );
  }

  late final Map<String, MarkdownElementBuilder> builders = {
    'pre': _CodeBlockBuilder(),
    'callout': _CalloutBuilder(),
    'math-block': _MathBlockBuilder(),
    'definition-list': _DefinitionListBuilder(),
    'properties': _TagsPropertyBuilder(),
    'math-inline': _InlineMathBuilder(),
    'mark': _InlineStyleBuilder(_InlineStyle.mark),
    'ins': _InlineStyleBuilder(_InlineStyle.ins),
    'sup-text': _InlineStyleBuilder(_InlineStyle.sup),
    'sub-text': _InlineStyleBuilder(_InlineStyle.sub),
    'sup': _FootnoteReferenceBuilder(this),
    'section': _FootnoteSectionBuilder(this),
    'abbr': _AbbreviationBuilder(),
    'wikilink': _WikiLinkBuilder(),
    'wiki-embed': _WikiEmbedBuilder(),
    'kbd': _KbdBuilder(),
    'hr': _RuleBuilder(),
    'html-img': _HtmlImageBuilder(),
    'html-details': _HtmlDetailsBuilder(),
    'html-block': _HtmlBlockBuilder(),
  };

  /// Non-scrolling Markdown for nested content.
  Widget body(String data) {
    return MarkdownBody(
      data: data,
      styleSheet: styleSheet,
      builders: builders,
      extensionSet: note.extensionSet,
      blockSyntaxes: note.blockSyntaxes,
      inlineSyntaxes: note.inlineSyntaxes,
      onTapLink: onTapLink,
      imageBuilder: imageBuilder,
      checkboxBuilder: (checked) => _StaticTaskBox(checked: checked),
    );
  }

  /// Scrolling Markdown for the whole document.
  Widget document({
    required ScrollController controller,
    required EdgeInsets padding,
  }) {
    _documentController = controller;
    return _FootnoteMarkdown(
      config: this,
      controller: controller,
      padding: padding,
    );
  }
}

class _FootnoteMarkdown extends Markdown {
  _FootnoteMarkdown({
    required this.config,
    required super.controller,
    required super.padding,
  }) : super(
         data: config.note.markdown,
         styleSheet: config.styleSheet,
         builders: config._documentBuilders,
         extensionSet: config.note.extensionSet,
         blockSyntaxes: config.note.blockSyntaxes,
         inlineSyntaxes: config.note.inlineSyntaxes,
         onTapLink: config.onTapLink,
         imageBuilder: config.imageBuilder,
         checkboxBuilder: config._taskCheckbox,
       );

  final NoteMarkdownConfig config;

  @override
  Widget build(BuildContext context, List<Widget>? children) {
    final indexed = config._footnoteBlocks;
    if (children == null ||
        indexed.references.isEmpty ||
        children.length != indexed.count * 2 - 1) {
      return super.build(context, children);
    }
    return CustomScrollView(
      controller: controller,
      semanticChildCount: children.length,
      slivers: [
        SliverPadding(
          padding: padding,
          sliver: SliverList.list(
            key: config._footnoteListKey,
            children: children,
          ),
        ),
      ],
    );
  }
}

class NoteMarkdownScope extends InheritedWidget {
  const NoteMarkdownScope({
    required this.config,
    required super.child,
    super.key,
  });

  final NoteMarkdownConfig config;

  static NoteMarkdownConfig of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<NoteMarkdownScope>();
    assert(scope != null, 'NoteMarkdownScope is missing');
    return scope!.config;
  }

  @override
  bool updateShouldNotify(NoteMarkdownScope oldWidget) =>
      oldWidget.config != config;
}

/* ──────────────────── Block builders ──────────────────── */

class _CodeBlockBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    md.Element? code;
    for (final child in element.children ?? const <md.Node>[]) {
      if (child is md.Element && child.tag == 'code') {
        code = child;
        break;
      }
    }
    final rawSource = (code ?? element).textContent;
    final source = rawSource.endsWith('\n')
        ? rawSource.substring(0, rawSource.length - 1)
        : rawSource;
    final language = (code?.attributes['class'] ?? '')
        .split(' ')
        .firstWhere((name) => name.startsWith('language-'), orElse: () => '')
        .replaceFirst('language-', '')
        .toLowerCase();
    final dark = Theme.of(context).brightness == Brightness.dark;
    return switch (language) {
      'mermaid' => DiagramView(
        kind: DiagramKind.mermaid,
        source: source.trim(),
        dark: dark,
      ),
      'dot' || 'graphviz' => DiagramView(
        kind: DiagramKind.graphviz,
        source: source.trim(),
        dark: dark,
      ),
      propertiesFenceLanguage => PropertiesView(
        properties: parseYamlSubset(source),
      ),
      _ => CodeBlockView(
        source: source,
        language: language,
        showLineNumbers: NoteMarkdownScope.of(context).codeLineNumbers,
      ),
    };
  }
}

class _CalloutBuilder extends MarkdownElementBuilder {
  @override
  bool isBlockElement() => true;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    return CalloutView(
      type: element.attributes['type'] ?? 'note',
      fold: element.attributes['fold'] ?? '',
      title: element.attributes['title'] ?? '',
      body: element.attributes['body'] ?? '',
    );
  }
}

class _MathBlockBuilder extends MarkdownElementBuilder {
  @override
  bool isBlockElement() => true;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final tex = element.attributes['tex'] ?? '';
    final style = NoteMarkdownScope.of(context).styleSheet.p;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Center(
              child: Math.tex(
                tex,
                mathStyle: MathStyle.display,
                textStyle: style?.copyWith(height: 1),
                onErrorFallback: (error) => _MathError(tex: tex),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DefinitionListBuilder extends MarkdownElementBuilder {
  @override
  bool isBlockElement() => true;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final config = NoteMarkdownScope.of(context);
    final colors = Theme.of(context).colorScheme;
    final items = (jsonDecode(element.attributes['json'] ?? '[]') as List)
        .cast<Map<String, dynamic>>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in items) ...[
          config.body('**${item['term']}**'),
          for (final definition in (item['definitions'] as List).cast<String>())
            Container(
              margin: const EdgeInsets.only(left: 4, top: 2, bottom: 6),
              padding: const EdgeInsets.only(left: 14),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: colors.outlineVariant, width: 3),
                ),
              ),
              child: config.body(definition),
            ),
        ],
      ],
    );
  }
}

class _TagsPropertyBuilder extends MarkdownElementBuilder {
  @override
  bool isBlockElement() => true;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final data = jsonDecode(element.attributes['json'] ?? '{}');
    return PropertiesView(
      properties: (data as Map).cast<String, Object?>(),
      showHeader: false,
    );
  }
}

/* ──────────────────── Inline builders ──────────────────── */

class _TaskInputBuilder extends MarkdownElementBuilder {
  _TaskInputBuilder(this.config);

  final NoteMarkdownConfig config;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    if (element.attributes['type'] == 'checkbox') {
      config._pendingTasks.add(config._nextTaskIndex());
    }
    return null;
  }
}

enum _InlineStyle { mark, ins, sup, sub }

/// The footnotes at the end of a document, drawn by the app: number,
/// content and a drawn "back to text" button. The markdown package's own
/// back link is the character ↩, which Android shows as a colour emoji.
class _FootnoteSectionBuilder extends MarkdownElementBuilder {
  _FootnoteSectionBuilder(this.config);

  final NoteMarkdownConfig config;

  @override
  bool isBlockElement() => true;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    if (element.attributes['class'] != 'footnotes') return null;
    final items = <md.Element>[];
    void collect(md.Node node) {
      if (node is! md.Element) return;
      if (node.tag == 'li') {
        items.add(node);
        return;
      }
      node.children?.forEach(collect);
    }

    element.children?.forEach(collect);
    final look = ReaderLook.of(context);
    final numberStyle = config.styleSheet.p?.copyWith(
      color: look.muted,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(height: 32, color: look.border),
        for (var index = 0; index < items.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 28,
                  child: Text('${index + 1}.', style: numberStyle),
                ),
                // The back button follows the text instead of sitting at
                // the right edge; the body shrinks to its content.
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(child: config.body(_content(items[index]))),
                      for (final href in _backLinks(items[index]))
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 2),
                          child: FootnoteBackButton(
                            onTap: () => config.onTapLink('', href, ''),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Markdown of one footnote, from the note's own definitions (`fn-<label>`).
  String _content(md.Element item) {
    final id = item.attributes['id'] ?? '';
    final label = id.startsWith('fn-') ? id.substring(3) : id;
    return config.note.footnoteFor(label) ?? item.textContent;
  }

  static List<String> _backLinks(md.Element item) {
    final hrefs = <String>[];
    void visit(md.Node node) {
      if (node is! md.Element) return;
      final href = node.attributes['href'];
      if (node.tag == 'a' &&
          node.attributes['class'] == 'footnote-backref' &&
          href != null) {
        hrefs.add(href);
        return;
      }
      node.children?.forEach(visit);
    }

    item.children?.forEach(visit);
    return hrefs;
  }
}

/// Round "back to text" button: a drawn arrow that curves down and left,
/// in the same capsule as the footnote numbers in the text.
class FootnoteBackButton extends StatelessWidget {
  const FootnoteBackButton({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Tooltip(
      message: tr('回到正文'),
      child: Semantics(
        button: true,
        label: tr('回到正文'),
        excludeSemantics: true,
        child: Material(
          color: colors.primaryContainer.withValues(alpha: 0.72),
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox.square(
              dimension: 20,
              child: CustomPaint(
                painter: _BackArrowPainter(colors.onPrimaryContainer),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackArrowPainter extends CustomPainter {
  const _BackArrowPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.085
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    // Match the web footnote's return arrow (↩).
    final stem = Path()
      ..moveTo(s * 0.64, s * 0.27)
      ..cubicTo(s * 0.84, s * 0.32, s * 0.83, s * 0.63, s * 0.57, s * 0.63)
      ..lineTo(s * 0.24, s * 0.63);
    final head = Path()
      ..moveTo(s * 0.37, s * 0.50)
      ..lineTo(s * 0.24, s * 0.63)
      ..lineTo(s * 0.37, s * 0.76);
    canvas
      ..drawPath(stem, paint)
      ..drawPath(head, paint);
  }

  @override
  bool shouldRepaint(_BackArrowPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _FootnoteReferenceBuilder extends MarkdownElementBuilder {
  _FootnoteReferenceBuilder(this.config);

  final NoteMarkdownConfig config;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final children = element.children;
    if (element.attributes['class'] != 'footnote-ref' ||
        children == null ||
        children.isEmpty ||
        children.first is! md.Element) {
      return null;
    }
    final link = children.first as md.Element;
    final href = link.attributes['href'];
    if (href == null || !href.startsWith('#fn-')) return null;
    final number = link.textContent;
    final referenceId = link.attributes['id'] ?? 'fnref-${href.substring(4)}';
    final colors = Theme.of(context).colorScheme;
    final base = parentStyle ?? DefaultTextStyle.of(context).style;
    final visualSize = math.max(12.0, (base.fontSize ?? 16) * 0.78);
    return Text.rich(
      WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: Transform.translate(
          key: config.footnoteReferenceKey(referenceId),
          offset: Offset(0, -visualSize * 0.24),
          child: Semantics(
            button: true,
            label: tr('註腳 {number}', {'number': number}),
            child: Material(
              color: colors.primaryContainer.withValues(alpha: 0.72),
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => config.onTapLink(number, href, ''),
                child: SizedBox.square(
                  key: ValueKey('footnote-reference-$referenceId'),
                  dimension: 26,
                  child: Center(
                    child: Text(
                      number,
                      style: base.copyWith(
                        color: colors.onPrimaryContainer,
                        fontSize: visualSize,
                        height: 1,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineStyleBuilder extends MarkdownElementBuilder {
  _InlineStyleBuilder(this.style);

  final _InlineStyle style;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final base = parentStyle ?? DefaultTextStyle.of(context).style;
    final text = element.textContent;
    return Text.rich(switch (style) {
      _InlineStyle.mark => TextSpan(
        text: text,
        style: base.copyWith(backgroundColor: ReaderLook.of(context).mark),
      ),
      _InlineStyle.ins => TextSpan(
        text: text,
        style: base.copyWith(
          decoration: TextDecoration.underline,
          decorationThickness: 1.5,
        ),
      ),
      _InlineStyle.sup || _InlineStyle.sub => _shiftedSpan(
        text,
        base,
        raise: style == _InlineStyle.sup,
      ),
    });
  }

  static InlineSpan _shiftedSpan(
    String text,
    TextStyle base, {
    required bool raise,
  }) {
    final fontSize = base.fontSize ?? 16;
    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: Transform.translate(
        offset: Offset(0, raise ? -fontSize * 0.4 : fontSize * 0.22),
        child: Text(
          text,
          style: base.copyWith(fontSize: fontSize * 0.72, height: 1),
        ),
      ),
    );
  }
}

class _InlineMathBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final tex = element.textContent;
    final base = parentStyle ?? DefaultTextStyle.of(context).style;
    return Text.rich(
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Math.tex(
          tex,
          mathStyle: MathStyle.text,
          textStyle: base.copyWith(height: 1),
          onErrorFallback: (error) =>
              Text('\$$tex\$', style: base.copyWith(fontFamily: 'monospace')),
        ),
      ),
    );
  }
}

class _AbbreviationBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final base = parentStyle ?? DefaultTextStyle.of(context).style;
    final title = element.attributes['title'] ?? '';
    return Text.rich(
      WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: Tooltip(
          message: title,
          triggerMode: TooltipTriggerMode.tap,
          showDuration: const Duration(seconds: 4),
          child: Text(
            element.textContent,
            style: base.copyWith(
              decoration: TextDecoration.underline,
              decorationStyle: TextDecorationStyle.dotted,
            ),
          ),
        ),
      ),
    );
  }
}

class _WikiLinkBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final config = NoteMarkdownScope.of(context);
    final base = parentStyle ?? DefaultTextStyle.of(context).style;
    final target = WikiTarget.parse(element.attributes['raw'] ?? '');
    final colors = Theme.of(context).colorScheme;
    return Text.rich(
      TextSpan(
        text: element.textContent,
        style: base.copyWith(
          color: colors.primary,
          decoration: TextDecoration.underline,
          decorationColor: colors.primary.withValues(alpha: 0.4),
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            final resolver = config.resolver;
            if (resolver != null) {
              resolver.openWiki(target);
            } else {
              config.showMessage(
                tr('「{name}」在其他筆記裡，要先開啟整個筆記資料夾才能跳過去', {
                  'name': target.name.isEmpty
                      ? target.displayText
                      : target.name,
                }),
              );
            }
          },
      ),
    );
  }
}

class _WikiEmbedBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final target = WikiTarget.parse(element.attributes['raw'] ?? '');
    final config = NoteMarkdownScope.of(context);
    if (config.resolver == null) return _EmbedPlaceholder(target: target);
    if (target.isImage) {
      return config.imageBuilder(
        wikiImageUri(target),
        null,
        target.target.split('/').last,
      );
    }
    return _NoteEmbed(target: target);
  }
}

/* ──────────────────── HTML ──────────────────── */

/// Horizontal rule; parchment draws a `❦` ornament.
class _RuleBuilder extends MarkdownElementBuilder {
  @override
  bool isBlockElement() => true;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final look = ReaderLook.of(context);
    final line = Expanded(child: Divider(color: look.border, thickness: 1));
    if (!look.chrome.ornamentRule) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [line]),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          line,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '❦',
              style: TextStyle(fontSize: 20, color: look.quoteBorder),
            ),
          ),
          line,
        ],
      ),
    );
  }
}

/// `<kbd>Ctrl</kbd>`: a small key cap.
class _KbdBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final base = parentStyle ?? DefaultTextStyle.of(context).style;
    final colors = Theme.of(context).colorScheme;
    final fontSize = (base.fontSize ?? 16) * 0.82;
    return Text.rich(
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 1),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: colors.outlineVariant),
            boxShadow: [
              BoxShadow(color: colors.outline, offset: const Offset(0, 1.5)),
            ],
          ),
          child: Text(
            element.textContent,
            style: base.copyWith(
              fontFamily: 'monospace',
              fontSize: fontSize,
              height: 1.3,
              color: colors.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

/// `<img src="…" width="200">`, shown like a Markdown image.
class _HtmlImageBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final config = NoteMarkdownScope.of(context);
    final uri = Uri.tryParse(element.attributes['src'] ?? '');
    if (uri == null) return const SizedBox.shrink();
    final image = config.imageBuilder(
      uri,
      element.attributes['title'],
      element.attributes['alt'],
    );
    double? size(String name) => double.tryParse(
      (element.attributes[name] ?? '').replaceFirst(RegExp(r'px$'), ''),
    );
    final width = size('width');
    final height = size('height');
    if (width == null && height == null) return image;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: width ?? double.infinity,
        maxHeight: height ?? double.infinity,
      ),
      child: image,
    );
  }
}

/// `<details><summary>…</summary>…</details>`: a fold-out section.
class _HtmlDetailsBuilder extends MarkdownElementBuilder {
  @override
  bool isBlockElement() => true;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    return HtmlDetailsView(
      summary: element.attributes['summary'] ?? '',
      body: element.attributes['body'] ?? '',
      initiallyOpen: element.attributes['open'] == 'true',
    );
  }
}

/// Wrapper HTML (`<div>`, `<p align="center">` …) shown as its content.
class _HtmlBlockBuilder extends MarkdownElementBuilder {
  @override
  bool isBlockElement() => true;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final config = NoteMarkdownScope.of(context);
    final markdown = element.attributes['markdown'] ?? '';
    if (element.attributes['center'] == 'true') {
      final images = _centeredImages(config, markdown);
      if (images != null) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: images,
          ),
        );
      }
    }
    final body = config.body(markdown);
    if (element.attributes['center'] != 'true') return body;
    return Align(
      child: DefaultTextStyle.merge(textAlign: TextAlign.center, child: body),
    );
  }

  /// GitHub-style README headers commonly use a centered `<p>` containing
  /// one logo or several linked badge images. Rendering that HTML through a
  /// nested Markdown list turns every image into a separate full-width row.
  /// Keep an image-only wrapper as one compact, centered wrapping group.
  static List<Widget>? _centeredImages(
    NoteMarkdownConfig config,
    String markdown,
  ) {
    final matches = RegExp(
      r'<img\b([^<>]*)>',
      caseSensitive: false,
    ).allMatches(markdown).toList();
    if (matches.isEmpty) return null;
    final remainder = markdown
        .replaceAll(RegExp(r'<img\b[^<>]*>', caseSensitive: false), '')
        .replaceAll(RegExp(r'</?a\b[^<>]*>', caseSensitive: false), '')
        .trim();
    if (remainder.isNotEmpty) return null;
    final widgets = <Widget>[];
    for (final match in matches) {
      final attributes = parseHtmlAttributes(match.group(1)!);
      final uri = Uri.tryParse(attributes['src'] ?? '');
      if (uri == null) continue;
      widgets.add(
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth:
                double.tryParse(attributes['width'] ?? '') ?? double.infinity,
            maxHeight:
                double.tryParse(attributes['height'] ?? '') ?? double.infinity,
          ),
          child: config.imageBuilder(
            uri,
            attributes['title'],
            attributes['alt'],
          ),
        ),
      );
    }
    return widgets.isEmpty ? null : widgets;
  }
}

class HtmlDetailsView extends StatefulWidget {
  const HtmlDetailsView({
    required this.summary,
    required this.body,
    required this.initiallyOpen,
    super.key,
  });

  final String summary;
  final String body;
  final bool initiallyOpen;

  @override
  State<HtmlDetailsView> createState() => _HtmlDetailsViewState();
}

class _HtmlDetailsViewState extends State<HtmlDetailsView> {
  late bool _open = widget.initiallyOpen;

  @override
  Widget build(BuildContext context) {
    final config = NoteMarkdownScope.of(context);
    final colors = Theme.of(context).colorScheme;
    final summary = widget.summary.isEmpty ? tr('詳細內容') : widget.summary;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: ReaderLook.of(context).cardBackground,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(ReaderLook.of(context).radius + 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: _open,
            child: InkWell(
              onTap: () => setState(() => _open = !_open),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
                child: Row(
                  children: [
                    AnimatedRotation(
                      turns: _open ? 0.25 : 0,
                      duration: const Duration(milliseconds: 150),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(child: config.body(summary)),
                  ],
                ),
              ),
            ),
          ),
          if (_open && widget.body.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: config.body(widget.body),
            ),
        ],
      ),
    );
  }
}

/* ──────────────────── Widgets ──────────────────── */

/// Source state of every task plus the user's unsaved toggles.
class TaskStateStore extends ChangeNotifier {
  final Map<int, bool> _source = {};
  final Map<int, bool> _overrides = {};

  /// Number of interactive tasks found in the rendered document.
  int get taskCount => _source.length;

  /// Tasks whose state differs from the file, as task index → checked.
  Map<int, bool> get changes => {
    for (final entry in _overrides.entries)
      if (_source[entry.key] != entry.value) entry.key: entry.value,
  };

  bool get hasChanges => changes.isNotEmpty;

  void register(int index, bool checked) => _source[index] = checked;

  bool valueOf(int index) => _overrides[index] ?? _source[index] ?? false;

  void set(int index, bool checked) {
    if (valueOf(index) == checked) return;
    _overrides[index] = checked;
    notifyListeners();
  }

  /// Drops unsaved toggles so every checkbox shows the file again.
  void discard() {
    if (_overrides.isEmpty) return;
    _overrides.clear();
    notifyListeners();
  }
}

class TaskCheckbox extends StatelessWidget {
  const TaskCheckbox({required this.store, required this.index, super.key});

  final TaskStateStore store;
  final int index;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final value = store.valueOf(index);
        return ThemedCheckBox(
          checked: value,
          onChanged: () => store.set(index, !value),
        );
      },
    );
  }
}

class _StaticTaskBox extends StatelessWidget {
  const _StaticTaskBox({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) => ThemedCheckBox(checked: checked);
}

/// Task checkbox drawn in the palette's style: a square, a rounded square
/// or an iOS-style circle.
class ThemedCheckBox extends StatelessWidget {
  const ThemedCheckBox({required this.checked, this.onChanged, super.key});

  final bool checked;

  /// `null` for read-only boxes (embeds, callouts).
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final look = ReaderLook.of(context);
    final chrome = look.chrome;
    final fill = chrome.checkedColor ?? look.primary;
    const size = 18.0;
    final shape = switch (chrome.check) {
      CheckLook.circle => const CircleBorder(),
      CheckLook.rounded => RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      CheckLook.square => RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(2),
      ),
    };
    final onFill = fill.computeLuminance() > 0.45
        ? const Color(0xFF111111)
        : Colors.white;
    final box = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: size,
      height: size,
      decoration: ShapeDecoration(
        color: checked ? fill : null,
        shape: shape.copyWith(
          side: BorderSide(
            color: checked ? fill : look.muted,
            width: chrome.check == CheckLook.circle ? 1.6 : 1.4,
          ),
        ),
      ),
      child: checked
          ? Icon(Icons.check_rounded, size: size - 4, color: onFill)
          : null,
    );
    return Semantics(
      checked: checked,
      enabled: onChanged != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onChanged,
        child: SizedBox(width: 28, height: 28, child: Center(child: box)),
      ),
    );
  }
}

/// Limits nested embeds so notes that embed each other cannot recurse.
class _EmbedDepth extends InheritedWidget {
  const _EmbedDepth({required this.depth, required super.child});

  final int depth;

  static int of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_EmbedDepth>()?.depth ?? 0;

  @override
  bool updateShouldNotify(_EmbedDepth oldWidget) => oldWidget.depth != depth;
}

class _NoteEmbed extends StatefulWidget {
  const _NoteEmbed({required this.target});

  static const maxDepth = 2;

  final WikiTarget target;

  @override
  State<_NoteEmbed> createState() => _NoteEmbedState();
}

class _NoteEmbedState extends State<_NoteEmbed> {
  Future<String?>? _section;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _section ??= NoteMarkdownScope.of(
      context,
    ).resolver!.loadEmbed(widget.target);
  }

  @override
  Widget build(BuildContext context) {
    final config = NoteMarkdownScope.of(context);
    final depth = _EmbedDepth.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: colors.primary, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => config.resolver!.openWiki(widget.target),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 4),
              child: Row(
                children: [
                  Icon(Icons.article_outlined, size: 18, color: colors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.target.displayText,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colors.primary,
                      ),
                    ),
                  ),
                  Icon(Icons.open_in_new, size: 16, color: colors.primary),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: depth >= _NoteEmbed.maxDepth
                ? Text(
                    tr('這裡引用的內容太多層，點上方標題直接開啟那份筆記'),
                    style: TextStyle(color: colors.onSurfaceVariant),
                  )
                : FutureBuilder<String?>(
                    future: _section,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Padding(
                          padding: EdgeInsets.all(8),
                          child: LinearProgressIndicator(),
                        );
                      }
                      final section = snapshot.data;
                      if (section == null) {
                        return Text(
                          snapshot.hasError
                              ? tr('無法讀取引用的內容')
                              : tr('找不到「{name}」', {
                                  'name': widget.target.displayText,
                                }),
                          style: TextStyle(color: colors.error),
                        );
                      }
                      return _EmbedDepth(
                        depth: depth + 1,
                        child: config.body(section),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmbedPlaceholder extends StatelessWidget {
  const _EmbedPlaceholder({required this.target});

  final WikiTarget target;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final image = target.isImage;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: colors.primary, width: 3)),
      ),
      child: Row(
        children: [
          Icon(
            image ? Icons.image_outlined : Icons.article_outlined,
            color: colors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  image ? target.target.split('/').last : target.displayText,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  image
                      ? tr('缺圖：無法存取相對路徑圖片，或圖片不存在')
                      : tr('這裡引用了另一份筆記，開啟整個筆記資料夾後才會顯示'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MathError extends StatelessWidget {
  const _MathError({required this.tex});

  final String tex;

  @override
  Widget build(BuildContext context) {
    return Text(
      tex,
      style: TextStyle(
        fontFamily: 'monospace',
        color: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

/* ──────────────────── Callouts ──────────────────── */

const _calloutAliases = {
  'summary': 'abstract',
  'tldr': 'abstract',
  'hint': 'tip',
  'important': 'tip',
  'check': 'success',
  'done': 'success',
  'help': 'question',
  'faq': 'question',
  'caution': 'warning',
  'attention': 'warning',
  'fail': 'failure',
  'missing': 'failure',
  'error': 'danger',
  'cite': 'quote',
};

class CalloutView extends StatefulWidget {
  const CalloutView({
    required this.type,
    required this.fold,
    required this.title,
    required this.body,
    super.key,
  });

  final String type;

  /// `-` collapsed by default, `+` expanded but collapsible, empty = static.
  final String fold;
  final String title;
  final String body;

  @override
  State<CalloutView> createState() => _CalloutViewState();
}

class _CalloutViewState extends State<CalloutView> {
  late bool _expanded = widget.fold != '-';

  String get _category {
    final type = _calloutAliases[widget.type] ?? widget.type;
    return calloutCategories.contains(type) ? type : 'note';
  }

  String get _title {
    if (widget.title.isNotEmpty) {
      return widget.title.replaceAll(RegExp(r'[*_`]'), '');
    }
    final type = widget.type;
    return type.isEmpty ? 'Note' : type[0].toUpperCase() + type.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final config = NoteMarkdownScope.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final collapsible = widget.fold.isNotEmpty;
    final look = ReaderLook.of(context);
    final style = look.chrome.callout;
    final visual = calloutVisual(style, _category, dark);
    final accent = visual.accent;
    // Notion and Windows 11 write the title in the text colour.
    final titleColor =
        style == CalloutLook.plain || style == CalloutLook.infoBar
        ? look.text
        : accent;
    final titleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
      color: titleColor,
      fontFamily: look.chrome.headingFamily,
      fontWeight: style == CalloutLook.inset
          ? FontWeight.w600
          : FontWeight.w700,
    );

    final iconWidget = visual.emoji != null
        ? Text(visual.emoji!, style: const TextStyle(fontSize: 18, height: 1.2))
        : Icon(visual.icon, size: 20, color: accent);

    final header = Row(
      children: [
        iconWidget,
        SizedBox(width: style == CalloutLook.plain ? 10 : 8),
        Expanded(child: Text(_title, style: titleStyle)),
        if (collapsible)
          AnimatedRotation(
            turns: _expanded ? 0.25 : 0,
            duration: const Duration(milliseconds: 150),
            child: Icon(Icons.chevron_right, size: 20, color: titleColor),
          ),
      ],
    );

    final tint = accent.withValues(alpha: dark ? 0.16 : 0.09);
    final (radius, decoration) = switch (style) {
      CalloutLook.edge => (
        BorderRadius.circular(look.radius),
        BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(look.radius),
          border: Border(left: BorderSide(color: accent, width: 3)),
        ),
      ),
      CalloutLook.soft => (
        BorderRadius.circular(4),
        BoxDecoration(
          color: accent.withValues(alpha: dark ? 0.14 : 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      CalloutLook.plain => (
        BorderRadius.circular(4),
        BoxDecoration(
          color: visual.background,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      CalloutLook.infoBar => (
        BorderRadius.circular(8),
        BoxDecoration(
          color: visual.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: look.border),
        ),
      ),
      CalloutLook.inset => (
        BorderRadius.circular(14),
        BoxDecoration(
          color: accent.withValues(alpha: dark ? 0.18 : 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    };
    final pad = style == CalloutLook.inset ? 14.0 : 12.0;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: decoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (collapsible)
            InkWell(
              borderRadius: radius,
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: EdgeInsets.fromLTRB(pad, 10, pad, 10),
                child: header,
              ),
            )
          else
            Padding(
              padding: EdgeInsets.fromLTRB(pad, 10, pad, 4),
              child: header,
            ),
          if (_expanded && widget.body.trim().isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(pad, collapsible ? 0 : 2, pad, 10),
              child: config.body(widget.body),
            ),
        ],
      ),
    );
  }
}

/* ──────────────────── Properties ──────────────────── */

class PropertiesView extends StatelessWidget {
  const PropertiesView({
    required this.properties,
    this.showHeader = true,
    super.key,
  });

  final Map<String, Object?> properties;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showHeader)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(Icons.tune, size: 18, color: colors.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    tr('文件資料'),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          for (final entry in properties.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 96,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        entry.key,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PropertyValue(name: entry.key, value: entry.value),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TapTarget extends StatelessWidget {
  const _TapTarget({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (onTap == null) return child;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: child,
    );
  }
}

class _PropertyValue extends StatelessWidget {
  const _PropertyValue({required this.name, required this.value});

  final String name;
  final Object? value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isTags = const {'tags', 'tag', 'Tags'}.contains(name);
    final value = this.value;
    if (value is List || isTags) {
      final items = value is List
          ? value
                .map((item) => '${item ?? ''}')
                .where((item) => item.isNotEmpty)
          : '${value ?? ''}'
                .split(RegExp(r'[,，\s]+'))
                .where((item) => item.isNotEmpty);
      final onTagTap = isTags
          ? context
                .dependOnInheritedWidgetOfExactType<NoteMarkdownScope>()
                ?.config
                .onTagTap
          : null;
      return Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final item in items)
            _TapTarget(
              onTap: onTagTap == null
                  ? null
                  : () => onTagTap(item.replaceFirst('#', '')),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: isTags
                      ? colors.primaryContainer
                      : colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isTags ? '#${item.replaceFirst('#', '')}' : item,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isTags
                        ? colors.onPrimaryContainer
                        : colors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      );
    }
    if (value is bool) {
      return Row(
        children: [
          Icon(
            value ? Icons.check_box : Icons.check_box_outline_blank,
            size: 20,
            color: value ? colors.primary : colors.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(value ? 'true' : 'false', style: theme.textTheme.bodyMedium),
        ],
      );
    }
    return Text(
      value == null || '$value'.isEmpty ? '—' : '$value',
      style: theme.textTheme.bodyMedium,
    );
  }
}

/* ──────────────────── Code blocks ──────────────────── */

class _OverflowCodeScroller extends StatefulWidget {
  const _OverflowCodeScroller({required this.padding, required this.child});

  final EdgeInsets padding;
  final Widget child;

  @override
  State<_OverflowCodeScroller> createState() => _OverflowCodeScrollerState();
}

class _OverflowCodeScrollerState extends State<_OverflowCodeScroller> {
  final ScrollController _controller = ScrollController();
  bool _overflow = false;
  bool _updateScheduled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _onMetrics(ScrollMetricsNotification notification) {
    if (notification.metrics.axis != Axis.horizontal) return false;
    if (_updateScheduled) return false;
    _updateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateScheduled = false;
      final next =
          _controller.hasClients && _controller.position.maxScrollExtent > 0.5;
      if (mounted && next != _overflow) setState(() => _overflow = next);
    });
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: _onMetrics,
      child: RawScrollbar(
        key: const ValueKey('code-horizontal-scrollbar'),
        controller: _controller,
        thumbVisibility: _overflow,
        trackVisibility: _overflow,
        interactive: true,
        scrollbarOrientation: ScrollbarOrientation.bottom,
        thickness: 4,
        radius: const Radius.circular(99),
        thumbColor: colors.onSurfaceVariant.withValues(alpha: 0.65),
        trackColor: colors.onSurfaceVariant.withValues(alpha: 0.12),
        child: SingleChildScrollView(
          controller: _controller,
          scrollDirection: Axis.horizontal,
          padding: widget.padding,
          child: widget.child,
        ),
      ),
    );
  }
}

class CodeBlockView extends StatelessWidget {
  const CodeBlockView({
    required this.source,
    required this.language,
    this.showLineNumbers = false,
    super.key,
  });

  final String source;
  final String language;
  final bool showLineNumbers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final look = ReaderLook.of(context);
    final style = look.chrome.code;
    final codeStyle = TextStyle(
      fontFamily: 'monospace',
      fontFamilyFallback: const ['Menlo', 'Roboto Mono', 'Courier'],
      fontSize: 13.5,
      height: 1.5,
      color: look.text,
    );
    // The gutter and highlighted source are separate paragraphs. A forced
    // strut makes every line use the exact same font metrics even when a
    // syntax span is italic/bold or falls back to another glyph font.
    const codeStrut = StrutStyle(
      fontFamily: 'monospace',
      fontFamilyFallback: ['Menlo', 'Roboto Mono', 'Courier'],
      fontSize: 13.5,
      height: 1.5,
      forceStrutHeight: true,
    );
    const codeHeightBehavior = TextHeightBehavior(
      applyHeightToFirstAscent: true,
      applyHeightToLastDescent: true,
    );
    final label = Text(
      language.isEmpty
          ? (style == CodeLook.label ? 'Plain Text' : 'text')
          : language,
      style: theme.textTheme.labelSmall?.copyWith(
        color: look.muted,
        fontWeight: style == CodeLook.card ? FontWeight.w600 : null,
      ),
    );
    final copy = IconButton(
      tooltip: tr('複製程式碼'),
      visualDensity: VisualDensity.compact,
      iconSize: 18,
      color: look.muted,
      onPressed: () async {
        await Clipboard.setData(ClipboardData(text: source));
        if (!context.mounted) return;
        ScaffoldMessenger.maybeOf(context)
          ?..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(tr('已複製程式碼'))));
      },
      icon: const Icon(Icons.copy_rounded),
    );
    final codeTop = style == CodeLook.framed || style == CodeLook.card
        ? 10.0
        : 0.0;
    final code = _OverflowCodeScroller(
      padding: EdgeInsets.fromLTRB(showLineNumbers ? 12 : 16, codeTop, 16, 14),
      child: Text.rich(
        key: const ValueKey('code-source'),
        TextSpan(
          style: codeStyle,
          children: _highlight(source, language, dark),
        ),
        softWrap: false,
        strutStyle: codeStrut,
        textHeightBehavior: codeHeightBehavior,
      ),
    );
    final codeBody = showLineNumbers
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Container(
                  padding: EdgeInsets.fromLTRB(10, codeTop, 10, 14),
                  decoration: BoxDecoration(
                    color: look.text.withValues(alpha: dark ? 0.055 : 0.035),
                    border: Border(
                      right: BorderSide(
                        color: look.codeBorder.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                  child: Text(
                    key: const ValueKey('code-line-numbers'),
                    List.generate(
                      source.split('\n').length,
                      (index) => '${index + 1}',
                    ).join('\n'),
                    textAlign: TextAlign.right,
                    style: codeStyle.copyWith(
                      color: look.muted.withValues(alpha: 0.78),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                    strutStyle: codeStrut,
                    textHeightBehavior: codeHeightBehavior,
                  ),
                ),
              ),
              Expanded(child: code),
            ],
          )
        : code;

    // Header: label and copy button, arranged per palette.
    final header = switch (style) {
      // Obsidian: no visible header, language and copy in the corner.
      CodeLook.flat => Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [label, copy],
      ),
      _ => Padding(
        padding: const EdgeInsets.only(left: 14),
        child: Row(
          children: [
            Expanded(child: label),
            copy,
          ],
        ),
      ),
    };
    final separated = style == CodeLook.framed || style == CodeLook.card;
    final radius = switch (style) {
      CodeLook.framed => look.radius,
      CodeLook.flat || CodeLook.label => 4.0,
      CodeLook.card => 8.0,
      CodeLook.inset => 12.0,
    };
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: look.codeBackground,
        borderRadius: BorderRadius.circular(radius),
        border: style == CodeLook.framed || style == CodeLook.card
            ? Border.all(color: look.codeBorder)
            : null,
        boxShadow: style == CodeLook.card
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: dark ? 0.2 : 0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (separated)
            DecoratedBox(
              decoration: BoxDecoration(
                color: style == CodeLook.card
                    ? Color.lerp(look.codeBackground, look.border, 0.25)
                    : null,
                border: Border(bottom: BorderSide(color: look.codeBorder)),
              ),
              child: header,
            )
          else
            header,
          codeBody,
        ],
      ),
    );
  }

  static List<TextSpan> _highlight(String source, String language, bool dark) {
    if (language.isEmpty || language == 'text' || language == 'plaintext') {
      return [TextSpan(text: source)];
    }
    try {
      final result = highlight.parse(source, language: language);
      final palette = dark ? _darkPalette : _lightPalette;
      return _spans(result.nodes ?? const [], palette);
    } catch (_) {
      return [TextSpan(text: source)];
    }
  }

  static List<TextSpan> _spans(
    List<Node> nodes,
    Map<String, TextStyle> palette,
  ) {
    return [
      for (final node in nodes)
        TextSpan(
          text: node.value,
          style: palette[node.className],
          children: node.children == null
              ? null
              : _spans(node.children!, palette),
        ),
    ];
  }

  static const _lightPalette = <String, TextStyle>{
    'keyword': TextStyle(color: Color(0xFFCF222E)),
    'selector-tag': TextStyle(color: Color(0xFFCF222E)),
    'built_in': TextStyle(color: Color(0xFF953800)),
    'type': TextStyle(color: Color(0xFF953800)),
    'literal': TextStyle(color: Color(0xFF0550AE)),
    'number': TextStyle(color: Color(0xFF0550AE)),
    'string': TextStyle(color: Color(0xFF0A3069)),
    'regexp': TextStyle(color: Color(0xFF0A3069)),
    'comment': TextStyle(color: Color(0xFF6E7781), fontStyle: FontStyle.italic),
    'quote': TextStyle(color: Color(0xFF6E7781)),
    'title': TextStyle(color: Color(0xFF8250DF)),
    'function': TextStyle(color: Color(0xFF8250DF)),
    'attr': TextStyle(color: Color(0xFF0550AE)),
    'attribute': TextStyle(color: Color(0xFF0550AE)),
    'variable': TextStyle(color: Color(0xFF953800)),
    'params': TextStyle(color: Color(0xFF1F2328)),
    'meta': TextStyle(color: Color(0xFF0550AE)),
    'name': TextStyle(color: Color(0xFF116329)),
    'tag': TextStyle(color: Color(0xFF116329)),
    'symbol': TextStyle(color: Color(0xFF0550AE)),
    'section': TextStyle(color: Color(0xFF0550AE), fontWeight: FontWeight.w700),
    'addition': TextStyle(
      color: Color(0xFF116329),
      backgroundColor: Color(0xFFDAFBE1),
    ),
    'deletion': TextStyle(
      color: Color(0xFF82071E),
      backgroundColor: Color(0xFFFFEBE9),
    ),
  };

  static const _darkPalette = <String, TextStyle>{
    'keyword': TextStyle(color: Color(0xFFFF7B72)),
    'selector-tag': TextStyle(color: Color(0xFFFF7B72)),
    'built_in': TextStyle(color: Color(0xFFFFA657)),
    'type': TextStyle(color: Color(0xFFFFA657)),
    'literal': TextStyle(color: Color(0xFF79C0FF)),
    'number': TextStyle(color: Color(0xFF79C0FF)),
    'string': TextStyle(color: Color(0xFFA5D6FF)),
    'regexp': TextStyle(color: Color(0xFFA5D6FF)),
    'comment': TextStyle(color: Color(0xFF8B949E), fontStyle: FontStyle.italic),
    'quote': TextStyle(color: Color(0xFF8B949E)),
    'title': TextStyle(color: Color(0xFFD2A8FF)),
    'function': TextStyle(color: Color(0xFFD2A8FF)),
    'attr': TextStyle(color: Color(0xFF79C0FF)),
    'attribute': TextStyle(color: Color(0xFF79C0FF)),
    'variable': TextStyle(color: Color(0xFFFFA657)),
    'params': TextStyle(color: Color(0xFFE6EDF3)),
    'meta': TextStyle(color: Color(0xFF79C0FF)),
    'name': TextStyle(color: Color(0xFF7EE787)),
    'tag': TextStyle(color: Color(0xFF7EE787)),
    'symbol': TextStyle(color: Color(0xFF79C0FF)),
    'section': TextStyle(color: Color(0xFF1F6FEB), fontWeight: FontWeight.w700),
    'addition': TextStyle(
      color: Color(0xFFAFF5B4),
      backgroundColor: Color(0xFF033A16),
    ),
    'deletion': TextStyle(
      color: Color(0xFFFFDCD7),
      backgroundColor: Color(0xFF67060C),
    ),
  };
}
