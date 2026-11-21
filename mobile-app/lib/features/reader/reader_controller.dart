import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/markdown/wiki_paths.dart';
import '../../core/models/local_document.dart';
import '../../core/models/note_folder.dart';
import '../../core/models/reader_preferences.dart';
import '../../core/notes/note_index.dart';
import '../../core/services/document_inspector.dart';
import '../../core/services/document_picker.dart';
import '../../core/services/document_writer.dart';
import '../../core/services/folder_source.dart';
import '../../core/services/incoming_documents.dart';
import '../../core/services/large_document_policy.dart';
import '../../core/services/reader_settings.dart';
import '../../core/services/recent_folders.dart';
import '../../core/l10n/tr.dart';

class ReaderController extends ChangeNotifier {
  ReaderController({
    required DocumentPicker documentPicker,
    DocumentWriter? documentWriter,
    FolderSource? folderSource,
    IncomingDocumentSource? incomingSource,
    RecentFoldersStore? recentFoldersStore,
    DocumentInspector? documentInspector,
    ReaderSettingsStore? settingsStore,
    ReaderSettings? initialSettings,
  }) : _documentPicker = documentPicker,
       _settingsStore = settingsStore,
       _inspector = documentInspector,
       _documentWriter = documentWriter,
       _folderSource = folderSource,
       _incomingSource = incomingSource,
       _recentStore = recentFoldersStore {
    if (initialSettings != null) _applySettings(initialSettings);
  }

  final DocumentPicker _documentPicker;
  final DocumentWriter? _documentWriter;
  final FolderSource? _folderSource;
  final IncomingDocumentSource? _incomingSource;
  final RecentFoldersStore? _recentStore;
  final DocumentInspector? _inspector;
  final ReaderSettingsStore? _settingsStore;
  Timer? _saveTimer;

  List<RecentFolder> _recentFolders = const [];
  Set<String> _grantedFolderUris = const {};
  NoteIndex? _index;
  Future<NoteIndex>? _indexing;
  int _indexedCount = 0;

  LocalDocument? _document;
  NoteFolder? _folder;
  Object? _error;
  bool _isOpening = false;
  ThemeMode _themeMode = ThemeMode.system;
  double _textScale = 1;
  double _lineHeight = 1.75;
  ReaderLocale _locale = ReaderLocale.zhTw;
  ReaderCjkFont _cjkFont = ReaderCjkFont.system;
  ReaderLatinFont _latinFont = ReaderLatinFont.system;
  ReaderPalette _palette = ReaderPalette.parchment;
  bool _fullscreen = false;
  bool _codeLineNumbers = false;

  LocalDocument? get document => _document;
  NoteFolder? get folder => _folder;
  bool get supportsFolders => _folderSource?.isSupported ?? false;
  IncomingDocumentSource? get incomingSource => _incomingSource;
  List<RecentFolder> get recentFolders => _recentFolders;

  /// Whether [folder] can be reopened without picking it again.
  bool isFolderGranted(RecentFolder folder) =>
      _grantedFolderUris.contains(folder.uri);

  NoteIndex? get noteIndex => _index;
  bool get isIndexing => _indexing != null && _index == null;
  int get indexedCount => _indexedCount;

  /// Plain message for the home screen, without technical exception names.
  String? get errorMessage => switch (_error) {
    null => null,
    FormatException(:final message) => message,
    PlatformException() => tr('無法讀取檔案'),
    final error => error.toString(),
  };
  bool get isOpening => _isOpening;
  ThemeMode get themeMode => _themeMode;
  double get textScale => _textScale;
  double get lineHeight => _lineHeight;
  ReaderLocale get locale => _locale;
  ReaderCjkFont get cjkFont => _cjkFont;
  ReaderLatinFont get latinFont => _latinFont;
  ReaderPalette get palette => _palette;
  bool get fullscreen => _fullscreen;
  bool get codeLineNumbers => _codeLineNumbers;

