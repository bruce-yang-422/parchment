import 'package:flutter_test/flutter_test.dart';
import 'package:parchment_mobile/core/markdown/wiki_paths.dart';

void main() {
  test('GitHub 風格的標題錨點可對應到標題', () {
    expect(headingSlug('8. 表格 Tables'), '8-表格-tables');
    expect(headingSlug('Tiếng Việt'), 'tiếng-việt');
    expect(headingMatches('8. 表格 Tables', '8-表格-tables'), isTrue);
    expect(headingMatches('8. 表格 Tables', '8. 表格 Tables'), isTrue);
    expect(headingMatches('8. 表格 Tables', '9-引用'), isFalse);
  });
}
