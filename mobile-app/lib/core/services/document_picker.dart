import '../models/local_document.dart';

abstract interface class DocumentPicker {
  Future<LocalDocument?> pickDocument();
}