  void setLocale(ReaderLocale value) => _update(value, _locale, (next) {
    _locale = next;
    AppLocale.current = next;
  });
  void setCjkFont(ReaderCjkFont value) =>
      _update(value, _cjkFont, (next) => _cjkFont = next);
  void setLatinFont(ReaderLatinFont value) =>
      _update(value, _latinFont, (next) => _latinFont = next);
  void setPalette(ReaderPalette value) =>
      _update(value, _palette, (next) => _palette = next);
  void setFullscreen(bool value) =>
      _update(value, _fullscreen, (next) => _fullscreen = next);
  void setCodeLineNumbers(bool value) =>
      _update(value, _codeLineNumbers, (next) => _codeLineNumbers = next);

  void _update<T>(T value, T current, void Function(T) assign) {
    if (value == current) return;
    assign(value);
    _settingsChanged();
  }

  void setThemeMode(ThemeMode value) {
    if (_themeMode == value) return;
    _themeMode = value;
    _settingsChanged();
  }

  void setTextScale(double value) {
    final normalized = value.clamp(0.5, 2.0);
    if (_textScale == normalized) return;
    _textScale = normalized;
    _settingsChanged();
  }

  void setLineHeight(double value) {
    final normalized = value.clamp(1.3, 2.2);
    if (_lineHeight == normalized) return;
    _lineHeight = normalized;
    _settingsChanged();
  }

  /// Current reading settings, as they are saved.
  ReaderSettings get settings => ReaderSettings(
    themeMode: _themeMode.name,
    textScale: _textScale,
    lineHeight: _lineHeight,
    locale: _locale,
    cjkFont: _cjkFont,
    latinFont: _latinFont,
    palette: _palette,
    fullscreen: _fullscreen,
    codeLineNumbers: _codeLineNumbers,
  );

  void _applySettings(ReaderSettings settings) {
    _themeMode = ThemeMode.values.firstWhere(
      (mode) => mode.name == settings.themeMode,
      orElse: () => ThemeMode.system,
    );
    _textScale = settings.textScale;
    _lineHeight = settings.lineHeight;
    _locale = settings.locale;
    AppLocale.current = settings.locale;
    _cjkFont = settings.cjkFont;
    _latinFont = settings.latinFont;
    _palette = settings.palette;
    _fullscreen = settings.fullscreen;
    _codeLineNumbers = settings.codeLineNumbers;
  }

