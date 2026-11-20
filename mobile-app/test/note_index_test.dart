import 'package:flutter_test/flutter_test.dart';
import 'package:parchment_mobile/core/models/note_folder.dart';
import 'package:parchment_mobile/core/notes/note_index.dart';

void main() {
  final contents = <String, String>{
    'index.md':
        '---\ntitle: 首頁\ntags: [專案, 入門]\n---\n連到 [[daily/today]] 與 [計畫](projects/plan.md#目標)。\n',
    'daily/today.md':
        '# 今天\n\n- [ ] 回覆 [[index]]\n內文提到 #待辦 與 #專案。\n```\n#不是標籤 [[ghost]]\n```\n',
    'projects/plan.md': '## tags: [專案, "規劃"]\n\n# 計畫\n\n目標：完成 Parchment 手機版。\n',
    'notes.txt': '純文字也能搜尋 Parchment。',
  };
  final folder = NoteFolder(
    name: 'Notes',
    uri: 'content://tree',
    entries: [
      for (final path in contents.keys)
        FolderEntry(
          path: path.split('/'),
          uri: 'content://tree/$path',
          directory: false,
        ),
    ],
  );
  final index = NoteIndex([
    for (final entry in folder.notes)
      IndexedNote.fromContent(entry, contents[entry.pathKey]!, folder),
  ]);

  test('標題取自 Frontmatter、第一個標題或檔名', () {
    expect(index['index.md']!.title, '首頁');
    expect(index['daily/today.md']!.title, '今天');
    expect(index['notes.txt']!.title, 'notes');
  });

  test('標籤合併 Frontmatter、tags 標題與行內標籤，忽略程式碼', () {
    expect(index['index.md']!.tags, ['專案', '入門']);
    expect(index['daily/today.md']!.tags, ['待辦', '專案']);
    expect(index['projects/plan.md']!.tags, ['專案', '規劃']);
    expect(index.withTag('#專案').map((n) => n.pathKey).toSet(), {
      'index.md',
      'daily/today.md',
      'projects/plan.md',
    });
    expect(index.tagCounts.first, isA<MapEntry<String, int>>());
    expect(index.tagCounts.first.key, '專案');
    expect(index.tagCounts.first.value, 3);
  });

  test('連結與雙向連結（Wiki Links 與相對 .md 連結）', () {
    expect(index['index.md']!.links, {'daily/today.md', 'projects/plan.md'});
    expect(index['daily/today.md']!.links, {'index.md'});
    expect(index.backlinks('index.md').map((n) => n.pathKey), [
      'daily/today.md',
    ]);
    expect(index.backlinks('projects/plan.md').map((n) => n.pathKey), [
      'index.md',
    ]);
  });

  test('全文搜尋不分大小寫、標題優先並提供片段', () {
    final hits = index.search('parchment');
    expect(hits.map((h) => h.note.pathKey).toSet(), {
      'projects/plan.md',
      'notes.txt',
    });
    final hit = hits.firstWhere((h) => h.note.pathKey == 'notes.txt');
    expect(
      hit.snippet.substring(hit.matchStart, hit.matchStart + hit.matchLength),
      'Parchment',
    );
    expect(index.search('計畫').first.note.pathKey, 'projects/plan.md');
    expect(index.search('  '), isEmpty);
  });
}
