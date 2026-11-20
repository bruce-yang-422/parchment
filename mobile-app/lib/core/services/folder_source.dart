import 'dart:typed_data';

import '../models/note_folder.dart';

/// Opens a folder of notes and reads files inside it.
abstract interface class FolderSource {
  /// Whether this platform supports folder mode.
  bool get isSupported;

  /// Lets the user pick a folder; returns `null` when cancelled.
  Future<NoteFolder?> pickFolder();

  /// Reopens a previously picked folder whose access grant is still valid.
  Future<NoteFolder> openFolderUri(String uri, String name);

  /// URIs of folders the app can still access without asking again.
  Future<Set<String>> grantedFolderUris();

  /// Gives up the stored access grant for [uri].
  Future<void> releaseFolder(String uri);

  Future<Uint8List> readFile(FolderEntry entry);
}
