import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:parchment_mobile/core/markdown/frontmatter.dart';
import 'package:parchment_mobile/core/markdown/note_syntax.dart';

String render(String source) {
  final note = PreparedNote.prepare(source);
  return md.renderToHtml(note.parse(note.markdown));
}

void main() {
  test('Frontmatter 解析為屬性而非內文', () {
    final note = PreparedNote.prepare(
      '---\ntitle: 導覽\ntags: [範例, 入門]\n已讀完: false\nlist:\n  - a\n  - "b"\n---\n# 標題',
    );
    expect(note.frontmatter.data, {
      'title': '導覽',
      'tags': ['範例', '入門'],
      '已讀完': false,
      'list': ['a', 'b'],
    });
    expect(note.frontmatter.tags, ['範例', '入門']);
    final html = md.renderToHtml(note.parse(note.markdown));
    expect(html, contains('language-$propertiesFenceLanguage'));
    expect(html, isNot(contains('<hr')));
    expect(html, contains('<h1'));
  });

  test('Callout 保留類型、收合與標題', () {
    final nodes = PreparedNote.prepare(
      '',
    ).parse('> [!question]- 可以收合嗎？\n> 可以。**粗體**\n\n> [!NOTE]\n> GitHub 風格');
    final callouts = nodes.whereType<md.Element>().toList();
    expect(callouts.map((e) => e.tag), ['callout', 'callout']);
    expect(callouts[0].attributes['type'], 'question');
    expect(callouts[0].attributes['fold'], '-');
    expect(callouts[0].attributes['title'], '可以收合嗎？');
    expect(callouts[0].attributes['body'], '可以。**粗體**');
    expect(callouts[1].attributes['type'], 'note');
  });

  test('行內擴充語法', () {
    final html = render(
      '==螢光== ++插入++ H~2~O x^2^ ~~刪除~~ :sparkles: \$E=mc^2\$ 價格 \$5 與 \$6\n\n*[HTML]: HyperText\n\nHTML 與 XHTML',
    );
    expect(html, contains('<mark>螢光</mark>'));
    expect(html, contains('<ins>插入</ins>'));
    expect(html, contains('<sub-text>2</sub-text>'));
    expect(html, contains('<sup-text>2</sup-text>'));
    expect(html, contains('<del>刪除</del>'));
    expect(html, contains('✨'));
    expect(html, contains('<math-inline>E=mc^2</math-inline>'));
    expect(html, contains(r'$5 與 $6'));
    expect(html, contains('<abbr title="HyperText">HTML</abbr> 與 XHTML'));
    expect(html, isNot(contains('*[HTML]')));
  });

  test('註腳不被上標語法吃掉', () {
    final note = PreparedNote.prepare('註腳[^a]，平方 x^2^。\n\n[^a]: 內容\n  第二行');
    final html = md.renderToHtml(note.parse(note.markdown));
    expect(html, contains('href="#fn-a"'));
    expect(html, contains('<sup-text>2</sup-text>'));
    expect(note.footnotes['a'], '內容\n第二行');
  });

  test('Wiki Links、內嵌與區塊 ID', () {
    final html = render(
      '連到 [[note#段落|別名]] 與 [[note]]\n\n![[note#^summary]]\n\n段落 ^summary',
    );
    expect(html, contains('<wikilink raw="note#段落|別名">別名</wikilink>'));
    expect(html, contains('<wikilink raw="note">note</wikilink>'));
    expect(html, contains('<wiki-embed raw="note#^summary">'));
    expect(html, contains('<p>段落</p>'));
  });

  test('數學區塊、定義清單與 tags 標題', () {
    final nodes = PreparedNote.prepare('').parse(
      '\$\$\n\\int x\n\$\$\n\n唯讀\n: 只讀取\n: 第二義\n\n本機\n: 不上傳\n\n## tags: [a, "b"]',
    );
    final elements = nodes.whereType<md.Element>().toList();
    expect(elements.map((e) => e.tag), [
      'math-block',
      'definition-list',
      'properties',
    ]);
    expect(elements[0].attributes['tex'], r'\int x');
    expect(jsonDecode(elements[1].attributes['json']!), [
      {
        'term': '唯讀',
        'definitions': ['只讀取', '第二義'],
      },
      {
        'term': '本機',
        'definitions': ['不上傳'],
      },
    ]);
    expect(jsonDecode(elements[2].attributes['json']!), {
      'tags': ['a', 'b'],
    });
  });

  test('目錄忽略程式碼區塊與 Frontmatter', () {
    final headings = extractHeadings(
      '---\ntitle: x\n---\n# 一\n```bash\n# 註解\n```\n## 二\n## tags: [a]',
    );
    expect(headings.map((h) => h.title), ['一', '二']);
  });

  test('目錄包含底線式（setext）標題，分隔線與清單不算標題', () {
    const source =
        '# 一\n\n另一種寫法\n=====\n\n第二層\n---\n\n段落\n\n---\n\n- 項目\n---\n';
    final headings = extractHeadings(source);
    expect(headings.map((h) => h.title), ['一', '另一種寫法', '第二層']);
    expect(headings.map((h) => h.level), [1, 1, 2]);
    expect(headings[1].offset, source.indexOf('另一種寫法'));
    expect(headings[2].offset, source.indexOf('第二層'));
  });

  test('範例文件不再顯示原始語法符號', () {
    final source = File('test/fixtures/parchment-guide.md').readAsStringSync();
    final html = render(source).replaceFirst(
      RegExp(
        r'<pre><code class="language-parchment-properties">[\s\S]*?</pre>',
      ),
      '',
    );
    for (final raw in [
      '[!tip]',
      '[!note]',
      '==',
      '++',
      '*[HTML]',
      '![[',
      '[[',
      'title:',
    ]) {
      expect(html, isNot(contains(raw)), reason: raw);
    }
    expect(html, contains('language-dot'));
    expect(html, contains('language-mermaid'));
    expect(Frontmatter.parse(source).data, isNotNull);
  });

  test('Windows CRLF 換行也能解析標題、縮寫、註腳與區塊 ID', () {
    const source =
        '# 一\r\n\r\nHTML 段落 ^id\r\n\r\n*[HTML]: 超文字\r\n[^a]: 註\r\n## 二\r\n';
    expect(extractHeadings(source).map((h) => h.title), ['一', '二']);
    expect(extractHeadings(source)[1].offset, source.indexOf('## 二'));
    final note = PreparedNote.prepare(source);
    expect(note.abbreviations, {'HTML': '超文字'});
    expect(note.footnotes, {'a': '註'});
    expect(note.markdown, isNot(contains('^id')));
    expect(note.markdown, isNot(contains('\r')));
  });

  test('中文或大寫名稱的註腳也找得到內容', () {
    final note = PreparedNote.prepare(
      '一[^1]，二[^說明]，三[^Note]。\n\n'
      '[^1]: 第一\n[^說明]: 第二\n[^Note]: 第三',
    );
    final html = md.renderToHtml(note.parse(note.markdown));
    final labels = RegExp(
      r'href="#fn-([^"]+)"',
    ).allMatches(html).map((m) => m.group(1)!).toList();
    expect(labels, hasLength(3));
    expect(labels.map(note.footnoteFor), ['第一', '第二', '第三']);
  });
}
