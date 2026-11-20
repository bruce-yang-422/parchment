import 'package:flutter_test/flutter_test.dart';
import 'package:parchment_mobile/core/models/local_document.dart';
import 'package:parchment_mobile/core/notes/document_stats.dart';
import 'package:parchment_mobile/core/services/document_inspector.dart';

void main() {
  test('中英文字數、字元、行數與閱讀時間', () {
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
    expect(stats.readingTime.inSeconds, greaterThan(0));
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
      '來源：jp.naver.line.android.fileprovider',
    );
  });
}
