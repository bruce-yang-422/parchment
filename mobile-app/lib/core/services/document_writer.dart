import '../models/local_document.dart';

/// Writes user-approved edits. Nothing is written unless the user chooses to
/// save.
abstract interface class DocumentWriter {
  /// Whether [document] can be overwritten at its original location.
  bool canWriteInPlace(LocalDocument document);

  /// Replaces the original file with [content]. Throws
  /// [DocumentChangedException] if the file changed since it was opened.
  Future<void> writeInPlace(LocalDocument document, String content);

  /// Saves [content] through the system "save as" dialog. Returns `false`
  /// when the user cancels.
  Future<bool> saveAs(LocalDocument document, String content);
}

class DocumentChangedException implements Exception {
  const DocumentChangedException();

  @override
  String toString() => '這個檔案在你打開後被其他 App 改過了，為了不蓋掉那些修改，這次沒有儲存。請重新開啟檔案再試一次。';
}
