import 'package:flutter_test/flutter_test.dart';
import 'package:parchment_mobile/core/services/large_document_policy.dart';

void main() {
  test('2 MiB 以內可直接載入', () {
    expect(
      LargeDocumentPolicy.requiresPagedReading(
        LargeDocumentPolicy.eagerLoadLimitBytes,
      ),
      isFalse,
    );
  });

  test('超過 2 MiB 必須使用分頁閱讀', () {
    expect(
      LargeDocumentPolicy.requiresPagedReading(
        LargeDocumentPolicy.eagerLoadLimitBytes + 1,
      ),
      isTrue,
    );
  });
}
