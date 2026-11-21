import 'package:flutter/material.dart';

import '../../core/markdown/note_syntax.dart';
import '../../core/models/note_folder.dart';
import '../../core/notes/note_index.dart';
import '../../core/services/recent_folders.dart';
import '../../features/reader/reader_controller.dart';
import 'folder_tree.dart';
import '../../core/l10n/tr.dart';

/// The "筆記" sheet: folder tree, full-text search, tag filter and recent
/// folders.
class NotesSheet extends StatefulWidget {
  const NotesSheet({
    required this.controller,
    required this.onOpenEntry,
    required this.onOpenDocument,
    required this.onPickFolder,
    required this.onOpenRecent,
    this.initialTag,
    super.key,
  });

  final ReaderController controller;

  /// Opens [entry], optionally scrolling to [heading].
  final void Function(FolderEntry entry, {String heading}) onOpenEntry;
  final VoidCallback onOpenDocument;
  final VoidCallback onPickFolder;
  final ValueChanged<RecentFolder> onOpenRecent;
  final String? initialTag;

  @override
  State<NotesSheet> createState() => _NotesSheetState();
}

class _NotesSheetState extends State<NotesSheet> {
  final _query = TextEditingController();
  late String? _tag = widget.initialTag;
  late bool _showFolders = widget.controller.folder == null;

