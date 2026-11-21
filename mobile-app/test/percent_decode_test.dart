import 'package:flutter_test/flutter_test.dart';
import 'package:parchment_mobile/core/markdown/wiki_paths.dart';

void main() {
  test('解開合法的 %XX，中文與單獨的 % 原樣保留', () {
    expect(decodePercent('Parchment%E7%A4%BA%E7%AF%84'), 'Parchment示範');
    expect(decodePercent('Parchment示範'), 'Parchment示範');
    expect(decodePercent('筆記%20一.md'), '筆記 一.md');
    expect(decodePercent('100%完成'), '100%完成');
    expect(decodePercent('%ZZ'), '%ZZ');
    expect(decodePercent('primary:Documents/筆記'), 'primary:Documents/筆記');
  });

  test('中文資料夾網址的路徑片段已解碼，不需再解一次', () {
    final tree = Uri.parse(
      'content://com.android.externalstorage.documents/tree/'
      'primary%3ADocuments%2FParchment%E7%A4%BA%E7%AF%84',
    );
    expect(tree.pathSegments.last, 'primary:Documents/Parchment示範');
    expect(decodePercent(tree.pathSegments.last), tree.pathSegments.last);
  });
}
