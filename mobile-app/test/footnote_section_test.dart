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
}
