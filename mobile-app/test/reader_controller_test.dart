import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:parchment_mobile/core/models/local_document.dart';
import 'package:parchment_mobile/core/services/document_picker.dart';
import 'package:parchment_mobile/core/services/document_writer.dart';
import 'package:parchment_mobile/core/services/incoming_documents.dart';
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

  test('選檔畫面還開著時收到外部開啟的檔案，結束後接著開啟', () async {
    final picking = Completer<LocalDocument?>();
    final controller = ReaderController(
      documentPicker: _PendingPicker(picking),
      incomingSource: _FakeIncoming(),
    );

    final pick = controller.openDocument();
    await controller.openIncoming(const IncomingDocument(name: 'shared.md'));
    expect(controller.document, isNull);

    // The file manager opened the file elsewhere; the picker returns nothing.
    picking.complete(null);
    await pick;

    expect(controller.document?.name, 'shared.md');
    expect(controller.isOpening, isFalse);
  });
}

class _PendingPicker implements DocumentPicker {
  const _PendingPicker(this.result);

  final Completer<LocalDocument?> result;

  @override
  Future<LocalDocument?> pickDocument() => result.future;
}

class _FakeIncoming implements IncomingDocumentSource {
  @override
  Stream<IncomingDocument> get documents => const Stream.empty();

  @override
  Future<IncomingDocument?> takeInitial() async => null;

  @override
  Future<LocalDocument> load(IncomingDocument incoming) async => LocalDocument(
    name: incoming.name,
    content: '# 內容',
    format: DocumentFormat.markdown,
  );
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
