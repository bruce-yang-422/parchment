class LargeDocumentPolicy {
  const LargeDocumentPolicy._();

  /// Until the paged reader is available, never decode a larger source into
  /// one Dart String. This is deliberately conservative for low-memory phones.
  static const int eagerLoadLimitBytes = 2 * 1024 * 1024;

  static bool requiresPagedReading(int byteLength) {
    return byteLength > eagerLoadLimitBytes;
  }
}

class PagedReadingRequiredException implements Exception {
  const PagedReadingRequiredException(this.byteLength);

  final int byteLength;

  @override
  String toString() {
    final mebibytes = byteLength / (1024 * 1024);
    return '這個檔案太大（約 ${mebibytes.toStringAsFixed(1)} MB），'
        '打開可能讓手機變慢或當機，目前無法開啟。';
  }
}

class FileSizeUnavailableException implements Exception {
  const FileSizeUnavailableException();

  @override
  String toString() {
    return '無法確認檔案大小，為了避免手機變慢，已取消開啟。';
  }
}
