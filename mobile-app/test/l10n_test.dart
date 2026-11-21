import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:parchment_mobile/core/l10n/tr.dart';
import 'package:parchment_mobile/core/models/reader_preferences.dart';

/// Unescapes a single-quoted Dart literal body.
String _unescape(String body) => body
    .replaceAll(r"\'", "'")
    .replaceAll(r'\n', '\n')
    .replaceAll(r'\$', r'$')
    .replaceAll(r'\\', r'\');

void main() {
  tearDown(() => AppLocale.current = ReaderLocale.zhTw);

  test('每個 tr() 的文字都有 7 種語言的翻譯', () {
    final call = RegExp(r"""tr\(\s*'((?:[^'\\]|\\.)*)'""");
    final missing = <String>[];
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      for (final match in call.allMatches(file.readAsStringSync())) {
        final key = _unescape(match.group(1)!);
        if (!translations.containsKey(key)) missing.add('${file.path}: $key');
      }
    }
    expect(missing, isEmpty);
  });

  test('翻譯表每列都完整，且佔位符一致', () {
    final holes = RegExp(r'\{(\w+)\}');
    Set<String> names(String text) =>
        holes.allMatches(text).map((m) => m.group(1)!).toSet();
    translations.forEach((key, row) {
      expect(row, hasLength(ReaderLocale.values.length - 1), reason: key);
      for (final text in row) {
        expect(text.trim(), isNotEmpty, reason: key);
        expect(names(text), names(key), reason: '$key → $text');
      }
    });
  });

  test('依目前語言輸出並填入佔位符', () {
    expect(tr('找不到「{name}」', {'name': 'a.md'}), '找不到「a.md」');
    AppLocale.current = ReaderLocale.en;
    expect(tr('找不到「{name}」', {'name': 'a.md'}), '“a.md” not found');
    AppLocale.current = ReaderLocale.de;
    expect(tr('關閉'), 'Schließen');
    // Text that is not in the table is shown as written.
    expect(tr('未翻譯的文字'), '未翻譯的文字');
  });
}
