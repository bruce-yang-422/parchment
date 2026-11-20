import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:parchment_mobile/core/markdown/note_syntax.dart';
import 'package:parchment_mobile/core/markdown/task_markers.dart';

/// Counts the checkboxes the top-level reader renders (callout bodies are
/// rendered separately and are read-only).
int parserTaskCount(String source) {
  final note = PreparedNote.prepare(source);
  var count = 0;
  void visit(List<md.Node>? nodes) {
    for (final node in nodes ?? const <md.Node>[]) {
      if (node is md.Element) {
        if (node.tag == 'input' && node.attributes['type'] == 'checkbox') {
          count++;
        }
        visit(node.children);
      }
    }
  }

  visit(note.parse(note.markdown));
  return count;
}

void main() {
  const source =
      '---\ntitle: x\n---\n'
      '- [ ] 一\r\n'
      '  - [X] 巢狀\n'
      '1. [ ] 有序\n'
      '```md\n- [ ] 程式碼內\n```\n'
      '> [!todo]\n> - [ ] 提示內\n\n'
      '> - [x] 引用內\n'
      '* [x] 星號 ^block\n';

  test('只找出閱讀器可勾選的工作項目並與解析器一致', () {
    final offsets = findTaskMarkerOffsets(source);
    expect(offsets.length, 5);
    expect(offsets.length, parserTaskCount(source));
    expect(offsets.map((o) => source[o]).join(), ' X xx');
  });

  test('只替換勾選字元，其餘位元組不變', () {
    final result = applyTaskChanges(source, {
      0: true,
      1: false,
      3: false,
    }, expectedTaskCount: 5);
    expect(result.length, source.length);
    final diff = [
      for (var i = 0; i < source.length; i++)
        if (source[i] != result[i]) i,
    ];
    final offsets = findTaskMarkerOffsets(source);
    expect(diff, [offsets[0], offsets[1], offsets[3]]);
    expect(result, contains('- [x] 一\r\n'));
    expect(result, contains('  - [ ] 巢狀'));
    expect(result, contains('> - [ ] 引用內'));
    expect(result, contains('- [ ] 程式碼內'));
    expect(result, contains('> - [ ] 提示內'));
  });

  test('保留原本的大寫 X', () {
    expect(
      applyTaskChanges('- [X] a\n', {0: true}, expectedTaskCount: 1),
      '- [X] a\n',
    );
  });

  test('數量對不上時拒絕寫入', () {
    expect(
      () => applyTaskChanges(source, {0: true}, expectedTaskCount: 4),
      throwsA(isA<TaskMarkerMismatchException>()),
    );
  });

  test('範例文件的工作項目與解析器一致', () {
    for (final path in [
      'test/fixtures/parchment-guide.md',
      'test/fixtures/mermaid-common.md',
    ]) {
      final text = File(path).readAsStringSync();
      expect(
        findTaskMarkerOffsets(text).length,
        parserTaskCount(text),
        reason: path,
      );
    }
  });
}
