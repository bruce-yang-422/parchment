import 'package:flutter_test/flutter_test.dart';
import 'package:parchment_mobile/core/models/local_document.dart';
import 'package:parchment_mobile/core/services/document_picker.dart';
import 'package:parchment_mobile/core/services/document_writer.dart';
import 'package:parchment_mobile/features/reader/reader_controller.dart';

LocalDocument sampleDocument() => LocalDocument(
  name: 'note.md',
  content: '- [ ] task',
  format: DocumentFormat.markdown,
  sourceUri: 'content://docs/note.md',
);

void main() {
  test('選檔後更新目前文件', () async {
    final selected = sampleDocument();
    final controller = ReaderController(
      documentPicker: _FakeDocumentPicker(selected),
    );

    await controller.openDocument();

    expect(controller.document, same(selected));
    expect(controller.errorMessage, isNull);
    expect(controller.isOpening, isFalse);
    expect(controller.canSaveAs, isFalse);
  });

  test('寫回原檔後保留文件識別並更新內容', () async {
    final writer = _FakeDocumentWriter();
    final controller = ReaderController(
      documentPicker: _FakeDocumentPicker(sampleDocument()),
      documentWriter: writer,
    );
    await controller.openDocument();
    final before = controller.document!;

    expect(controller.canWriteInPlace, isTrue);
    await controller.writeInPlace('- [x] task');

    expect(writer.written, ['- [x] task']);
    expect(controller.document!.content, '- [x] task');
    expect(controller.document!.id, before.id);
    expect(controller.document, isNot(same(before)));
  });

  test('檔案已被外部修改時不更新內容', () async {
    final writer = _FakeDocumentWriter(conflict: true);
    final controller = ReaderController(
      documentPicker: _FakeDocumentPicker(sampleDocument()),
      documentWriter: writer,
    );
    await controller.openDocument();
    final before = controller.document;

    await expectLater(
      controller.writeInPlace('- [x] task'),
      throwsA(isA<DocumentChangedException>()),
    );
    expect(controller.document, same(before));
  });
}

class _FakeDocumentPicker implements DocumentPicker {
  const _FakeDocumentPicker(this.document);

  final LocalDocument? document;

  @override
  Future<LocalDocument?> pickDocument() async => document;
}

class _FakeDocumentWriter implements DocumentWriter {
  _FakeDocumentWriter({this.conflict = false});

  final bool conflict;
  final List<String> written = [];

  @override
  bool canWriteInPlace(LocalDocument document) => document.sourceUri != null;

  @override
  Future<void> writeInPlace(LocalDocument document, String content) async {
    if (conflict) throw const DocumentChangedException();
    written.add(content);
  }

  @override
  Future<bool> saveAs(LocalDocument document, String content) async => true;
}
