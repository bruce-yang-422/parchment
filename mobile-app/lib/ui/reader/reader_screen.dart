import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../core/markdown/frontmatter.dart';
import '../../core/markdown/note_syntax.dart';
import '../../core/markdown/task_markers.dart';
import '../../core/markdown/wiki_paths.dart';
import '../../core/models/local_document.dart';
import '../../core/models/note_folder.dart';
import '../../core/models/reader_preferences.dart';
import '../../core/notes/note_index.dart';
import '../../core/services/incoming_documents.dart';
import '../../core/services/large_document_policy.dart';
import '../../features/reader/reader_controller.dart';
import '../../infrastructure/diagram_render_service.dart';
import '../../platform/platform_profile.dart';
import '../localization/reader_strings.dart';
import '../theme/parchment_theme.dart';
import '../theme/reader_fonts.dart';
import 'about_section.dart';
import 'document_info_sheet.dart';
import 'notes_sheet.dart';
import 'readable_table.dart';
import 'note_markdown.dart';
import '../../core/l10n/tr.dart';

/// While one document replaces another, the old and the new list are both
/// attached for a moment and [ScrollController.position] throws; this
/// returns the newest position instead, or `null` when none is attached.
extension on ScrollController {
  ScrollPosition? get current => positions.isEmpty ? null : positions.last;
}

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({required this.controller, super.key});

  final ReaderController controller;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();

  ReaderController get controller => widget.controller;
  String? _shownError;
  TaskStateStore? _taskStore;
  final GlobalKey _documentKey = GlobalKey();
  StreamSubscription<IncomingDocument>? _incomingSubscription;
  late final NoteResolver _resolver = _FolderResolver(this);
  LocalDocument? _taskStoreDocument;
  bool? _appliedFullscreen;

  /// One task store per document content; saving creates a new document
  /// object, which resets the store to the saved file state.
  TaskStateStore _taskStoreFor(LocalDocument document) {
    if (_taskStore == null || !identical(_taskStoreDocument, document)) {
      _taskStore?.dispose();
      _taskStore = TaskStateStore();
      _taskStoreDocument = document;
    }
    return _taskStore!;
  }

  bool get _hasUnsavedTasks => _taskStore?.hasChanges ?? false;

  /// Asks before an action would drop unsaved task changes.
  Future<bool> _confirmDiscard() async {
    if (!_hasUnsavedTasks) return true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr('放棄未儲存的變更？')),
        content: Text(tr('工作清單的勾選變更尚未儲存，繼續將會捨棄這些變更。')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(tr('取消')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(tr('捨棄變更')),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  Future<void> _openAnotherDocument() async {
    if (await _confirmDiscard()) controller.openDocument();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller.addListener(_onControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncFullscreen());
    final incoming = controller.incomingSource;
    if (incoming != null) {
      _incomingSubscription = incoming.documents.listen(_openIncoming);
      incoming.takeInitial().then((document) {
        if (document != null && mounted) _openIncoming(document);
      });
    }
  }

  /// A file sent from another app ("Open with" / share).
  Future<void> _openIncoming(IncomingDocument incoming) async {
    if (!await _confirmDiscard()) return;
    await controller.openIncoming(incoming);
  }

  @override
  void didUpdateWidget(covariant ReaderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      controller.addListener(_onControllerChanged);
      _appliedFullscreen = null;
      _syncFullscreen();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _appliedFullscreen = null;
      _syncFullscreen();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.removeListener(_onControllerChanged);
    if (_appliedFullscreen == true) {
      unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    }
    _incomingSubscription?.cancel();
    _taskStore?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    _reportOpenError();
    _syncFullscreen();
  }

  void _syncFullscreen() {
    final fullscreen = controller.fullscreen;
    if (_appliedFullscreen == fullscreen) return;
    _appliedFullscreen = fullscreen;
    unawaited(
      SystemChrome.setEnabledSystemUIMode(
        fullscreen ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
      ),
    );
  }

  /// The welcome view shows open errors inline; once a document is open the
  /// error would otherwise be invisible, so surface it as a snack bar.
  void _reportOpenError() {
    final message = controller.errorMessage;
    if (message == _shownError) return;
    _shownError = message;
    if (message == null || controller.document == null || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final profile = PlatformProfile.current();
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final strings = ReaderStrings.forLocale(controller.locale);
        final document = controller.document;
        final taskStore = document == null ? null : _taskStoreFor(document);
        final scaffold = Scaffold(
          appBar: AppBar(title: Text(document?.name ?? 'Parchment')),
          body: Stack(
            children: [
              SafeArea(
                top: false,
                child: document == null
                    ? _WelcomeView(
                        controller: controller,
                        padding: profile.pagePadding,
                        onOpenFolder: _pickFolder,
                      )
                    : _DocumentView(
                        key: _documentKey,
                        document: document,
                        controller: controller,
                        taskStore: taskStore!,
                        resolver:
                            document.folderPath != null &&
                                controller.folder != null
                            ? _resolver
                            : null,
                        loadFolderImage: _loadFolderImage,
                        openRelativeLink: _openRelativeLink,
                        onTagTap:
                            document.folderPath != null &&
                                controller.folder != null
                            ? (tag) => _showNotes(context, tag: tag)
                            : null,
                        padding: profile.readerPadding,
                        scrollController: _scrollController,
                        textScale: controller.textScale,
                        lineHeight: controller.lineHeight,
                        cjkFont: controller.cjkFont,
                        latinFont: controller.latinFont,
                        locale: controller.locale,
                      ),
              ),
              // Floating layers get a fixed size: if one ever fails to
              // build, its error box must not grow over the whole screen
              // and swallow every tap.
              const Positioned(
                left: 0,
                bottom: 0,
                width: 1,
                height: 1,
                child: DiagramRenderHost(),
              ),
              if (document != null)
                Positioned(
                  right: 16,
                  bottom: 16,
                  width: 44,
                  // Room for the button, its lift above the unsaved-tasks
                  // bar and the system navigation inset.
                  height: 44 + 64 + 48,
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: SafeArea(
                      top: false,
                      child: _BackToTopButton(
                        controller: _scrollController,
                        taskStore: taskStore,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          bottomNavigationBar: _ReaderToolbar(
            strings: strings,
            onNotes: () => _showNotes(context),
            onOutline: () => _showOutline(context),
            onRelations: () => _showRelations(context),
            onInfo: () => _showInfo(context),
            onSettings: () => _showSettings(context),
          ),
        );
        if (taskStore == null) return scaffold;
        // Leaving the app with unsaved task changes asks first.
        return ListenableBuilder(
          listenable: taskStore,
          builder: (context, child) => PopScope(
            canPop: !taskStore.hasChanges,
            onPopInvokedWithResult: (didPop, _) async {
              if (didPop) return;
              final navigator = Navigator.of(context);
              if (await _confirmDiscard()) {
                taskStore.discard();
                navigator.maybePop();
              }
            },
            child: child!,
          ),
          child: scaffold,
        );
      },
    );
  }

  void _showNotes(BuildContext context, {String? tag}) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => NotesSheet(
        controller: controller,
        initialTag: tag,
        onOpenEntry: (entry, {heading = ''}) {
          Navigator.pop(sheetContext);
          _openFolderEntry(entry, heading: heading);
        },
        onOpenDocument: () {
          Navigator.pop(sheetContext);
          _openAnotherDocument();
        },
        onPickFolder: () {
          Navigator.pop(sheetContext);
          _pickFolder();
        },
        onOpenRecent: (recent) async {
          Navigator.pop(sheetContext);
          if (await controller.openRecentFolder(recent) && mounted) {
            _showNotes(this.context);
          } else if (mounted && controller.errorMessage != null) {
            _showSnack(controller.errorMessage!);
          }
        },
      ),
    );
  }

  /// Picks a folder, then shows its notes so the user can choose one.
  Future<void> _pickFolder() async {
    if (await controller.openFolder() && mounted) _showNotes(context);
  }

  Future<void> _openFolderEntry(
    FolderEntry entry, {
    String heading = '',
  }) async {
    final current = controller.document;
    final alreadyOpen = current?.folderPath?.join('/') == entry.pathKey;
    if (!alreadyOpen) {
      if (!await _confirmDiscard()) return;
      await controller.openFolderEntry(entry);
    }
    final opened = controller.document;
    if (heading.isEmpty || opened == null) return;
    if (opened.folderPath?.join('/') != entry.pathKey) return;
    _scrollToHeadingText(opened, heading);
  }

  void _scrollToHeadingText(LocalDocument document, String heading) {
    final wanted = headingKey(heading);
    final match = extractHeadings(
      document.content,
    ).where((item) => headingKey(item.title) == wanted).firstOrNull;
    if (match == null) {
      _showSnack(tr('找不到段落「{heading}」', {'heading': heading}));
      return;
    }
    _scrollToHeading(match, document);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Follows a `[[wiki link]]` inside the folder.
  Future<void> _openWiki(WikiTarget target) async {
    final current = controller.document;
    if (current == null) return;
    if (target.target.isEmpty) {
      if (target.heading.isNotEmpty) {
        _scrollToHeadingText(current, target.heading);
      }
      return;
    }
    final entry = controller.resolveWikiTarget(target.target);
    if (entry == null) {
      _showSnack(tr('找不到筆記「{name}」', {'name': target.name}));
      return;
    }
    if (!entry.isNote) {
      _showSnack(
        tr('「{name}」不是 .md 或 .txt 檔案，無法在 Parchment 開啟', {'name': entry.name}),
      );
      return;
    }
    await _openFolderEntry(entry, heading: target.heading);
  }

  /// Follows a relative Markdown link (`[text](other.md#heading)`).
  bool _openRelativeLink(String href) {
    if (controller.folder == null || controller.document?.folderPath == null) {
      return false;
    }
    final hash = href.indexOf('#');
    final path = hash >= 0 ? href.substring(0, hash) : href;
    var heading = hash >= 0 ? href.substring(hash + 1) : '';
    heading = decodePercent(heading);
    final current = controller.document!;
    if (path.isEmpty) {
      if (heading.isNotEmpty) _scrollToHeadingText(current, heading);
      return true;
    }
    final entry = controller.resolveLink(path, markdown: true);
    if (entry == null || !entry.isNote) {
      _showSnack(tr('找不到「{name}」', {'name': path}));
      return true;
    }
    _openFolderEntry(entry, heading: heading);
    return true;
  }

  /// Markdown for an `![[embed]]`, or `null` when it cannot be resolved.
  Future<String?> _loadEmbed(WikiTarget target) async {
    final current = controller.document;
    if (current == null) return null;
    String text;
    if (target.target.isEmpty) {
      text = current.content;
    } else {
      final entry = controller.resolveWikiTarget(target.target);
      if (entry == null || !entry.isNote) return null;
      if (entry.size case final size?
          when LargeDocumentPolicy.requiresPagedReading(size)) {
        throw PagedReadingRequiredException(size);
      }
      final bytes = await controller.readFolderFile(entry);
      text = utf8.decode(bytes, allowMalformed: true);
    }
    return extractNoteSection(
      text,
      heading: target.heading,
      blockId: target.blockId,
    );
  }

  /// Bytes of an image in the folder, or `null` when it cannot be resolved.
  Future<Uint8List>? _loadFolderImage(Uri uri) {
    if (controller.folder == null || controller.document?.folderPath == null) {
      return null;
    }
    FolderEntry? entry;
    if (uri.scheme == 'parchment-wiki') {
      entry = controller.resolveWikiTarget(
        uri.queryParameters['target'] ?? '',
        markdown: false,
      );
    } else if (!uri.hasScheme) {
      final path = uri.toString();
      entry = controller.resolveLink(path);
    }
    if (entry == null) {
      final name = uri.scheme == 'parchment-wiki'
          ? uri.queryParameters['target'] ?? ''
          : decodePercent(uri.path);
      return Future.error(_ImageNotFound(name));
    }
    return controller.readFolderFile(entry);
  }

  void _requireDocument(
    BuildContext context,
    void Function(LocalDocument) action,
  ) {
    final document = controller.document;
    if (document == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr('請先開啟 .md 或 .txt 文件'))));
      return;
    }
    action(document);
  }

  void _showOutline(BuildContext context) {
    _requireDocument(context, (document) {
      final allHeadings = document.format == DocumentFormat.markdown
          ? extractHeadings(document.content)
          : const <NoteHeading>[];
      final headings = allHeadings.length > 1 && allHeadings.first.level == 1
          ? allHeadings.skip(1).toList()
          : allHeadings;
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('目錄'), style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                if (headings.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(tr('這份文件沒有可用的章節標題。')),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: headings.length,
                      itemBuilder: (context, index) {
                        final heading = headings[index];
                        final indent = (heading.level - 2).clamp(0, 4) * 16.0;
                        return ListTile(
                          dense: true,
                          visualDensity: const VisualDensity(vertical: -2),
                          minTileHeight: 44,
                          contentPadding: EdgeInsets.only(
                            left: indent,
                            right: 4,
                          ),
                          leading: Icon(
                            heading.level <= 2
                                ? Icons.article_outlined
                                : Icons.subdirectory_arrow_right,
                            size: 19,
                          ),
                          title: Text(
                            heading.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            Navigator.pop(sheetContext);
                            _scrollToHeading(heading, document);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  /// The Markdown list builds lazily, so its extent is only an estimate.
  /// Jump near the heading, then step towards it using the headings that
  /// are built, and finally align to the rendered heading itself.
  Future<void> _scrollToHeading(
    NoteHeading heading,
    LocalDocument document,
  ) async {
    final headings = extractHeadings(document.content);
    final targetIndex = headings.indexWhere(
      (item) => item.offset == heading.offset,
    );
    final occurrence = headings
        .take(math.max(targetIndex, 0))
        .where((item) => item.title == heading.title)
        .length;
    final ratio = heading.offset / document.content.length.clamp(1, 1 << 30);
    await WidgetsBinding.instance.endOfFrame;
    for (var attempt = 0; attempt < 40; attempt++) {
      if (!mounted) return;
      final position = _scrollController.current;
      if (position == null) return;
      final found = _findHeading(heading.title, occurrence);
      if (found != null && found.mounted) {
        await Scrollable.ensureVisible(
          found,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
        return;
      }
      final built = _builtHeadingIndex(headings, targetIndex);
      double next;
      if (attempt == 0 || built == null || targetIndex < 0) {
        next = position.maxScrollExtent * ratio;
      } else {
        // Step one screen towards the target.
        final step = position.viewportDimension * 0.9;
        next = position.pixels + (targetIndex < built ? -step : step);
      }
      next = next.clamp(0.0, position.maxScrollExtent);
      if (attempt > 0 && (next - position.pixels).abs() < 1) return;
      position.jumpTo(next);
      await WidgetsBinding.instance.endOfFrame;
    }
  }

  /// Rendered heading texts inside the document, in build order.
  List<String> _builtHeadings() {
    final titles = <String>[];
    final minHeadingSize =
        Theme.of(context).textTheme.titleMedium?.fontSize ?? 16;
    void visit(Element element) {
      final widget = element.widget;
      final span = widget is Text ? widget.textSpan : null;
      if (span != null && (span.style?.fontSize ?? 0) >= minHeadingSize) {
        titles.add(span.toPlainText().trim());
      }
      element.visitChildren(visit);
    }

    final root = _documentKey.currentContext;
    if (root is Element) root.visitChildren(visit);
    return titles;
  }

  /// Index in [headings] of a heading that is built now, picking for each
  /// built title the occurrence closest to [targetIndex]; `null` when no
  /// heading is built.
  int? _builtHeadingIndex(List<NoteHeading> headings, int targetIndex) {
    final indexes = <int>[];
    for (final title in _builtHeadings()) {
      int? best;
      for (var i = 0; i < headings.length; i++) {
        if (headings[i].title != title) continue;
        if (best == null ||
            (i - targetIndex).abs() < (best - targetIndex).abs()) {
          best = i;
        }
      }
      if (best != null) indexes.add(best);
    }
    if (indexes.isEmpty) return null;
    indexes.sort();
    return indexes[indexes.length ~/ 2];
  }

  /// Finds the rendered heading text, preferring the [occurrence]-th match
  /// by document order among the currently built blocks.
  BuildContext? _findHeading(String title, int occurrence) {
    final matches = <Element>[];
    final minHeadingSize =
        Theme.of(context).textTheme.titleMedium?.fontSize ?? 16;
    void visit(Element element) {
      final widget = element.widget;
      final span = widget is Text ? widget.textSpan : null;
      if (span != null &&
          span.toPlainText().trim() == title &&
          (span.style?.fontSize ?? 0) >= minHeadingSize) {
        matches.add(element);
      }
      element.visitChildren(visit);
    }

    // Search only the document; the closing outline sheet shows the same
    // titles.
    final root = _documentKey.currentContext;
    if (root == null) return null;
    (root as Element).visitChildren(visit);
    if (matches.isEmpty) return null;
    return matches[occurrence.clamp(0, matches.length - 1)];
  }

  void _showRelations(BuildContext context) {
    _requireDocument(context, (document) {
      final relations = _extractRelations(
        document.content,
        markdown: document.format == DocumentFormat.markdown,
      );
      final folderPath = document.folderPath;
      final inFolder = controller.folder != null && folderPath != null;
      if (inFolder) controller.ensureIndex();
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (sheetContext) => SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(sheetContext).height * 0.62,
            child: ListenableBuilder(
              listenable: controller,
              builder: (sheetContext, _) {
                final theme = Theme.of(sheetContext);
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  children: [
                    Text(tr('關聯'), style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      inFolder
                          ? tr('點標籤可找出相同標籤的筆記，點連結可開啟筆記')
                          : tr('這篇筆記提到的標籤與連結'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _RelationSection(
                      icon: Icons.sell_outlined,
                      title: tr('標籤'),
                      values: [for (final tag in relations.tags) '#$tag'],
                      emptyText: tr('沒有標籤'),
                      onTap: inFolder
                          ? (value) {
                              Navigator.pop(sheetContext);
                              _showNotes(context, tag: value.substring(1));
                            }
                          : null,
                    ),
                    const SizedBox(height: 20),
                    _RelationSection(
                      icon: Icons.link,
                      title: tr('連到的筆記'),
                      values: relations.links,
                      emptyText: tr('沒有連到其他筆記'),
                      onTap: inFolder
                          ? (value) {
                              Navigator.pop(sheetContext);
                              _openRelativeLink(value);
                            }
                          : null,
                    ),
                    const SizedBox(height: 20),
                    if (!inFolder)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.link_off_outlined),
                        title: Text(tr('哪些筆記連到這裡')),
                        subtitle: Text(tr('開啟整個筆記資料夾後，會列出連到這一篇的筆記。')),
                      )
                    else
                      _Backlinks(
                        index: controller.noteIndex,
                        pathKey: folderPath.join('/'),
                        progress: controller.indexedCount,
                        total: controller.folder!.notes.length,
                        onOpen: (note) {
                          Navigator.pop(sheetContext);
                          _openFolderEntry(note.entry);
                        },
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      );
    });
  }

  void _showInfo(BuildContext context) {
    _requireDocument(context, (document) {
      final folder = controller.folder;
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (sheetContext) => DocumentInfoSheet(
          document: document,
          stat: controller.statDocument(),
          canWriteInPlace: controller.canWriteInPlace,
          folderName: document.folderPath != null ? folder?.name : null,
          taskStore: _taskStore,
        ),
      );
    });
  }

  void _showSettings(BuildContext context) {
    // Checked once per opening; a font chosen now shows its sample next time.
    final downloads = ReaderFonts.downloadedGoogleFonts();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final strings = ReaderStrings.forLocale(controller.locale);
          return SafeArea(
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.82,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  Text(
                    strings.readingSettings,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _SettingsGroup(
                    children: [
                      _SettingDropdown<ReaderLocale>(
                        title: strings.interfaceLanguage,
                        value: controller.locale,
                        values: strings.languageNames,
                        onChanged: controller.setLocale,
                      ),
                      // Latin-script interfaces have a single font list.
                      if (!ReaderFonts.isLatinLocale(controller.locale))
                        _SettingDropdown<ReaderCjkFont>(
                          title: strings.cjkFont,
                          preview: (font) => _FontSample(
                            sample: ReaderFonts.cjkSample(controller.locale),
                            fonts: () => ReaderFonts.resolve(
                              latin: ReaderLatinFont.system,
                              cjk: font,
                              locale: controller.locale,
                            ),
                            googleFamily: ReaderFonts.googleFamily(
                              font,
                              controller.locale,
                            ),
                            current: font == controller.cjkFont,
                            downloads: downloads,
                          ),
                          value: controller.cjkFont,
                          // Popular fonts of the interface language first.
                          values: {
                            for (final font in ReaderFonts.cjkChoices(
                              controller.locale,
                              current: controller.cjkFont,
                            ))
                              font: strings.cjkFontNames[font]!,
                          },
                          onChanged: controller.setCjkFont,
                        ),
                      _SettingDropdown<ReaderLatinFont>(
                        title: ReaderFonts.isLatinLocale(controller.locale)
                            ? strings.font
                            : strings.latinFont,
                        preview: (font) => _FontSample(
                          sample: ReaderFonts.latinSample(controller.locale),
                          fonts: () => ReaderFonts.resolve(
                            latin: font,
                            cjk: controller.cjkFont,
                            locale: controller.locale,
                          ),
                          googleFamily: ReaderFonts.googleLatinFamily(font),
                          current: font == controller.latinFont,
                          downloads: downloads,
                        ),
                        value: controller.latinFont,
                        values: {
                          for (final font in ReaderFonts.latinChoices(
                            controller.locale,
                            current: controller.latinFont,
                          ))
                            font: strings.latinFontNames[font]!,
                        },
                        onChanged: controller.setLatinFont,
                      ),
                      _SettingDropdown<ReaderPalette>(
                        title: strings.palette,
                        value: controller.palette,
                        values: strings.paletteNames,
                        onChanged: controller.setPalette,
                      ),
                      _SettingDropdown<ThemeMode>(
                        title: strings.appearance,
                        value: controller.themeMode,
                        values: {
                          ThemeMode.system: strings.themeNames['system']!,
                          ThemeMode.light: strings.themeNames['light']!,
                          ThemeMode.dark: strings.themeNames['dark']!,
                        },
                        onChanged: controller.setThemeMode,
                      ),
                    ],
                  ),
                  ReaderLook.of(context).chrome.groupedSettings
                      ? const SizedBox(height: 20)
                      : const Divider(height: 28),
                  _SettingsGroup(
                    children: [
                      _ReadingSlider(
                        title: strings.textSize,
                        valueLabel: _fontSizeLabel(controller.textScale),
                        value: controller.textScale,
                        min: 0.5,
                        max: 2,
                        divisions: 30,
                        onChanged: controller.setTextScale,
                      ),
                      _ReadingSlider(
                        title: strings.lineSpacing,
                        valueLabel:
                            '${controller.lineHeight.toStringAsFixed(2)}×',
                        value: controller.lineHeight,
                        min: 1.3,
                        max: 2.2,
                        divisions: 9,
                        onChanged: controller.setLineHeight,
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: Text(strings.fullscreen),
                        subtitle: Text(strings.fullscreenHint),
                        value: controller.fullscreen,
                        onChanged: controller.setFullscreen,
                      ),
                    ],
                  ),
                  AboutSection(strings: strings),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _fontSizeLabel(double scale) {
    final points = 16 * scale;
    final text = points == points.roundToDouble()
        ? points.toStringAsFixed(0)
        : points.toStringAsFixed(1);
    return '$text pt · ${scale.toStringAsFixed(2)}×';
  }
}

/// Floating "back to top" button, as on the website's phone layout: shown
/// only when the document is longer than four screens and the reader is
/// more than two screens down.
class _BackToTopButton extends StatelessWidget {
  const _BackToTopButton({required this.controller, this.taskStore});

  final ScrollController controller;

  /// Moves the button above the unsaved-tasks bar while it is shown.
  final TaskStateStore? taskStore;

  static bool _visible(ScrollController controller) {
    final position = controller.current;
    if (position == null) return false;
    if (!position.hasContentDimensions || !position.hasViewportDimension) {
      return false;
    }
    final screen = position.viewportDimension;
    final length = position.maxScrollExtent + screen;
    return length > screen * 4 && position.pixels > screen * 2;
  }

  Future<void> _scrollToTop() async {
    final position = controller.current;
    if (position == null) return;
    // Far away: jump most of the way, so the lazy list does not build every
    // block on the way up.
    final screen = position.viewportDimension;
    if (position.pixels > screen * 6) position.jumpTo(screen * 2);
    await position.animateTo(
      0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final look = ReaderLook.of(context);
    final colors = Theme.of(context).colorScheme;
    final shape = look.chrome.controlRadius == null
        ? const CircleBorder()
        : RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(look.chrome.controlRadius! + 4),
          );
    return ListenableBuilder(
      listenable: Listenable.merge([controller, ?taskStore]),
      builder: (context, _) {
        final visible = _visible(controller);
        final lift = (taskStore?.hasChanges ?? false) ? 64.0 : 0.0;
        return AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.only(bottom: lift),
          child: IgnorePointer(
            ignoring: !visible,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: visible ? 1 : 0,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 180),
                scale: visible ? 1 : 0.8,
                child: Tooltip(
                  message: tr('回到頂端'),
                  child: Material(
                    color: colors.surfaceContainerLow,
                    elevation: 3,
                    shadowColor: Colors.black.withValues(alpha: 0.3),
                    shape: shape.copyWith(
                      side: BorderSide(color: look.border, width: 0.5),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: _scrollToTop,
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(
                          Icons.arrow_upward_rounded,
                          color: colors.primary,
                          semanticLabel: tr('回到頂端'),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Settings rows. iOS and Windows 11 palettes show them as a rounded
/// grouped list; the others as a plain list.
class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final look = ReaderLook.of(context);
    if (!look.chrome.groupedSettings) return Column(children: children);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: dark
            ? Color.lerp(look.surface, Colors.white, 0.07)
            : Colors.white,
        borderRadius: BorderRadius.circular(look.chrome.panelRadius),
        border: look.chrome.panelRadius < 10
            ? Border.all(color: look.border)
            : null,
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, color: look.border),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _ReaderToolbar extends StatelessWidget {
  const _ReaderToolbar({
    required this.strings,
    required this.onNotes,
    required this.onOutline,
    required this.onRelations,
    required this.onInfo,
    required this.onSettings,
  });

  final ReaderStrings strings;

  final VoidCallback onNotes;
  final VoidCallback onOutline;
  final VoidCallback onRelations;
  final VoidCallback onInfo;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.96),
        border: Border(
          top: BorderSide(color: colors.outlineVariant, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 70,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 5, 8, 4),
            child: Row(
              children: [
                _ToolbarButton(
                  icon: Icons.account_tree_outlined,
                  label: strings.notes,
                  onTap: onNotes,
                ),
                _ToolbarButton(
                  icon: Icons.hub_outlined,
                  label: strings.relations,
                  onTap: onRelations,
                ),
                _ToolbarButton(
                  icon: Icons.format_list_bulleted_rounded,
                  label: strings.outline,
                  onTap: onOutline,
                ),
                _ToolbarButton(
                  icon: Icons.info_outline_rounded,
                  label: strings.info,
                  onTap: onInfo,
                ),
                _ToolbarButton(
                  icon: Icons.settings_outlined,
                  label: strings.settings,
                  onTap: onSettings,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadingSlider extends StatelessWidget {
  const _ReadingSlider({
    required this.title,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String title;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              Text(
                valueLabel,
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: valueLabel,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _Backlinks extends StatelessWidget {
  const _Backlinks({
    required this.index,
    required this.pathKey,
    required this.progress,
    required this.total,
    required this.onOpen,
  });

  final NoteIndex? index;
  final String pathKey;
  final int progress;
  final int total;
  final ValueChanged<IndexedNote> onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final index = this.index;
    final notes = index?.backlinks(pathKey) ?? const <IndexedNote>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.call_received, size: 20),
            const SizedBox(width: 8),
            Text(tr('哪些筆記連到這裡'), style: theme.textTheme.titleMedium),
            if (index != null) ...[
              const SizedBox(width: 6),
              Text(
                '${notes.length}',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        if (index == null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: total == 0 ? null : progress / total,
                ),
                const SizedBox(height: 6),
                Text(
                  tr('正在讀取所有筆記（{done}／{total}）', {
                    'done': progress,
                    'total': total,
                  }),
                ),
              ],
            ),
          )
        else if (notes.isEmpty)
          Text(
            tr('沒有其他筆記連到這裡'),
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          )
        else
          for (final note in notes)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.description_outlined),
              title: Text(note.title),
              subtitle: Text(note.pathKey),
              onTap: () => onOpen(note),
            ),
      ],
    );
  }
}

class _RelationSection extends StatelessWidget {
  const _RelationSection({
    required this.icon,
    required this.title,
    required this.values,
    required this.emptyText,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final List<String> values;
  final String emptyText;
  final ValueChanged<String>? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 10),
        if (values.isEmpty)
          Text(
            emptyText,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final value in values)
                if (onTap case final onTap?)
                  ActionChip(label: Text(value), onPressed: () => onTap(value))
                else
                  Chip(label: Text(value)),
            ],
          ),
      ],
    );
  }
}

/// One line of sample text in a font, under its name in the font list.
/// Google Fonts that are not on the phone yet show a download mark
/// instead, so opening the list never downloads anything.
class _FontSample extends StatelessWidget {
  const _FontSample({
    required this.sample,
    required this.fonts,
    required this.googleFamily,
    required this.current,
    required this.downloads,
  });

  final String sample;

  /// Resolved only when the sample is shown: asking google_fonts for a
  /// family starts its download.
  final ({String? family, List<String> fallback}) Function() fonts;

  /// Google Fonts name, or `null` for system and bundled fonts.
  final String? googleFamily;

  /// The chosen font is in use already, so its sample is always shown.
  final bool current;
  final Future<Set<String>> downloads;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyLarge?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      height: 1.5,
    );
    final family = googleFamily;
    if (family == null || current) return _line(style);
    return FutureBuilder<Set<String>>(
      future: downloads,
      builder: (context, snapshot) {
        final downloaded = snapshot.data;
        if (downloaded == null) return const SizedBox(height: 24);
        if (ReaderFonts.isDownloaded(family, downloaded)) return _line(style);
        return Align(
          alignment: Alignment.centerLeft,
          child: Icon(
            Icons.cloud_download_outlined,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
            semanticLabel: tr('選擇後下載'),
          ),
        );
      },
    );
  }

  /// Built only when the font is bundled or already downloaded, so the
  /// style never starts a download.
  Widget _line(TextStyle? style) {
    final resolved = fonts();
    return Text(
      sample,
      maxLines: 1,
      overflow: TextOverflow.fade,
      softWrap: false,
      style: style?.copyWith(
        fontFamily: resolved.family,
        fontFamilyFallback: resolved.fallback,
      ),
    );
  }
}

class _SettingDropdown<T extends Enum> extends StatelessWidget {
  const _SettingDropdown({
    required this.title,
    required this.value,
    required this.values,
    required this.onChanged,
    this.preview,
  });

  final String title;
  final T value;
  final Map<T, String> values;
  final ValueChanged<T> onChanged;

  /// Shown under each choice, e.g. a sample line in that font, so the
  /// difference between choices is visible before picking.
  final Widget? Function(T choice)? preview;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(
              values[value]!,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 20),
        ],
      ),
      onTap: () => _showChoices(context),
    );
  }

  void _showChoices(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.78,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              ...values.entries.map(
                (entry) => ListTile(
                  title: Text(entry.value),
                  subtitle: preview?.call(entry.key),
                  trailing: entry.key == value
                      ? Icon(
                          Icons.check,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                  onTap: () {
                    onChanged(entry.key);
                    Navigator.pop(sheetContext);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatefulWidget {
  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_ToolbarButton> createState() => _ToolbarButtonState();
}

class _ToolbarButtonState extends State<_ToolbarButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final emphasized = _hovered || _pressed;
    return Expanded(
      child: Semantics(
        button: true,
        label: widget.label,
        child: AnimatedScale(
          scale: _pressed ? 0.95 : 1,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            splashFactory: NoSplash.splashFactory,
            hoverColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onHover: (value) => setState(() => _hovered = value),
            onHighlightChanged: (value) => setState(() => _pressed = value),
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: emphasized
                    ? colors.primaryContainer.withValues(alpha: 0.55)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.icon,
                    size: 22,
                    color: emphasized
                        ? colors.primary
                        : colors.onSurfaceVariant,
                    opticalSize: 22,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: emphasized
                          ? colors.primary
                          : colors.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.1,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// First screen: two actions, with how-to help folded away. Covers files
/// someone sent (usually in LINE) and notes edited on a computer.
class _WelcomeView extends StatelessWidget {
  const _WelcomeView({
    required this.controller,
    required this.padding,
    required this.onOpenFolder,
  });

  final ReaderController controller;
  final EdgeInsets padding;
  final VoidCallback onOpenFolder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final errorMessage = controller.errorMessage;
    final busy = controller.isOpening;
    return Center(
      child: SingleChildScrollView(
        padding: padding.add(const EdgeInsets.symmetric(vertical: 24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.auto_stories_outlined,
                size: 64,
                color: colors.primary,
              ),
              const SizedBox(height: 20),
              Text(
                tr('在手機上閱讀 .md 文件'),
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tr('打開就是排好版的文件'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),
              Center(
                child: FilledButton.icon(
                  onPressed: busy ? null : controller.openDocument,
                  icon: busy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.file_open_outlined),
                  label: Text(tr('開啟檔案')),
                ),
              ),
              if (controller.supportsFolders) ...[
                const SizedBox(height: 12),
                Center(
                  child: OutlinedButton.icon(
                    onPressed: busy ? null : onOpenFolder,
                    icon: const Icon(Icons.folder_open_outlined),
                    label: Text(tr('開啟筆記資料夾')),
                  ),
                ),
              ],
              if (errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  errorMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.error),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 15,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      tr('檔案只在這支手機上開啟，不會上傳'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _WelcomeTip(
                icon: Icons.help_outline,
                title: tr('怎麼使用？'),
                body: tr(
                  '收到 LINE 傳來的 .md 檔：點一下檔案，選「用其他應用程式開啟」或「分享」，再選 Parchment。\n\n在電腦編輯的筆記：把筆記資料夾同步到手機（例如 Syncthing、FolderSync），再按「開啟筆記資料夾」，筆記之間的連結、圖片和搜尋都能使用。\n\nMarkdown 是一種輕量級標記語言，透過簡單符號排版純文字，例如用 # 建立標題、** 標示粗體、- 製作清單。它易學、易讀，並可轉換成 HTML 等格式，廣泛應用於技術文件、筆記、README 與網頁內容。',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Collapsible help card on the welcome screen.
class _WelcomeTip extends StatelessWidget {
  const _WelcomeTip({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: colors.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(icon, color: colors.primary),
          title: Text(title, style: theme.textTheme.titleSmall),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentView extends StatefulWidget {
  const _DocumentView({
    required this.document,
    super.key,
    required this.controller,
    required this.taskStore,
    required this.resolver,
    required this.loadFolderImage,
    required this.openRelativeLink,
    required this.onTagTap,
    required this.padding,
    required this.scrollController,
    required this.textScale,
    required this.lineHeight,
    required this.cjkFont,
    required this.locale,
    required this.latinFont,
  });

  final LocalDocument document;
  final ReaderController controller;
  final TaskStateStore taskStore;
  final NoteResolver? resolver;
  final Future<Uint8List>? Function(Uri uri) loadFolderImage;
  final bool Function(String href) openRelativeLink;
  final ValueChanged<String>? onTagTap;
  final EdgeInsets padding;
  final ScrollController scrollController;
  final double textScale;
  final double lineHeight;
  final ReaderCjkFont cjkFont;
  final ReaderLatinFont latinFont;

  /// Picks the regional Noto variant (TC, SC, JP, KR).
  final ReaderLocale locale;

  @override
  State<_DocumentView> createState() => _DocumentViewState();
}

class _DocumentViewState extends State<_DocumentView> {
  PreparedNote? _note;
  LocalDocument? _preparedFor;

  bool _saving = false;

  PreparedNote get _preparedNote {
    if (_note == null || !identical(_preparedFor, widget.document)) {
      _note = PreparedNote.prepare(widget.document.content);
      _preparedFor = widget.document;
    }
    return _note!;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _handleLink(NoteMarkdownConfig config, String? text, String? href) {
    if (href == null || href.isEmpty) return;
    if (href.startsWith('#fn-')) {
      _showFootnote(
        config,
        href.substring(4),
        number: text?.trim().isNotEmpty == true ? text!.trim() : null,
      );
      return;
    }
    if (href.startsWith('#fnref-')) {
      unawaited(config.scrollToFootnoteReference(href.substring(1)));
      return;
    }
    final uri = Uri.tryParse(href);
    if (uri != null && uri.hasScheme) {
      Clipboard.setData(ClipboardData(text: href));
      _showMessage(tr('已複製連結：{href}', {'href': href}));
      return;
    }
    if (widget.openRelativeLink(href)) return;
    _showMessage(tr('這個連結指向其他檔案，要先開啟整個筆記資料夾才能跳過去'));
  }

  void _showFootnote(
    NoteMarkdownConfig config,
    String label, {
    String? number,
  }) {
    final content = config.note.footnoteFor(label);
    if (content == null) return;
    // Same width for every footnote (96% of the screen), however short or
    // long its text; the sheet would otherwise shrink to fit the content.
    final width = MediaQuery.sizeOf(context).width * 0.96;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      constraints: BoxConstraints.tightFor(width: width),
      builder: (sheetContext) => NoteMarkdownScope(
        config: config,
        child: SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: width,
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.6,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    number == null
                        ? tr('註腳')
                        : tr('註腳 {number}', {'number': number}),
                    style: Theme.of(sheetContext).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  MediaQuery(
                    data: MediaQuery.of(
                      sheetContext,
                    ).copyWith(textScaler: TextScaler.noScaling),
                    child: config.body(content),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool get _usesChosenFont =>
      widget.latinFont != ReaderLatinFont.system ||
      widget.cjkFont != ReaderCjkFont.system;

  /// Markdown styles for the current palette (see [ReaderLook]).
  MarkdownStyleSheet _styleSheet(
    ThemeData theme,
    ReaderLook look,
    TextStyle? bodyStyle,
  ) {
    final size = bodyStyle?.fontSize ?? 16;
    TextStyle? heading(double scale, Color color) => bodyStyle?.copyWith(
      fontSize: size * scale,
      height: 1.3,
      color: color,
      // The palette's heading font (parchment serif) only applies while the
      // reader keeps the system fonts; a chosen font is used throughout.
      fontFamily: _usesChosenFont
          ? bodyStyle.fontFamily
          : look.chrome.headingFamily ?? bodyStyle.fontFamily,
      fontWeight: look.headingWeight,
      letterSpacing: size * scale * look.headingLetterSpacing,
    );
    final radius = BorderRadius.circular(look.radius);
    final borderSide = BorderSide(color: look.border);
    final (quoteDecoration, quotePadding) = switch (look.quote) {
      QuoteLook.line => (
        BoxDecoration(
          border: Border(
            left: BorderSide(
              color: look.quoteBorder,
              width: look.chrome.quoteWidth,
            ),
          ),
        ),
        const EdgeInsets.fromLTRB(14, 2, 0, 2),
      ),
      QuoteLook.tinted => (
        BoxDecoration(
          color: look.quoteBackground,
          borderRadius: radius,
          border: Border(
            left: BorderSide(
              color: look.quoteBorder,
              width: look.chrome.quoteWidth,
            ),
          ),
        ),
        const EdgeInsets.fromLTRB(14, 10, 12, 10),
      ),
      QuoteLook.card => (
        BoxDecoration(
          color: look.quoteBackground,
          borderRadius: radius,
          border: Border(
            left: BorderSide(
              color: look.quoteBorder,
              width: look.chrome.quoteWidth,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        const EdgeInsets.fromLTRB(14, 10, 12, 10),
      ),
    };
    final (tableBorder, headDecoration, cellDecoration) = switch (look.table) {
      TableLook.grid => (
        TableBorder.all(color: look.border),
        look.chrome.tableHeaderTint ? BoxDecoration(color: look.surface) : null,
        null,
      ),
      TableLook.lines => (
        TableBorder(horizontalInside: borderSide, bottom: borderSide),
        null,
        null,
      ),
      TableLook.card => (
        TableBorder(
          top: borderSide,
          bottom: borderSide,
          left: borderSide,
          right: borderSide,
          horizontalInside: borderSide,
          borderRadius: radius,
        ),
        BoxDecoration(color: look.cardBackground),
        BoxDecoration(color: look.cardBackground),
      ),
    };
    return MarkdownStyleSheet.fromTheme(theme).copyWith(
      p: bodyStyle,
      listBullet: bodyStyle,
      h1: heading(look.headingScale[0], look.heading1),
      h2: heading(look.headingScale[1], look.heading2),
      h3: heading(look.headingScale[2], look.text),
      h4: heading(1.1, look.text),
      h5: heading(1, look.text),
      h6: heading(1, look.muted),
      blockSpacing: look.blockSpacing,
      tableBody: bodyStyle?.copyWith(height: 1.5),
      tableHead: bodyStyle?.copyWith(
        height: 1.5,
        fontWeight: FontWeight.w600,
        color: look.minimal ? look.muted : look.text,
      ),
      code: theme.textTheme.bodyMedium?.copyWith(
        fontFamily: 'monospace',
        fontSize: size * 0.88,
        color: look.inlineCode,
        backgroundColor: look.codeBackground,
      ),
      a: TextStyle(
        color: look.chrome.mutedUnderline ? look.text : look.link,
        decoration: look.chrome.linkUnderline
            ? TextDecoration.underline
            : TextDecoration.none,
        decorationColor: look.chrome.mutedUnderline
            ? look.muted.withValues(alpha: 0.5)
            : look.link.withValues(alpha: 0.4),
      ),
      blockquote: look.minimal
          ? bodyStyle?.copyWith(fontSize: size * 1.1)
          : bodyStyle,
      // Tables decide between fitting the screen and scrolling sideways.
      tableColumnWidth: ReadableColumnWidth(
        availableWidth:
            MediaQuery.sizeOf(context).width - widget.padding.horizontal,
      ),
      tableScrollbarThumbVisibility: true,
      tableCellsPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      tableBorder: tableBorder,
      tableHeadCellsDecoration: headDecoration,
      tableCellsDecoration: cellDecoration,
      blockquoteDecoration: quoteDecoration,
      blockquotePadding: quotePadding,
      horizontalRuleDecoration: BoxDecoration(
        border: Border(top: BorderSide(color: look.border, width: 1)),
      ),
    );
  }

  NoteMarkdownConfig? _config;
  Object? _configKey;

  /// The Markdown widget re-parses and rebuilds the whole document whenever
  /// its style sheet or the [NoteMarkdownScope] config is a new object. The
  /// screen rebuilds often (opening state, folder indexing, system bars), so
  /// the config is only replaced when something that affects the rendering
  /// really changed. Without this, long documents re-rendered from scratch
  /// several times while opening and while reading.
  NoteMarkdownConfig _configFor(
    BuildContext context,
    ThemeData theme,
    ReaderLook look,
    TextStyle? bodyStyle,
  ) {
    final key = (
      _preparedNote,
      theme,
      look,
      bodyStyle,
      _usesChosenFont,
      MediaQuery.sizeOf(context).width - widget.padding.horizontal,
      widget.resolver,
      widget.taskStore,
      widget.onTagTap != null,
    );
    final cached = _config;
    if (cached != null && _configKey == key) return cached;
    late final NoteMarkdownConfig config;
    config = NoteMarkdownConfig(
      note: _preparedNote,
      styleSheet: _styleSheet(theme, look, bodyStyle),
      onTapLink: (text, href, title) => _handleLink(config, text, href),
      imageBuilder: (uri, title, alt) => _ZoomableMarkdownImage(
        uri: uri,
        semanticLabel: alt ?? title,
        loadFolderImage: widget.loadFolderImage,
      ),
      showMessage: _showMessage,
      resolver: widget.resolver,
      onTagTap: widget.onTagTap == null
          ? null
          : (tag) => widget.onTagTap?.call(tag),
      taskStates: widget.taskStore,
    );
    _configKey = key;
    return _config = config;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fonts = ReaderFonts.resolve(
      latin: widget.latinFont,
      cjk: widget.cjkFont,
      locale: widget.locale,
    );
    final look = ReaderLook.of(context);
    // Keep the reader size absolute and predictable across devices. App
    // chrome still follows the operating-system accessibility scale; only
    // document typography uses the explicit 8–32 pt reader setting.
    final bodyStyle = theme.textTheme.bodyLarge?.copyWith(
      fontSize: 16 * widget.textScale,
      height: widget.lineHeight,
      fontFamily: fonts.family,
      fontFamilyFallback: fonts.fallback,
    );
    final mediaQuery = MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.noScaling);
    if (widget.document.format == DocumentFormat.plainText) {
      return MediaQuery(
        data: mediaQuery,
        child: SingleChildScrollView(
          key: ValueKey(widget.document.id),
          controller: widget.scrollController,
          padding: widget.padding,
          child: SelectionArea(
            child: Text(widget.document.content, style: bodyStyle),
          ),
        ),
      );
    }

    final config = _configFor(context, theme, look, bodyStyle);

    return MediaQuery(
      data: mediaQuery,
      child: NoteMarkdownScope(
        config: config,
        child: Column(
          children: [
            Expanded(
              // Keyed by document so a selection never carries over to
              // the next document.
              child: SelectionArea(
                key: ValueKey(widget.document.id),
                child: config.document(
                  controller: widget.scrollController,
                  // Room below the last line for the floating back-to-top
                  // button, so it never covers the end of the document.
                  padding: widget.padding.copyWith(
                    bottom: widget.padding.bottom + 64,
                  ),
                ),
              ),
            ),
            ListenableBuilder(
              listenable: widget.taskStore,
              builder: (context, _) {
                final count = widget.taskStore.changes.length;
                return AnimatedSize(
                  duration: const Duration(milliseconds: 180),
                  child: count == 0
                      ? const SizedBox(width: double.infinity)
                      : _UnsavedTasksBar(
                          count: count,
                          saving: _saving,
                          onDiscard: widget.taskStore.discard,
                          onSave: _chooseSave,
                        ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Applies the unsaved toggles to the source text, touching only the
  /// checkbox characters.
  String? _contentWithChanges() {
    try {
      return applyTaskChanges(
        widget.document.content,
        widget.taskStore.changes,
        expectedTaskCount: widget.taskStore.taskCount,
      );
    } on TaskMarkerMismatchException catch (error) {
      _showMessage('$error');
      return null;
    }
  }

  Future<void> _chooseSave() async {
    final controller = widget.controller;
    final count = widget.taskStore.changes.length;
    final choice = await showModalBottomSheet<_SaveChoice>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  child: Text(tr('儲存勾選'), style: theme.textTheme.titleLarge),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text(
                    tr('只會更新 {count} 個打勾項目，文件的其他內容完全不變。', {'count': count}),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                ListTile(
                  enabled: controller.canWriteInPlace,
                  leading: const Icon(Icons.save_outlined),
                  title: Text(tr('存回原本的檔案')),
                  subtitle: Text(
                    controller.canWriteInPlace
                        ? widget.document.name
                        : _inPlaceUnavailableReason(),
                  ),
                  onTap: () => Navigator.pop(sheetContext, _SaveChoice.inPlace),
                ),
                ListTile(
                  enabled: controller.canSaveAs,
                  leading: const Icon(Icons.save_as_outlined),
                  title: Text(tr('另存新檔…')),
                  subtitle: Text(tr('原本的檔案不會改變')),
                  onTap: () => Navigator.pop(sheetContext, _SaveChoice.saveAs),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (choice == null || !mounted) return;
    final content = _contentWithChanges();
    if (content == null) return;

    setState(() => _saving = true);
    try {
      switch (choice) {
        case _SaveChoice.inPlace:
          await controller.writeInPlace(content);
          _showMessage(tr('已儲存到「{name}」', {'name': widget.document.name}));
        case _SaveChoice.saveAs:
          if (await controller.saveAs(content)) {
            _showMessage(tr('已另存新檔，原本的檔案沒有改變'));
          }
      }
    } catch (error) {
      _showMessage(tr('儲存失敗：{error}', {'error': error}));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _inPlaceUnavailableReason() {
    if (!widget.document.lossless) return tr('這個檔案有特殊字元，為了避免損壞只能另存新檔');
    if (widget.document.sourceUri == null) {
      return Platform.isIOS
          ? tr('iPhone 開啟的是檔案副本，請用「另存新檔」')
          : tr('沒有被允許修改這個檔案，請用「另存新檔」');
    }
    return tr('目前無法存回');
  }
}

enum _SaveChoice { inPlace, saveAs }

class _UnsavedTasksBar extends StatelessWidget {
  const _UnsavedTasksBar({
    required this.count,
    required this.saving,
    required this.onDiscard,
    required this.onSave,
  });

  final int count;
  final bool saving;
  final VoidCallback onDiscard;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
        child: Row(
          children: [
            Icon(
              Icons.edit_note,
              color: theme.colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                tr('有 {count} 個勾選還沒儲存', {'count': count}),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
            TextButton(
              onPressed: saving ? null : onDiscard,
              child: Text(tr('捨棄')),
            ),
            const SizedBox(width: 4),
            FilledButton(
              onPressed: saving ? null : onSave,
              child: saving
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(tr('儲存')),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageNotFound implements Exception {
  const _ImageNotFound(this.name);

  final String name;
}

class _FolderResolver implements NoteResolver {
  _FolderResolver(this._state);

  final _ReaderScreenState _state;

  @override
  void openWiki(WikiTarget target) => _state._openWiki(target);

  @override
  Future<String?> loadEmbed(WikiTarget target) => _state._loadEmbed(target);
}

/// Markdown image: remote, `data:`, or a file inside the opened folder
/// (relative path or `![[image.png|width]]`). Tap to zoom.
class _ZoomableMarkdownImage extends StatefulWidget {
  const _ZoomableMarkdownImage({
    required this.uri,
    required this.loadFolderImage,
    this.semanticLabel,
  });

  final Uri uri;
  final String? semanticLabel;
  final Future<Uint8List>? Function(Uri uri) loadFolderImage;

  @override
  State<_ZoomableMarkdownImage> createState() => _ZoomableMarkdownImageState();
}

class _ZoomableMarkdownImageState extends State<_ZoomableMarkdownImage> {
  Future<Uint8List>? _folderBytes;
  bool _isFolderImage = false;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant _ZoomableMarkdownImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uri != widget.uri) _resolve();
  }

  void _resolve() {
    final uri = widget.uri;
    _isFolderImage = uri.scheme == 'parchment-wiki' || !uri.hasScheme;
    _folderBytes = _isFolderImage ? widget.loadFolderImage(uri) : null;
  }

  double? _dimension(String name) =>
      double.tryParse(widget.uri.queryParameters[name] ?? '');

  @override
  Widget build(BuildContext context) {
    final uri = widget.uri;
    if (_isFolderImage) {
      final bytes = _folderBytes;
      if (bytes == null) {
        return _ImageUnavailable(
          message: uri.scheme == 'parchment-wiki'
              ? tr('找不到圖片「{name}」', {'name': uri.queryParameters['target']})
              : tr('開啟整個筆記資料夾後，這張圖片才會顯示'),
        );
      }
      return FutureBuilder<Uint8List>(
        future: bytes,
        builder: (context, snapshot) {
          if (snapshot.error case final _ImageNotFound missing) {
            return _ImageUnavailable(
              message: tr('找不到圖片「{name}」', {'name': missing.name}),
            );
          }
          if (snapshot.hasError) {
            return _ImageUnavailable(message: tr('圖片無法顯示'));
          }
          final data = snapshot.data;
          if (data == null) {
            return const SizedBox(
              height: 48,
              child: Center(child: LinearProgressIndicator()),
            );
          }
          return _zoomable(context, MemoryImage(data));
        },
      );
    }
    if (uri.scheme == 'http' || uri.scheme == 'https') {
      return _zoomable(context, NetworkImage(uri.toString()));
    }
    if (uri.scheme == 'data' &&
        uri.data?.mimeType.startsWith('image/') == true) {
      return _zoomable(context, MemoryImage(uri.data!.contentAsBytes()));
    }
    return _ImageUnavailable(message: tr('圖片無法顯示'));
  }

  Widget _zoomable(BuildContext context, ImageProvider<Object> provider) {
    final width = _dimension('width');
    final height = _dimension('height');
    final image = Image(
      image: provider,
      width: width,
      height: height,
      fit: BoxFit.contain,
      semanticLabel: widget.semanticLabel,
      errorBuilder: (context, error, stackTrace) =>
          _ImageUnavailable(message: tr('圖片無法顯示')),
    );
    final label = widget.semanticLabel;
    return Semantics(
      button: true,
      label: label == null ? tr('開啟圖片') : tr('開啟圖片：{label}', {'label': label}),
      child: GestureDetector(
        onTap: () => _showImageLightbox(context, provider),
        child: Align(
          alignment: Alignment.centerLeft,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: image,
          ),
        ),
      ),
    );
  }

  void _showImageLightbox(
    BuildContext context,
    ImageProvider<Object> provider,
  ) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.94),
      builder: (dialogContext) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 8,
                child: Center(
                  child: Image(image: provider, fit: BoxFit.contain),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: SafeArea(
                child: IconButton.filled(
                  tooltip: tr('關閉'),
                  onPressed: () => Navigator.pop(dialogContext),
                  icon: const Icon(Icons.close),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageUnavailable extends StatelessWidget {
  const _ImageUnavailable({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.broken_image_outlined),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _DocumentRelations {
  const _DocumentRelations({required this.tags, required this.links});

  final List<String> tags;
  final List<String> links;
}

_DocumentRelations _extractRelations(String source, {required bool markdown}) {
  final frontmatter = markdown ? Frontmatter.parse(source) : null;
  final content = markdown ? stripFencedCode(frontmatter!.body) : source;
  final tags = markdown ? noteTags(source) : const <String>[];
  final wikiLinks = RegExp(
    r'(?<!!)\[\[([^\]|#]+)(?:#[^\]|]+)?(?:\|[^\]]+)?\]\]',
  ).allMatches(content).map((match) => match.group(1)!.trim());
  final markdownLinks = RegExp(
    r'(?<!!)\[[^\]]+\]\(([^)]+\.(?:md|txt))(?:#[^)]*)?\)',
    caseSensitive: false,
  ).allMatches(content).map((match) => match.group(1)!.trim());
  final links = {...wikiLinks, ...markdownLinks}.toList();
  tags.sort();
  links.sort();
  return _DocumentRelations(tags: tags, links: links);
}
