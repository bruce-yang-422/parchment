import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:parchment_mobile/core/markdown/html_syntax.dart';
import 'package:parchment_mobile/core/markdown/note_syntax.dart';
import 'package:parchment_mobile/ui/reader/note_markdown.dart';

String render(String source) {
  final note = PreparedNote.prepare(source);
  return md.renderToHtml(note.parse(note.markdown));
}

List<md.Element> blocks(String source) {
  final note = PreparedNote.prepare(source);
  return note.parse(note.markdown).whereType<md.Element>().toList();
}

void main() {
  group('行內 HTML 白名單', () {
    test('常用標籤轉成對應格式', () {
      final html = render(
        '按 <kbd>Ctrl</kbd> + <kbd>C</kbd>，<b>粗</b> <i>斜</i> <u>底線</u> '
        '<s>刪除</s> <mark>螢光</mark> H<sub>2</sub>O x<sup>2</sup>',
      );
      expect(html, contains('<kbd>Ctrl</kbd>'));
      expect(html, contains('<strong>粗</strong>'));
      expect(html, contains('<em>斜</em>'));
      expect(html, contains('<ins>底線</ins>'));
      expect(html, contains('<del>刪除</del>'));
      expect(html, contains('<mark>螢光</mark>'));
      expect(html, contains('<sub-text>2</sub-text>'));
      expect(html, contains('<sup-text>2</sup-text>'));
    });

    test('標籤內的 Markdown 照常解析，kbd／code 內保持原文', () {
      final html = render('<span>**粗體**</span> <kbd>**不變**</kbd>');
      expect(html, contains('<strong>粗體</strong>'));
      expect(html, contains('<kbd>**不變**</kbd>'));
    });

    test('script／style 連同內容移除，註解隱藏', () {
      final html = render(
        '前<script>alert(1)</script>中<style>p{}</style>後<!-- 備註 -->',
      );
      expect(html, isNot(contains('alert')));
      expect(html, isNot(contains('p{}')));
      expect(html, isNot(contains('備註')));
      expect(html, contains('前中後'));
    });

    test('連結只接受安全網址', () {
      final safe = render('<a href="https://example.com">網站</a>');
      expect(safe, contains('href="https://example.com"'));
      final unsafe = render('<a href="javascript:alert(1)">壞</a>');
      expect(unsafe, isNot(contains('javascript')));
      expect(unsafe, contains('壞'));
    });

    test('圖片與換行', () {
      final html = render('一<br>二 <img src="a.png" width="120" alt="圖">');
      expect(html, contains('<br />'));
      expect(html, contains('<html-img src="a.png" alt="圖" width="120" />'));
      final lone = blocks('<img src="a.png" width="120">').single;
      expect(lone.tag, 'html-block');
      expect(lone.attributes['markdown'], '<img src="a.png" width="120">');
      expect(render('<img src="javascript:x">'), isNot(contains('html-img')));
    });

    test('未知標籤與泛型照原樣顯示', () {
      final nodes = blocks('List<String> 與 <custom>x</custom>');
      expect(nodes.first.textContent, contains('List<String>'));
      expect(nodes.first.textContent, contains('<custom>'));
    });

    test('沒有結尾的標籤只隱藏標籤本身', () {
      expect(render('<b>沒有結尾'), contains('沒有結尾'));
    });
  });

  group('區塊 HTML', () {
    test('details／summary 轉成可收合區塊', () {
      final nodes = blocks(
        '<details open>\n<summary>點我展開</summary>\n\n'
        '- 項目 **一**\n\n<details><summary>內層</summary>深</details>\n'
        '</details>\n\n之後',
      );
      expect(nodes.first.tag, 'html-details');
      expect(nodes.first.attributes['summary'], '點我展開');
      expect(nodes.first.attributes['open'], 'true');
      expect(nodes.first.attributes['body'], contains('- 項目 **一**'));
      expect(nodes.first.attributes['body'], contains('<summary>內層'));
      expect(nodes.last.textContent, '之後');
    });

    test('置中的 div／p 保留內容並標記置中', () {
      final nodes = blocks(
        '<p align="center">\n  <img src="logo.png" width="80">\n</p>\n\n內文',
      );
      expect(nodes.first.tag, 'html-block');
      expect(nodes.first.attributes['center'], 'true');
      expect(nodes.first.attributes['markdown'], '<img src="logo.png" width="80">');
      expect(nodes.last.textContent, '內文');
    });

    test('h1 轉成標題，空的包裝標籤不顯示', () {
      final nodes = blocks('<div>\n\n**中間**\n\n</div>');
      expect(nodes.map((e) => e.tag), ['p']);
      final heading = htmlWrapperToMarkdown('<h2 align="center">標題</h2>')!;
      expect((heading as md.Element).attributes['markdown'], '## 標題');
    });

    test('區塊 script 與註解整段移除', () {
      final nodes = blocks('<script>\nalert(1)\n</script>\n<!--\n備註\n-->\n文字');
      expect(nodes.map((e) => e.textContent).join(), '文字');
    });
  });

  testWidgets('kbd 與 details 顯示且可展開', (tester) async {
    final note = PreparedNote.prepare(
      '按 <kbd>Ctrl</kbd>\n\n<details>\n<summary>更多</summary>\n\n隱藏內容\n</details>',
    );
    final config = NoteMarkdownConfig(
      note: note,
      styleSheet: MarkdownStyleSheet(),
      onTapLink: (_, _, _) {},
      imageBuilder: (uri, title, alt) => const SizedBox(),
      showMessage: (_) {},
      taskStates: TaskStateStore(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteMarkdownScope(
            config: config,
            child: config.body(note.markdown),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Ctrl'), findsOneWidget);
    expect(find.textContaining('<kbd>'), findsNothing);
    expect(find.text('隱藏內容'), findsNothing);
    await tester.tap(find.text('更多'));
    await tester.pump();
    expect(find.text('隱藏內容'), findsOneWidget);
  });
}
