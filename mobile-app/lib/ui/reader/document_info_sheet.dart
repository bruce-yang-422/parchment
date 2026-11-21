import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/markdown/frontmatter.dart';
import '../../core/models/local_document.dart';
import '../../core/notes/document_stats.dart';
import '../../core/notes/note_index.dart';
import '../../core/services/document_inspector.dart';
import '../theme/parchment_theme.dart';
import 'note_markdown.dart';

/// The "資訊" sheet: file details, statistics and quick copy actions.
class DocumentInfoSheet extends StatelessWidget {
  const DocumentInfoSheet({
    required this.document,
    required this.stat,
    required this.canWriteInPlace,
    this.folderName,
    this.taskStore,
    super.key,
  });

  final LocalDocument document;
  final Future<DocumentStat?> stat;
  final bool canWriteInPlace;
  final String? folderName;
  final TaskStateStore? taskStore;

  bool get _markdown => document.format == DocumentFormat.markdown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = DocumentStats.of(document.content, markdown: _markdown);
    final tags = _markdown ? noteTags(document.content) : const <String>[];
    final Object? title = _markdown
        ? (Frontmatter.parse(document.content).data ?? const {})['title']
        : null;
    final folderPath = document.folderPath?.join('/');
    final baseName = document.name.replaceFirst(
      RegExp(r'\.(md|txt)$', caseSensitive: false),
      '',
    );

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: FutureBuilder<DocumentStat?>(
          future: stat,
          builder: (context, snapshot) {
            final info = snapshot.data;
            final location = describeLocation(
              documentId: info?.documentId,
              authority: info?.authority,
              storagePath: info?.storagePath,
              absolutePath: info?.absolutePath,
            );
            final size = info?.size ?? document.byteLength;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                Text('文件資訊', style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  title is String && title.isNotEmpty ? title : document.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _CopyChip(label: '複製檔名', value: document.name),
                    if (location?.path != null || folderPath != null)
                      _CopyChip(
                        label: '複製檔案位置',
                        value:
                            location?.absolute ??
                            location?.display ??
                            folderPath!,
                      ),
                    if (_markdown)
                      _CopyChip(label: '複製筆記連結', value: '[[$baseName]]'),
                    _CopyChip(label: '複製全文', value: document.content),
                  ],
                ),
                // Ordered by how often people look for each item; the
                // technical details come last.
                _Section(
                  title: '基本資訊',
                  rows: [
                    _Row('檔名', document.name, copyable: true),
                    _Row('大小', size == null ? '未知' : _formatSize(size)),
                    _Row(
                      '修改時間',
                      info?.modified == null
                          ? (snapshot.connectionState == ConnectionState.done
                                ? '系統未提供'
                                : '讀取中…')
                          : _formatTime(info!.modified!),
                    ),
                    _Row('字數', _number(stats.words)),
                    if (stats.cjkCharacters > 0 && stats.latinWords > 0)
                      _Row(
                        '　其中',
                        '中文 ${_number(stats.cjkCharacters)} 字・'
                            '英文 ${_number(stats.latinWords)} 字',
                        muted: true,
                      ),
                    if (_markdown && stats.tasks > 0) _taskRow(stats),
                    if (tags.isNotEmpty)
                      _Row('標籤', tags.map((tag) => '#$tag').join('  ')),
                  ],
                ),
                _Section(
                  title: '檔案位置',
                  rows: [
                    if (location != null)
                      _Row('位置', location.display, copyable: true),
                    if (location?.absolute != null)
                      _Row('完整路徑', location!.absolute!, copyable: true),
                    if (folderName != null && folderPath != null)
                      _Row('資料夾內', '$folderName/$folderPath', copyable: true),
                    _Row('勾選後儲存', canWriteInPlace ? '可以直接存回這個檔案' : '只能另存新檔'),
                    _Row(
                      '建立時間',
                      info?.created == null
                          ? '系統未提供'
                          : _formatTime(info!.created!),
                      muted: info?.created == null,
                    ),
                  ],
                ),
                _Section(
                  title: '文件內容',
                  rows: [
                    if (_markdown) _Row('標題', _number(stats.headings)),
                    _Row('段落', _number(stats.paragraphs)),
                    if (_markdown) ...[
                      _Row(
                        '連結',
                        '其他筆記 ${stats.wikiLinks + stats.markdownLinks}・'
                            '網址 ${stats.externalLinks}',
                      ),
                      _Row('圖片', _number(stats.images)),
                      _Row(
                        '程式碼與圖表',
                        '${stats.codeBlocks} 段程式碼・${stats.diagrams} 張圖表',
                      ),
                      if (stats.footnotes > 0)
                        _Row('附註', _number(stats.footnotes)),
                      if (stats.properties > 0)
                        _Row('文件資料', '${stats.properties} 項'),
                    ],
                  ],
                ),
                _Section(
                  title: '進階資訊（給技術人員）',
                  rows: [
                    _Row(
                      '字元數',
                      '${_number(stats.characters)}'
                          '（不含空白 ${_number(stats.charactersWithoutSpaces)}）',
                    ),
                    _Row('行數', _number(stats.lines)),
                    _Row('類型', _markdown ? 'Markdown' : '純文字'),
                    _Row(
                      '編碼',
                      [
                        'UTF-8',
                        if (document.hasBom) '含 BOM',
                        if (!document.lossless) '含無效位元組，以替代字元顯示',
                      ].join('・'),
                    ),
                    _Row('換行', switch (stats.lineEnding) {
                      LineEnding.none => '單行',
                      LineEnding.lf => 'LF（macOS／Linux）',
                      LineEnding.crlf => 'CRLF（Windows）',
                      LineEnding.mixed => '混合 LF 與 CRLF',
                    }),
                    if (size != null) _Row('位元組', _number(size)),
                    if (document.sha256 != null)
                      _Row(
                        'SHA-256',
                        document.sha256!,
                        copyable: true,
                        monospace: true,
                      ),
                    if (document.sourceUri != null)
                      _Row(
                        'URI',
                        document.sourceUri!,
                        copyable: true,
                        muted: true,
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  _Row _taskRow(DocumentStats stats) {
    final store = taskStore;
    final pending = store?.changes.length ?? 0;
    var done = stats.completedTasks;
    if (store != null) {
      for (final entry in store.changes.entries) {
        done += entry.value ? 1 : -1;
      }
    }
    final percent = stats.tasks == 0 ? 0 : (done * 100 / stats.tasks).round();
    return _Row(
      '待辦事項',
      '已完成 $done／${stats.tasks}（$percent%）'
          '${pending > 0 ? '，有 $pending 項還沒儲存' : ''}',
    );
  }

  static String _number(int value) => value.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );

  static String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kib = bytes / 1024;
    final text = kib < 1024
        ? '${kib.toStringAsFixed(kib < 10 ? 1 : 0)} KB'
        : '${(kib / 1024).toStringAsFixed(2)} MB';
    return text;
  }

  static String _formatTime(DateTime time) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${time.year}/${two(time.month)}/${two(time.day)} '
        '${two(time.hour)}:${two(time.minute)}';
  }
}

class _Row {
  const _Row(
    this.label,
    this.value, {
    this.copyable = false,
    this.muted = false,
    this.monospace = false,
  });

