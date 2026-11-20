import 'package:flutter_test/flutter_test.dart';
import 'package:parchment_mobile/core/markdown/wiki_paths.dart';
import 'package:parchment_mobile/core/models/local_document.dart';
import 'package:parchment_mobile/core/models/note_folder.dart';
import 'package:parchment_mobile/ui/reader/folder_tree.dart';

NoteFolder sampleFolder() {
  FolderEntry file(String path) => FolderEntry(
    path: path.split('/'),
    uri: 'content://tree/$path',
    directory: false,
  );
  return NoteFolder(
    name: 'Notes',
    uri: 'content://tree',
    entries: [
      const FolderEntry(path: ['daily'], uri: 'content://d', directory: true),
      file('index.md'),
      file('linked-note.md'),
      file('daily/2026-11-20.md'),
      file('daily/linked-note.md'),
      file('projects/plan/linked-note.md'),
      file('assets/logo.png'),
      file('daily/img/photo.jpg'),
    ],
  );
}

void main() {
  group('Wiki 路徑解析（與網頁版規則一致）', () {
    final folder = sampleFolder();

    test('同資料夾優先，其次最短路徑', () {
      expect(
        folder.resolve('linked-note', [
          'daily',
          '2026-11-20.md',
        ], markdown: true)?.pathKey,
        'daily/linked-note.md',
      );
      expect(
        folder.resolve('linked-note', ['index.md'], markdown: true)?.pathKey,
        'linked-note.md',
      );
    });

    test('完整路徑、大小寫與附件檔名', () {
      expect(
        folder.resolve('Projects/Plan/Linked-Note', [
          'index.md',
        ], markdown: true)?.pathKey,
        'projects/plan/linked-note.md',
      );
      expect(
        folder.resolve('logo.png', ['daily/x.md'])?.pathKey,
        'assets/logo.png',
      );
      expect(folder.resolve('missing', ['index.md'], markdown: true), isNull);
    });

    test('相對 Markdown 路徑不可跳出資料夾', () {
      final source = ['daily', '2026-11-20.md'];
      expect(
        folder.resolveRelative('img/photo.jpg', source)?.pathKey,
        'daily/img/photo.jpg',
      );
      expect(
        folder.resolveRelative('../assets/logo.png', source)?.pathKey,
        'assets/logo.png',
      );
      expect(
        folder.resolveRelative('../linked-note.md#段落', source)?.pathKey,
        'linked-note.md',
      );
      expect(folder.resolveRelative('../../../etc/passwd', source), isNull);
    });

    test('只列出筆記並自然排序', () {
      expect(folder.notes.length, 5);
      final names = ['10.md', '2.md', 'b.md', 'A.md']..sort(naturalCompare);
      expect(names, ['2.md', '10.md', 'A.md', 'b.md']);
    });
  });

  group('內嵌段落擷取', () {
    const note =
        '---\ntitle: x\n---\n# 標題\n前言\n\n## 可以被內嵌的段落\n內容 A\n```\n# 不是標題\n```\n### 子段落\n內容 B\n## 下一節\n其他\n\n摘要句子 ^summary\n';

    test('標題段落包含子段落、在同級標題停止', () {
      expect(
        extractNoteSection(note, heading: '可以被內嵌的段落'),
        '## 可以被內嵌的段落\n內容 A\n```\n# 不是標題\n```\n### 子段落\n內容 B',
      );
    });

    test('區塊 ID 擷取並移除標記', () {
      expect(extractNoteSection(note, blockId: 'summary'), '摘要句子');
    });

    test('找不到時回傳 null，未指定時回傳去除 Frontmatter 的全文', () {
      expect(extractNoteSection(note, heading: '不存在'), isNull);
      expect(extractNoteSection(note), startsWith('# 標題'));
    });
  });

  group('外部 App 傳入的檔案', () {
    test('依副檔名或 MIME 判斷格式，其他類型拒絕', () {
      expect(
        LocalDocument.formatForIncoming('note.MD', 'application/octet-stream'),
        DocumentFormat.markdown,
      );
      expect(
        LocalDocument.formatForIncoming('note.txt', null),
        DocumentFormat.plainText,
      );
      expect(
        LocalDocument.formatForIncoming('shared', 'text/markdown'),
        DocumentFormat.markdown,
      );
      expect(
        () => LocalDocument.formatForIncoming('photo.jpg', 'text/plain'),
        throwsFormatException,
      );
      expect(
        () =>
            LocalDocument.formatForIncoming('blob', 'application/octet-stream'),
        throwsFormatException,
      );
    });

    test('非 UTF-8 內容標記為不可無損寫回', () {
      final valid = LocalDocument.decode(
        name: 'a.md',
        bytes: [0xE4, 0xB8, 0xAD, 0x0A],
        format: DocumentFormat.markdown,
      );
      final invalid = LocalDocument.decode(
        name: 'b.md',
        bytes: [0x61, 0xFF, 0x62],
        format: DocumentFormat.markdown,
      );
      expect(valid.lossless, isTrue);
      expect(valid.content, '中\n');
      expect(invalid.lossless, isFalse);
    });
  });
}
