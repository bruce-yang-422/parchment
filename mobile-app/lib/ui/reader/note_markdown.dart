import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:highlight/highlight.dart' show highlight, Node;
import 'package:markdown/markdown.dart' as md;

import '../../core/markdown/frontmatter.dart';
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

  /// Task indexes waiting for their list item's checkbox. Inputs are visited
  /// before their `li` finishes, and nested items finish first, so a stack
  /// pairs every checkbox with its own task.
  final List<int> _pendingTasks = [];
  int _taskCount = 0;

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
    return Markdown(
      controller: controller,
      data: note.markdown,
      padding: padding,
      styleSheet: styleSheet,
      builders: _documentBuilders,
      extensionSet: note.extensionSet,
      blockSyntaxes: note.blockSyntaxes,
      inlineSyntaxes: note.inlineSyntaxes,
      onTapLink: onTapLink,
      imageBuilder: imageBuilder,
      checkboxBuilder: _taskCheckbox,
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
      _ => CodeBlockView(source: source, language: language),
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
      config._pendingTasks.add(config._taskCount++);
    }
    return null;
  }
}

enum _InlineStyle { mark, ins, sup, sub }

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
    final colors = Theme.of(context).colorScheme;
    final base = parentStyle ?? DefaultTextStyle.of(context).style;
    final visualSize = math.max(12.0, (base.fontSize ?? 16) * 0.78);
    return Text.rich(
      WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: Transform.translate(
          offset: Offset(0, -visualSize * 0.24),
          child: Semantics(
            button: true,
            label: tr('註腳 {number}', {'number': number}),
            child: Material(
              color: colors.primaryContainer.withValues(alpha: 0.72),
              shape: const StadiumBorder(),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: () => config.onTapLink(number, href, ''),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 30,
                    minHeight: 28,
                  ),
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
    final body = NoteMarkdownScope.of(
      context,
    ).body(element.attributes['markdown'] ?? '');
    if (element.attributes['center'] != 'true') return body;
    return Align(
      child: DefaultTextStyle.merge(textAlign: TextAlign.center, child: body),
    );
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
                      ? tr('開啟整個筆記資料夾後，這張圖片才會顯示')
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

class CodeBlockView extends StatelessWidget {
  const CodeBlockView({
    required this.source,
    required this.language,
    super.key,
  });

  final String source;
  final String language;

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
    final code = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.fromLTRB(
        16,
        style == CodeLook.framed || style == CodeLook.card ? 10 : 0,
        16,
        14,
      ),
      child: Text.rich(
        TextSpan(
          style: codeStyle,
          children: _highlight(source, language, dark),
        ),
        softWrap: false,
      ),
    );

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
          code,
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