  ReaderController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _query.addListener(() => setState(() {}));
    if (_tag != null) controller.ensureIndex();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final theme = Theme.of(context);
        final folder = controller.folder;
        final showFolders = _showFolders || folder == null;
        // Shrink above the on-screen keyboard so results stay visible.
        final keyboard = MediaQuery.viewInsetsOf(context).bottom;
        final height = MediaQuery.sizeOf(context).height * 0.85;
        return Padding(
          padding: EdgeInsets.only(bottom: keyboard),
          child: SafeArea(
            child: SizedBox(
              height: (height - keyboard).clamp(240.0, height),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                showFolders ? tr('資料夾') : tr('筆記'),
                                style: theme.textTheme.titleLarge,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                showFolders
                                    ? tr('開啟資料夾，或切換到最近使用的資料夾')
                                    : tr('{name}・{count} 份筆記', {
                                        'name': folder.name,
                                        'count': folder.notes.length,
                                      }),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (folder != null && showFolders)
                          TextButton(
                            onPressed: () =>
                                setState(() => _showFolders = false),
                            child: Text(tr('返回筆記')),
                          ),
                      ],
                    ),
                  ),
                  if (!showFolders) ..._searchBar(context),
                  Expanded(
                    child: showFolders
                        ? _recentFolders(context)
                        : _notesBody(context, folder),
                  ),
                  _actions(context, folder, showFolders),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _searchBar(BuildContext context) {
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: TextField(
          controller: _query,
          textInputAction: TextInputAction.search,
          onTap: controller.ensureIndex,
          onChanged: (_) => controller.ensureIndex(),
          decoration: InputDecoration(
            isDense: true,
            prefixIcon: const Icon(Icons.search),
            hintText: tr('搜尋所有筆記'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(28)),
            suffixIcon: _query.text.isEmpty
                ? null
                : IconButton(
                    tooltip: tr('清除'),
                    onPressed: _query.clear,
                    icon: const Icon(Icons.close),
                  ),
          ),
        ),
      ),
      if (_tag case final tag?)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: InputChip(
              avatar: const Icon(Icons.sell_outlined, size: 18),
              label: Text('#$tag'),
              onDeleted: () => setState(() => _tag = null),
            ),
          ),
        ),
    ];
  }

  Widget _notesBody(BuildContext context, NoteFolder folder) {
    final query = _query.text.trim();
    if (query.isEmpty && _tag == null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: FolderTreeView(
          folder: folder,
          currentPath: controller.document?.folderPath,
          onOpen: (entry) => widget.onOpenEntry(entry),
        ),
      );
    }
    final index = controller.noteIndex;
    if (index == null) {
      controller.ensureIndex();
      return _IndexProgress(
        done: controller.indexedCount,
        total: folder.notes.length,
      );
    }
    if (query.isNotEmpty) {
      var hits = index.search(query);
      if (_tag case final tag?) {
        final tagged = {for (final note in index.withTag(tag)) note.pathKey};
        hits = [
          for (final hit in hits)
            if (tagged.contains(hit.note.pathKey)) hit,
        ];
      }
      return _searchResults(context, hits, index);
    }
    final notes = index.withTag(_tag!);
    if (notes.isEmpty) return _EmptyMessage(tr('沒有使用這個標籤的筆記'));
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      children: [
        for (final note in notes)
          _NoteTile(
            note: note,
            current: _isCurrent(note.entry),
            onTap: () => widget.onOpenEntry(note.entry),
          ),
      ],
    );
  }

  bool _isCurrent(FolderEntry entry) =>
      controller.document?.folderPath?.join('/') == entry.pathKey;

  Widget _searchResults(
    BuildContext context,
    List<SearchHit> hits,
    NoteIndex index,
  ) {
    final theme = Theme.of(context);
    if (hits.isEmpty) return _EmptyMessage(tr('找不到符合的筆記'));
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
          child: Text(
            tr('{count} 份筆記', {'count': hits.length}) +
                (index.skipped.isEmpty
                    ? ''
                    : tr('（{count} 份檔案太大，沒有搜尋）', {
                        'count': index.skipped.length,
                      })),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        for (final hit in hits)
          _NoteTile(
            note: hit.note,
            current: _isCurrent(hit.note.entry),
            snippet: _highlight(context, hit),
            onTap: () => widget.onOpenEntry(
              hit.note.entry,
              heading: _headingBefore(hit),
            ),
          ),
      ],
    );
  }

  /// Nearest heading above the match, so the note opens near it.
  static String _headingBefore(SearchHit hit) {
    if (hit.matchLength == 0) return '';
    final headings = extractHeadings(hit.note.content);
    String heading = '';
    for (final item in headings) {
      if (item.offset > hit.offset) break;
      heading = item.title;
    }
    return heading;
  }

  static TextSpan _highlight(BuildContext context, SearchHit hit) {
    final colors = Theme.of(context).colorScheme;
    final text = hit.snippet;
    final start = hit.matchStart.clamp(0, text.length);
    final end = (hit.matchStart + hit.matchLength).clamp(start, text.length);
    return TextSpan(
      children: [
        TextSpan(text: text.substring(0, start)),
        TextSpan(
          text: text.substring(start, end),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: colors.onPrimaryContainer,
            backgroundColor: colors.primaryContainer,
          ),
        ),
        TextSpan(text: text.substring(end)),
      ],
    );
  }

  Widget _recentFolders(BuildContext context) {
    final theme = Theme.of(context);
    final recents = controller.recentFolders;
    final current = controller.folder?.uri;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      children: [
        // Android 11+ refuses the Download folder and storage roots in the
        // folder picker ("Can't use this folder").
        Container(
          margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  tr(
                    '建議把筆記放在「Documents（文件）」資料夾，可以直接選用。\n「Download（下載）」不能直接選，要點進去，選裡面放筆記的資料夾，再按「使用這個資料夾」。\n只想看一個檔案？按下方的「開啟文件」就好。',
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (recents.isEmpty)
          _EmptyMessage(tr('還沒有開啟過資料夾'))
        else
          for (final recent in recents)
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              selected: recent.uri == current,
              selectedTileColor: theme.colorScheme.secondaryContainer,
              leading: Icon(
                recent.uri == current
                    ? Icons.folder_open
                    : Icons.folder_outlined,
              ),
              title: Text(recent.name),
              subtitle: Text(
                controller.isFolderGranted(recent)
                    ? tr('上次開啟：{date}', {'date': _formatDate(recent.openedAt)})
                    : tr('需要重新選擇一次，請按「開啟資料夾」再選它'),
              ),
              trailing: IconButton(
                tooltip: tr('從清單移除'),
                onPressed: () => controller.forgetFolder(recent),
                icon: const Icon(Icons.close),
              ),
              onTap: recent.uri == current
                  ? () => setState(() => _showFolders = false)
                  : () => widget.onOpenRecent(recent),
            ),
      ],
    );
  }

  static String _formatDate(DateTime time) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${time.year}/${two(time.month)}/${two(time.day)} '
        '${two(time.hour)}:${two(time.minute)}';
  }

  Widget _actions(BuildContext context, NoteFolder? folder, bool showFolders) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: widget.onOpenDocument,
              icon: const Icon(Icons.description_outlined),
              label: Text(tr('開啟文件')),
            ),
          ),
          if (controller.supportsFolders) ...[
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: showFolders
                    ? widget.onPickFolder
                    : () => setState(() => _showFolders = true),
                icon: const Icon(Icons.folder_open_outlined),
                label: Text(showFolders ? tr('開啟資料夾') : tr('切換資料夾')),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NoteTile extends StatelessWidget {
  const _NoteTile({
    required this.note,
    required this.current,
    required this.onTap,
    this.snippet,
  });

  final IndexedNote note;
  final bool current;
  final VoidCallback onTap;
  final TextSpan? snippet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final path = note.entry.path;
    final location = path.length > 1
        ? '${path.sublist(0, path.length - 1).join('/')}/'
        : '';
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      selected: current,
      selectedTileColor: theme.colorScheme.secondaryContainer,
      leading: const Icon(Icons.description_outlined),
      title: Text(note.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '$location${note.entry.name}'),
            if (snippet != null) ...[const TextSpan(text: '\n'), snippet!],
          ],
        ),
        maxLines: snippet == null ? 1 : 3,
        overflow: TextOverflow.ellipsis,
      ),
      isThreeLine: snippet != null,
      onTap: onTap,
    );
  }
}

class _IndexProgress extends StatelessWidget {
  const _IndexProgress({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(value: total == 0 ? null : done / total),
          const SizedBox(height: 12),
          Text(tr('正在讀取所有筆記（{done}／{total}）', {'done': done, 'total': total})),
        ],
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