  /// Saves shortly after the last change, so dragging a slider writes once.
  void _settingsChanged() {
    notifyListeners();
    if (_settingsStore == null) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 400), saveSettings);
  }

  @override
  void dispose() {
    if (_saveTimer?.isActive ?? false) unawaited(saveSettings());
    super.dispose();
  }

  /// Writes the settings now (also used when the app closes).
  Future<void> saveSettings() async {
    _saveTimer?.cancel();
    _saveTimer = null;
    try {
      await _settingsStore?.save(settings);
    } on Object {
      // Settings are a convenience; failing to save must not break reading.
    }
  }

  /// Platform metadata (size, modified time, location) of the open file.
  Future<DocumentStat?> statDocument() async {
    final uri = _document?.originUri;
    final inspector = _inspector;
    if (uri == null || inspector == null) return null;
    try {
      return await inspector.stat(uri);
    } catch (_) {
      return null;
    }
  }

  /* ──────────────── Saving ──────────────── */

  bool get canSaveAs => _documentWriter != null;

  bool get canWriteInPlace {
    final document = _document;
    return document != null &&
        (_documentWriter?.canWriteInPlace(document) ?? false);
  }

  /// Overwrites the original file with [content] after the user chose to
  /// save, then shows the saved content without resetting the reader.
  Future<void> writeInPlace(String content) async {
    final document = _document;
    final writer = _documentWriter;
    if (document == null || writer == null) return;
    await writer.writeInPlace(document, content);
    if (identical(_document, document)) {
      _document = document.copyWith(content: content);
      _updateIndexed(_document!);
      notifyListeners();
    }
  }

  /// Saves [content] as a new file; the open document is left unchanged.
  Future<bool> saveAs(String content) async {
    final document = _document;
    final writer = _documentWriter;
    if (document == null || writer == null) return false;
    return writer.saveAs(document, content);
  }

  /* ──────────────── Opening ──────────────── */

  Future<void> openDocument() => _open(_documentPicker.pickDocument);

  /// Opens a file sent by another app ("Open with" / share).
  ///
  /// A file can arrive while the document picker is still open (some file
  /// managers open the tapped file with "Open with" instead of returning
  /// it to the picker); it is opened as soon as the picker has finished
  /// instead of being dropped.
  Future<void> openIncoming(IncomingDocument incoming) async {
    if (_isOpening) {
      _queuedIncoming = incoming;
      return;
    }
    await _open(() => _incomingSource!.load(incoming));
  }

  IncomingDocument? _queuedIncoming;

  /// Lets the user pick a folder. Returns whether a folder was opened.
  Future<bool> openFolder() async {
    final source = _folderSource;
    if (source == null || _isOpening) return false;
    _isOpening = true;
    _error = null;
    notifyListeners();
    try {
      final folder = await source.pickFolder();
      if (folder == null) return false;
      _setFolder(folder);
      await _remember(folder);
      return true;
    } catch (error) {
      _error = error;
      return false;
    } finally {
      _isOpening = false;
      notifyListeners();
    }
  }

  /// Loads remembered folders and which of them are still accessible.
  Future<void> loadRecentFolders() async {
    final store = _recentStore;
    final source = _folderSource;
    if (store == null || source == null || !source.isSupported) return;
    try {
      _recentFolders = await store.load();
      _grantedFolderUris = await source.grantedFolderUris();
      notifyListeners();
    } catch (_) {
      // Recent folders are a convenience; ignore storage failures.
    }
  }

  /// Reopens a remembered folder. Returns whether it opened.
  Future<bool> openRecentFolder(RecentFolder recent) async {
    final source = _folderSource;
    if (source == null || _isOpening) return false;
    _isOpening = true;
    _error = null;
    notifyListeners();
    try {
      _grantedFolderUris = await source.grantedFolderUris();
      if (!_grantedFolderUris.contains(recent.uri)) {
        throw StateError(
          tr('「{name}」需要重新選擇一次，請按「開啟資料夾」再選它。', {'name': recent.name}),
        );
      }
      final folder = await source.openFolderUri(recent.uri, recent.name);
      _setFolder(folder);
      await _remember(folder);
      return true;
    } catch (error) {
      _error = error is StateError ? error.message : error;
      return false;
    } finally {
      _isOpening = false;
      notifyListeners();
    }
  }

  /// Removes a remembered folder and releases its access grant.
  Future<void> forgetFolder(RecentFolder recent) async {
    _recentFolders = [
      for (final item in _recentFolders)
        if (item.uri != recent.uri) item,
    ];
    notifyListeners();
    await _recentStore?.save(_recentFolders);
    if (_folder?.uri != recent.uri) {
      await _folderSource?.releaseFolder(recent.uri);
      _grantedFolderUris = {..._grantedFolderUris}..remove(recent.uri);
    }
  }

  void _setFolder(NoteFolder folder) {
    _folder = folder;
    _fileCache.clear();
    _index = null;
    _indexing = null;
    _indexedCount = 0;
  }

  Future<void> _remember(NoteFolder folder) async {
    _recentFolders = rememberFolder(
      _recentFolders,
      RecentFolder(
        uri: folder.uri,
        name: folder.name,
        openedAt: DateTime.now(),
      ),
    );
    _grantedFolderUris = {..._grantedFolderUris, folder.uri};
    try {
      await _recentStore?.save(_recentFolders);
    } catch (_) {
      // Not critical.
    }
  }

  /* ──────────────── Note index ──────────────── */

  /// Reads every note in the folder once to support backlinks, tags and
  /// search. Notes over the eager-load limit are skipped.
  Future<NoteIndex> ensureIndex() {
    final folder = _folder;
    if (folder == null) return Future.error(StateError(tr('尚未開啟資料夾')));
    if (_index case final index?) return Future.value(index);
    return _indexing ??= _buildIndex(folder);
  }

  Future<NoteIndex> _buildIndex(NoteFolder folder) async {
    final notes = <IndexedNote>[];
    final skipped = <FolderEntry>[];
    _indexedCount = 0;
    notifyListeners();
    for (final entry in folder.notes) {
      if (!identical(_folder, folder)) break;
      final size = entry.size;
      if (size != null && LargeDocumentPolicy.requiresPagedReading(size)) {
        skipped.add(entry);
      } else {
        try {
          final bytes = await _folderSource!.readFile(entry);
          notes.add(
            IndexedNote.fromContent(
              entry,
              utf8.decode(bytes, allowMalformed: true),
              folder,
            ),
          );
        } catch (_) {
          skipped.add(entry);
        }
      }
      _indexedCount++;
      if (_indexedCount % 20 == 0) notifyListeners();
    }
    final index = NoteIndex(notes, skipped: skipped);
    if (identical(_folder, folder)) {
      _index = index;
      notifyListeners();
    }
    return index;
  }

  /// Keeps the index and caches in step after the open note is saved.
  void _updateIndexed(LocalDocument document) {
    final folder = _folder;
    final path = document.folderPath;
    if (folder == null || path == null) return;
    final entry = folder.entryAt(path);
    if (entry == null) return;
    _fileCache.remove(entry.uri);
    final index = _index;
    if (index == null) return;
    _index = NoteIndex([
      for (final note in index.notes)
        note.pathKey == entry.pathKey
            ? IndexedNote.fromContent(entry, document.content, folder)
            : note,
    ], skipped: index.skipped);
  }

  /// Opens a note from the current folder.
  Future<void> openFolderEntry(FolderEntry entry) => _open(() async {
    if (entry.size case final size?
        when LargeDocumentPolicy.requiresPagedReading(size)) {
      throw PagedReadingRequiredException(size);
    }
    final bytes = await _folderSource!.readFile(entry);
    if (LargeDocumentPolicy.requiresPagedReading(bytes.length)) {
      throw PagedReadingRequiredException(bytes.length);
    }
    return LocalDocument.decode(
      name: entry.name,
      bytes: bytes,
      format: LocalDocument.formatForFileName(entry.name),
      sourceUri: entry.uri,
      folderPath: entry.path,
    );
  });

  /* ──────────────── Folder resources ──────────────── */

  /// Resolves a wiki target (`note`, `folder/note.md`, `image.png`) from the
  /// current note, using the same rules as the web reader.
  FolderEntry? resolveWikiTarget(String target, {bool markdown = true}) {
    final folder = _folder;
    final path = _document?.folderPath;
    if (folder == null || path == null) return null;
    return folder.resolve(target, path, markdown: markdown);
  }

  /// Resolves a relative Markdown URL from the current note.
  FolderEntry? resolveRelative(String href) {
    final folder = _folder;
    final path = _document?.folderPath;
    if (folder == null || path == null) return null;
    return folder.resolveRelative(href, path);
  }

  /// Resolves a relative Markdown link or image: the relative path first,
  /// then wiki rules, and finally the bare file name anywhere in the folder
  /// (for paths such as `../image/logo.png` that point outside the folder).
  FolderEntry? resolveLink(String href, {bool markdown = false}) {
    var path = href.split('#').first.split('?').first;
    path = decodePercent(path);
    if (path.isEmpty) return null;
    final name = path.split('/').where((part) => part.isNotEmpty).lastOrNull;
    return resolveRelative(path) ??
        resolveWikiTarget(path, markdown: markdown) ??
        (name == null ? null : resolveWikiTarget(name, markdown: markdown));
  }

  final Map<String, Future<Uint8List>> _fileCache = {};

  /// Reads a folder file (images, embedded notes), caching recent reads.
  Future<Uint8List> readFolderFile(FolderEntry entry) {
    final cached = _fileCache[entry.uri];
    if (cached != null) return cached;
    final future = _folderSource!.readFile(entry);
    _fileCache[entry.uri] = future;
    future.then<void>(
      (_) {},
      onError: (Object _) => _fileCache.remove(entry.uri),
    );
    if (_fileCache.length > 32) _fileCache.remove(_fileCache.keys.first);
    return future;
  }

  Future<void> _open(Future<LocalDocument?> Function() load) async {
    if (_isOpening) return;
    _isOpening = true;
    _error = null;
    notifyListeners();

    try {
      final selected = await load();
      if (selected != null) _document = selected;
    } catch (error) {
      _error = error;
    } finally {
      _isOpening = false;
      notifyListeners();
    }
    final queued = _queuedIncoming;
    if (queued != null) {
      _queuedIncoming = null;
      await openIncoming(queued);
    }
  }
}
