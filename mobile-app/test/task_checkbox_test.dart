import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parchment_mobile/core/markdown/note_syntax.dart';
import 'package:parchment_mobile/ui/reader/note_markdown.dart';

Future<TaskStateStore> pumpNote(WidgetTester tester, String markdown) async {
  final store = TaskStateStore();
  final note = PreparedNote.prepare(markdown);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            final config = NoteMarkdownConfig(
              note: note,
              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
              onTapLink: (_, _, _) {},
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
  return store;
}

bool checkboxValue(WidgetTester tester, int index) => tester
    .widget<ThemedCheckBox>(
      find.descendant(
        of: find.byKey(ValueKey('task-$index')),
        matching: find.byType(ThemedCheckBox),
      ),
    )
    .checked;

void main() {
  testWidgets('工作清單可勾選，且巢狀項目各自對應', (tester) async {
    final store = await pumpNote(
      tester,
      '- [ ] 外層\n  - [x] 內層\n- [ ] 第三項\n\n> [!note]\n> - [ ] 提示內的任務',
    );

    expect(store.taskCount, 3);
    expect([0, 1, 2].map((i) => checkboxValue(tester, i)), [
      false,
      true,
      false,
    ]);
    expect(store.hasChanges, isFalse);

    await tester.tap(find.byKey(const ValueKey('task-2')));
    await tester.pump();
    expect(checkboxValue(tester, 2), isTrue);
    expect(store.changes, {2: true});

    await tester.tap(find.byKey(const ValueKey('task-1')));
    await tester.pump();
    expect(store.changes, {2: true, 1: false});

    // Toggling back to the file state is no longer a change.
    await tester.tap(find.byKey(const ValueKey('task-1')));
    await tester.pump();
    expect(store.changes, {2: true});
  });

  testWidgets('捨棄後所有勾選回到檔案狀態', (tester) async {
    final store = await pumpNote(tester, '- [ ] 一\n- [x] 二');
    await tester.tap(find.byKey(const ValueKey('task-0')));
    await tester.tap(find.byKey(const ValueKey('task-1')));
    await tester.pump();
    expect(store.changes, {0: true, 1: false});

    store.discard();
    await tester.pump();
    expect(store.hasChanges, isFalse);
    expect(checkboxValue(tester, 0), isFalse);
    expect(checkboxValue(tester, 1), isTrue);
  });

  testWidgets('文末註腳可在正文引用卸載後捲回原位', (tester) async {
    final controller = ScrollController();
    final store = TaskStateStore();
    final note = PreparedNote.prepare(
      '正文註腳[^a]\n\n${List.generate(180, (i) => '第 ${i + 1} 行內容').join('\n\n')}\n\n[^a]: 註腳內容',
    );
    late NoteMarkdownConfig config;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              config = NoteMarkdownConfig(
                note: note,
                styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
                onTapLink: (_, _, _) {},
                imageBuilder: (uri, title, alt) => const SizedBox(),
                showMessage: (_) {},
                taskStates: store,
              );
              return NoteMarkdownScope(
                config: config,
                child: config.document(
                  controller: controller,
                  padding: EdgeInsets.zero,
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();
    expect(
      tester.getSize(find.byKey(const ValueKey('footnote-reference-fnref-a'))),
      const Size.square(26),
    );
    expect(controller.position.maxScrollExtent, greaterThan(1000));

    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pumpAndSettle();
    final bottom = controller.offset;
    final scrolling = config.scrollToFootnoteReference('fnref-a');
    await tester.pumpAndSettle();
    await scrolling;

    expect(controller.offset, lessThan(bottom / 2));
    controller.dispose();
    store.dispose();
  });

  testWidgets('程式碼超出寬度時顯示水平捲動軸', (tester) async {
    Future<void> pumpCode(String source) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 220,
            child: CodeBlockView(source: source, language: 'dart'),
          ),
        ),
      ),
    );

    await pumpCode('x');
    await tester.pumpAndSettle();
    var scrollbar = tester.widget<RawScrollbar>(
      find.byKey(const ValueKey('code-horizontal-scrollbar')),
    );
    expect(scrollbar.thumbVisibility, isFalse);

    await pumpCode(
      'final veryLongVariableName = someFunctionWithManyArguments(firstArgument, secondArgument, thirdArgument);',
    );
    await tester.pumpAndSettle();
    scrollbar = tester.widget<RawScrollbar>(
      find.byKey(const ValueKey('code-horizontal-scrollbar')),
    );
    expect(scrollbar.thumbVisibility, isTrue);
    expect(scrollbar.trackVisibility, isTrue);
    expect(scrollbar.scrollbarOrientation, ScrollbarOrientation.bottom);
  });
}
