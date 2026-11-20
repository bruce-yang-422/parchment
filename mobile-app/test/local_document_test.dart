import 'package:flutter_test/flutter_test.dart';
import 'package:parchment_mobile/core/models/local_document.dart';

void main() {
  test('只接受 md 與 txt 副檔名且不分大小寫', () {
    expect(LocalDocument.supportsFileName('notes.md'), isTrue);
    expect(LocalDocument.supportsFileName('NOTES.TXT'), isTrue);
    expect(LocalDocument.supportsFileName('notes.markdown'), isFalse);
    expect(LocalDocument.supportsFileName('photo.png'), isFalse);
  });

  test('依副檔名辨識文件格式', () {
    expect(
      LocalDocument.formatForFileName('notes.md'),
      DocumentFormat.markdown,
    );
    expect(
      LocalDocument.formatForFileName('notes.txt'),
      DocumentFormat.plainText,
    );
    expect(
      () => LocalDocument.formatForFileName('notes.pdf'),
      throwsFormatException,
    );
  });
}
