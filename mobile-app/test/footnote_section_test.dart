import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parchment_mobile/core/markdown/note_syntax.dart';
import 'package:parchment_mobile/ui/reader/note_markdown.dart';

void main() {
  testWidgets('文末註腳用自繪的返回按鈕，不顯示 ↩ 表情符號', (tester) async {
    final tapped = <String>[];
    final note = PreparedNote.prepare('正文[^1]與[^說明]。\n\n[^1]: 第一則\n[^說明]: 第二則');
    final store = TaskStateStore();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              final config = NoteMarkdownConfig(
                note: note,
                styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
                onTapLink: (_, href, _) => tapped.add(href ?? ''),
                imageBuilder: (uri, title, alt) => const SizedBox(),
                showMessage: (_) {},
                taskStates: store,
              );
              return NoteMarkdownScope(
                config: config,
                child: config.document(
                  controller: ScrollController(),
                  padding: EdgeInsets.zero,
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('↩'), findsNothing);
    expect(find.text('第一則'), findsOneWidget);
    expect(find.text('第二則'), findsOneWidget);
    expect(find.byType(FootnoteBackButton), findsNWidgets(2));

    await tester.tap(find.byType(FootnoteBackButton).last);
    expect(tapped.single, startsWith('#fnref-'));
    store.dispose();
  });

  testWidgets('點文末返回箭頭可找到從未顯示過的對應註腳上標', (tester) async {
    final paragraphs = List.generate(
      180,
      (i) => switch (i) {
        50 => '第一次引用[^說明]。',
        100 => '> 第二次引用[^說明]。',
        _ => '段落 $i${i % 3 == 0 ? '  \n第二行  \n第三行' : ''}',
      },
    );
    final note = PreparedNote.prepare(
      '${paragraphs.join('\n\n')}\n\n[^說明]: 註腳內容',
    );
    final scroll = ScrollController();
    final store = TaskStateStore();
    addTearDown(scroll.dispose);
    addTearDown(store.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              late final NoteMarkdownConfig config;
              config = NoteMarkdownConfig(
                note: note,
                styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
                onTapLink: (_, href, _) {
                  if (href != null && href.startsWith('#fnref-')) {
                    unawaited(
                      config.scrollToFootnoteReference(href.substring(1)),
                    );
                  }
                },
                imageBuilder: (uri, title, alt) => const SizedBox(),
                showMessage: (_) {},
                taskStates: store,
              );
              return NoteMarkdownScope(
                config: config,
                child: SelectionArea(
                  child: config.document(
                    controller: scroll,
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 104),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final id = 'fnref-${Uri.encodeComponent('說明')}';
    final first = find.byKey(ValueKey('footnote-reference-$id'));
    final second = find.byKey(ValueKey('footnote-reference-$id-2'));
    expect(first, findsNothing);
    expect(second, findsNothing);

    scroll.jumpTo(scroll.position.maxScrollExtent);
    await tester.pumpAndSettle();
    final arrows = find.byType(FootnoteBackButton);
    expect(arrows, findsNWidgets(2));
    expect(second, findsNothing);
    await tester.tap(arrows.last);
    await tester.pumpAndSettle();

    expect(second.hitTestable(), findsOneWidget);
    expect(first.hitTestable(), findsNothing);
  });
}
