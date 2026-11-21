import 'package:flutter/material.dart';

import '../../core/models/note_folder.dart';
import '../../core/l10n/tr.dart';

/// Expandable tree of the `.md` / `.txt` notes in a folder. Folders come
/// first; names sort naturally (`2` before `10`).
class FolderTreeView extends StatefulWidget {
  const FolderTreeView({
    required this.folder,
    required this.currentPath,
    required this.onOpen,
    super.key,
  });

  final NoteFolder folder;
  final List<String>? currentPath;
  final ValueChanged<FolderEntry> onOpen;

  @override
  State<FolderTreeView> createState() => _FolderTreeViewState();
}

class _FolderTreeViewState extends State<FolderTreeView> {
  late _TreeNode _root = _TreeNode.build(widget.folder);
  final Set<String> _expanded = {};

  @override
  void initState() {
    super.initState();
    _expandToCurrent();
  }

  @override
  void didUpdateWidget(covariant FolderTreeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.folder, widget.folder)) {
      _root = _TreeNode.build(widget.folder);
      _expanded.clear();
      _expandToCurrent();
    }
  }

  void _expandToCurrent() {
    final path = widget.currentPath;
    if (path == null) return;
    for (var i = 1; i < path.length; i++) {
      _expanded.add(path.sublist(0, i).join('/'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    void add(_TreeNode node, int depth) {
      for (final child in node.children) {
        final key = child.pathKey;
        if (child.entry == null) {
          final open = _expanded.contains(key);
          rows.add(
            _TreeRow(
              depth: depth,
              icon: open ? Icons.folder_open_outlined : Icons.folder_outlined,
              label: child.name,
              trailing: Icon(open ? Icons.expand_less : Icons.expand_more),
              onTap: () => setState(() {
                if (!_expanded.remove(key)) _expanded.add(key);
              }),
            ),
          );
          if (open) add(child, depth + 1);
        } else {
          final current = widget.currentPath?.join('/') == key;
          rows.add(
            _TreeRow(
              depth: depth,
              icon: child.name.toLowerCase().endsWith('.md')
                  ? Icons.description_outlined
                  : Icons.article_outlined,
              label: child.name,
              selected: current,
              onTap: () => widget.onOpen(child.entry!),
            ),
          );
        }
      }
    }

    add(_root, 0);
    if (rows.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: Text(tr('這個資料夾沒有 .md 或 .txt 檔案'))),
      );
    }
    return Column(children: rows);
  }
}

class _TreeRow extends StatelessWidget {
  const _TreeRow({
    required this.depth,
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.selected = false,
  });

  final int depth;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: selected ? colors.secondaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.fromLTRB(8 + depth * 18.0, 10, 8, 10),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? colors.onSecondaryContainer : colors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? colors.onSecondaryContainer : null,
                    fontWeight: selected ? FontWeight.w600 : null,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _TreeNode {
  _TreeNode(this.name, this.pathKey, [this.entry]);

  final String name;
  final String pathKey;
  final FolderEntry? entry;
  final Map<String, _TreeNode> _children = {};

  late final List<_TreeNode> children = _children.values.toList()
    ..sort((a, b) {
      final kind = (a.entry == null ? 0 : 1) - (b.entry == null ? 0 : 1);
      return kind != 0 ? kind : naturalCompare(a.name, b.name);
    });

  /// Only folders that (eventually) contain notes are shown.
  static _TreeNode build(NoteFolder folder) {
    final root = _TreeNode(folder.name, '');
    for (final entry in folder.notes) {
      var node = root;
      for (var i = 0; i < entry.path.length - 1; i++) {
        final key = entry.path.sublist(0, i + 1).join('/');
        node = node._children.putIfAbsent(
          entry.path[i],
          () => _TreeNode(entry.path[i], key),
        );
      }
      node._children[entry.name] = _TreeNode(entry.name, entry.pathKey, entry);
    }
    return root;
  }
}

/// Case-insensitive comparison that orders digit runs numerically.
int naturalCompare(String a, String b) {
  final pattern = RegExp(r'(\d+)|(\D+)');
  final left = pattern.allMatches(a.toLowerCase()).toList();
  final right = pattern.allMatches(b.toLowerCase()).toList();
  for (var i = 0; i < left.length && i < right.length; i++) {
    final x = left[i];
    final y = right[i];
    if (x.group(1) != null && y.group(1) != null) {
      final diff = BigInt.parse(
        x.group(1)!,
      ).compareTo(BigInt.parse(y.group(1)!));
      if (diff != 0) return diff;
    } else {
      final diff = x.group(0)!.compareTo(y.group(0)!);
      if (diff != 0) return diff;
    }
  }
  return left.length - right.length;
}