  final String label;
  final String value;
  final bool copyable;
  final bool muted;

  /// Fixed-width digits, for hashes.
  final bool monospace;
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.rows});

  final String title;
  final List<_Row> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(color: colors.primary),
          ),
          const SizedBox(height: 6),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Column(
                children: [
                  for (final row in rows)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            // Labels grow with the system font size, up to
                            // about 40% of the screen.
                            width: math.min(
                              MediaQuery.textScalerOf(context).scale(92),
                              MediaQuery.sizeOf(context).width * 0.38,
                            ),
                            child: Text(
                              row.label,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Expanded(
                            child: SelectableText(
                              row.value,
                              // A row without a label is a note on the row
                              // above it.
                              style:
                                  (row.label.isEmpty
                                          ? theme.textTheme.bodySmall
                                          : theme.textTheme.bodyMedium)
                                      ?.copyWith(
                                        color: row.muted
                                            ? colors.onSurfaceVariant
                                            : null,
                                        fontFamily: row.monospace
                                            ? 'monospace'
                                            : null,
                                      ),
                            ),
                          ),
                          if (row.copyable)
                            _CopyIcon(value: row.value, label: row.label),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Copies [value] and briefly shows a check mark (snack bars would be
/// hidden behind the sheet).
class _CopyIcon extends StatefulWidget {
  const _CopyIcon({required this.value, required this.label});

  final String value;
  final String label;

  @override
  State<_CopyIcon> createState() => _CopyIconState();
}

class _CopyIconState extends State<_CopyIcon> {
  bool _copied = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.value));
    if (!mounted) return;
    setState(() => _copied = true);
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: 32,
      height: 24,
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 18,
        tooltip: _copied ? '已複製' : '複製${widget.label}',
        onPressed: _copy,
        icon: Icon(
          _copied ? Icons.check : Icons.copy_rounded,
          color: _copied ? colors.primary : colors.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _CopyChip extends StatefulWidget {
  const _CopyChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  State<_CopyChip> createState() => _CopyChipState();
}

class _CopyChipState extends State<_CopyChip> {
  bool _copied = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.value));
    if (!mounted) return;
    setState(() => _copied = true);
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final look = ReaderLook.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final style = look.chrome.button;
    final small = BorderRadius.circular(4);
    final capsule = BorderRadius.circular(999);
    final white = dark
        ? Color.lerp(look.surface, Colors.white, 0.06)!
        : Colors.white;
    final (background, foreground, border, radius) = switch (style) {
      ButtonLook.outlined => (
        Colors.transparent,
        look.primary,
        Border.all(color: look.border),
        capsule,
      ),
      ButtonLook.filled => (
        Color.lerp(look.surface, look.border, 0.6)!,
        look.text,
        null,
        small,
      ),
      ButtonLook.subtle => (
        white,
        look.muted,
        Border.all(color: look.border),
        small,
      ),
      ButtonLook.fluent => (
        white,
        look.text,
        Border.all(color: look.border),
        small,
      ),
      ButtonLook.tinted => (
        look.primary.withValues(alpha: dark ? 0.22 : 0.12),
        look.primary,
        null,
        capsule,
      ),
    };
    final iconColor = style == ButtonLook.filled || style == ButtonLook.fluent
        ? look.primary
        : foreground;
    return Semantics(
      button: true,
      label: _copied ? '已複製' : widget.label,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: _copy,
          child: Ink(
            decoration: BoxDecoration(
              color: background,
              borderRadius: radius,
              border: border,
              // Fluent buttons have a slightly darker bottom edge.
              boxShadow: style == ButtonLook.fluent
                  ? [
                      BoxShadow(
                        color: Color.lerp(look.border, look.text, 0.25)!,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: style == ButtonLook.tinted ? 14 : 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _copied ? Icons.check : Icons.copy_rounded,
                      size: 16,
                      color: iconColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _copied ? '已複製' : widget.label,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 13.5,
                        fontWeight: style == ButtonLook.tinted
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
