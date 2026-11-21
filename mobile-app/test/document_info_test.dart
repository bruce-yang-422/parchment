import 'package:flutter_test/flutter_test.dart';
import 'package:parchment_mobile/core/models/local_document.dart';
import 'package:parchment_mobile/core/notes/document_stats.dart';
import 'package:parchment_mobile/core/notes/note_index.dart';
import 'package:parchment_mobile/core/services/document_inspector.dart';
import 'package:parchment_mobile/infrastructure/android_document_channel.dart';

void main() {
  test('中英文字數、字元與行數', () {
    final stats = DocumentStats.of(
      '你好世界 Hello world, it\'s 2026.\n\n第二段',
      markdown: false,
    );
    expect(stats.cjkCharacters, 7);
    expect(stats.latinWords, 4);
    expect(stats.words, 11);
    expect(stats.lines, 3);
    expect(stats.paragraphs, 2);
    expect(stats.lineEnding, LineEnding.lf);
    expect(stats.characters, 33);
    expect(stats.charactersWithoutSpaces, 27);
  });

  test('Markdown 結構統計忽略程式碼與連結網址', () {
    const source =
        '---\r\ntitle: 測試\r\ntags: [a]\r\n---\r\n'
        '# 標題\r\n\r\n'
        '連到 [[note]] 與 [文件](other.md) 及 https://example.com\r\n'
        '![圖](a.png) ![[b.png|96]] ![[note#段落]]\r\n\r\n'
        '- [x] 完成\r\n- [ ] 未完成\r\n\r\n'
        '```js\r\n// [[不是連結]] - [ ] 不是任務\r\n```\r\n'
        '```mermaid\r\nflowchart LR\r\n```\r\n'
        '註腳[^1]\r\n\r\n[^1]: 內容\r\n';
    final stats = DocumentStats.of(source, markdown: true);
    expect(stats.lineEnding, LineEnding.crlf);
    expect(stats.properties, 2);
    expect(stats.headings, 1);
    expect(stats.wikiLinks, 1);
    expect(stats.markdownLinks, 1);
    expect(stats.externalLinks, 1);
    expect(stats.images, 2);
    expect(stats.codeBlocks, 1);
    expect(stats.diagrams, 1);
    expect(stats.footnotes, 1);
    expect(stats.tasks, 2);
    expect(stats.completedTasks, 1);
  });

  test('混合換行與 BOM 偵測', () {
    expect(
      DocumentStats.of('a\r\nb\nc', markdown: false).lineEnding,
      LineEnding.mixed,
    );
    final document = LocalDocument.decode(
      name: 'a.md',
      bytes: [0xEF, 0xBB, 0xBF, 0x61],
      format: DocumentFormat.markdown,
    );
    expect(document.hasBom, isTrue);
    expect(document.byteLength, 4);
  });

  test('從 SAF 文件 ID 推導可讀位置', () {
    expect(
      describeLocation(
        documentId: 'primary:Download/Notes/a.md',
        authority: 'com.android.externalstorage.documents',
      )?.display,
      '內部儲存空間/Download/Notes/a.md',
    );
    expect(
      describeLocation(
        documentId: '1234-ABCD:Books/b.md',
        authority: 'com.android.externalstorage.documents',
      )?.display,
      'SD 卡（1234-ABCD）/Books/b.md',
    );
    expect(
      describeLocation(
        documentId: 'raw:/storage/emulated/0/Download/c.md',
        authority: 'com.android.providers.downloads.documents',
      )?.display,
      '內部儲存空間/Download/c.md',
    );
    expect(
      describeLocation(
        documentId: 'msf:85',
        authority: 'com.android.providers.downloads.documents',
      )?.display,
      '下載項目',
    );
    expect(
      describeLocation(
        authority: 'jp.naver.line.android.fileprovider',
      )?.display,
      '來自 LINE',
    );
    expect(
      describeLocation(
        authority: 'media',
        storagePath: 'Documents/Parchment示範/示範.md',
      )?.display,
      '內部儲存空間/Documents/Parchment示範/示範.md',
    );
    expect(describeLocation(authority: 'com.example.app')?.display, '來自其他 App');
    expect(
      describeLocation(
        documentId: 'primary:Documents/筆記/a.md',
        authority: 'com.android.externalstorage.documents',
      )?.absolute,
      '/storage/emulated/0/Documents/筆記/a.md',
    );
    expect(
      describeLocation(
        documentId: '1234-ABCD:Notes/a.md',
        authority: 'com.android.externalstorage.documents',
      )?.absolute,
      '/storage/1234-ABCD/Notes/a.md',
    );
    expect(
      describeLocation(
        authority: 'media',
        storagePath: 'Documents/a.md',
        absolutePath: '/storage/emulated/0/Documents/a.md',
      )?.absolute,
      '/storage/emulated/0/Documents/a.md',
    );
    expect(describeLocation(authority: 'com.example.app')?.absolute, isNull);
  });

  test('外部開檔以正式顯示名稱取代 MediaStore 數字 ID', () {
    expect(
      resolveIncomingFileName(
        '1000102238',
        const DocumentStat(
          displayName: '住院準備指南.md',
          storagePath: 'Download/Telegram/住院準備指南.md',
        ),
      ),
      '住院準備指南.md',
    );
    expect(
      resolveIncomingFileName(
        '1000102238',
        const DocumentStat(
          displayName: '1000102238',
          absolutePath: '/storage/emulated/0/Download/Telegram/住院準備指南.md',
        ),
      ),
      '住院準備指南.md',
    );
    expect(resolveIncomingFileName('note.md', null), 'note.md');
  });

  test('內文標籤只認空白後的 #，連結與程式碼裡的 # 不算', () {
    expect(
      noteTags('#一 文字#不是 [[筆記#標題]] [連結](a.md#b) `#程式` \n#二\n## tags: 甲, 乙'),
      ['甲', '乙', '一', '二'],
    );
  });

  test('讀檔時計算 SHA-256，存檔後依新內容重算', () {
    final document = LocalDocument.decode(
      name: 'a.md',
      bytes: 'abc'.codeUnits,
      format: DocumentFormat.markdown,
    );
    expect(
      document.sha256,
      'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    );
    final saved = document.copyWith(content: '');
    expect(
      saved.sha256,
      'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    );
  });
}
