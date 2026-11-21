import 'dart:math' as math;

import 'package:flutter/rendering.dart';

/// Decides, per table, whether it fits the screen or scrolls sideways, and
/// wraps long cells in both cases. See [layoutColumns] for the rules.
///
/// The whole table is measured at once (each column reaches its siblings
/// through the parent [RenderTable]).
///
/// It extends [IntrinsicColumnWidth] on purpose: flutter_markdown_plus then
/// places tables in a horizontal scroll view. That view gives the table
/// unlimited width, so the reading width is passed in as [availableWidth].
/// Tables that fit simply never scroll.
class ReadableColumnWidth extends IntrinsicColumnWidth {
  const ReadableColumnWidth({required this.availableWidth});

  /// Width of the reading area (screen minus page padding).
  final double availableWidth;

  @override
  double minIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) =>
      _width(cells, containerWidth);

  @override
  double maxIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) =>
      _width(cells, containerWidth);

  @override
  double? flex(Iterable<RenderBox> cells) => null;

  double _width(Iterable<RenderBox> cells, double containerWidth) {
    final stats = TableColumnStats.measure(cells);
    final parent = cells.isEmpty ? null : cells.first.parent;
    if (parent is! RenderTable) return stats.natural;

    var index = -1;
    final columns = <TableColumnStats>[];
    for (var x = 0; x < parent.columns; x++) {
      final column = parent.column(x);
      if (index < 0 &&
          column.isNotEmpty &&
          identical(column.first, cells.first)) {
        index = x;
      }
      columns.add(TableColumnStats.measure(column));
    }
    if (index < 0) return stats.natural;
    final available = containerWidth.isFinite
        ? math.min(containerWidth, availableWidth)
        : availableWidth;
    // The header row does not count towards the table's height.
    final rows = math.max(parent.rows - 1, 1);
    return layoutColumns(columns, available, rows: rows)[index];
  }
}

/// Measurements of one table column.
class TableColumnStats {
  const TableColumnStats({required this.natural, required this.word});

  static TableColumnStats measure(Iterable<RenderBox> cells) {
    var natural = 0.0;
    var word = 0.0;
    for (final cell in cells) {
      final cellNatural = cell.getMaxIntrinsicWidth(double.infinity);
      natural = math.max(natural, cellNatural);
      word = math.max(word, _longestWord(cell, cellNatural));
    }
    return TableColumnStats(natural: natural, word: word);
  }

  /// Characters that never break inside a run: Latin letters, digits and
  /// URL punctuation. CJK, spaces and other punctuation are break points.
  static final _unbreakable = RegExp(r"[A-Za-z0-9_\-.:/@#%&+=?~'’]+");

  /// Width of the longest unbreakable run in [cell], including the cell's
  /// padding.
  ///
  /// RenderParagraph's min intrinsic width treats a run of CJK characters as
  /// one word, which would make every Chinese cell look unbreakable, so the
  /// runs are measured here instead.
  static double _longestWord(RenderBox cell, double cellNatural) {
    var longest = 0.0;
    var textNatural = 0.0;
    void visit(RenderObject node) {
      if (node is RenderParagraph) {
        textNatural = math.max(
          textNatural,
          node.getMaxIntrinsicWidth(double.infinity),
        );
        longest = math.max(longest, _paragraphWord(node));
        return;
      }
      node.visitChildren(visit);
    }

    visit(cell);
    if (longest == 0) return 0;
    final padding = math.max(0.0, cellNatural - textNatural);
    return longest + padding;
  }

  /// Measured runs per paragraph. Tables are measured several times per
  /// layout (once per column, minimum and maximum), so text is only
  /// measured again when it or its scale changes.
  static final _wordCache =
      Expando<({InlineSpan span, TextScaler scaler, double width})>();

  static double _paragraphWord(RenderParagraph node) {
    final span = node.text;
    final cached = _wordCache[node];
    if (cached != null &&
        identical(cached.span, span) &&
        cached.scaler == node.textScaler) {
      return cached.width;
    }
    final style = span.style ?? _styleOf(span);
    var longest = 0.0;
    for (final match in _unbreakable.allMatches(span.toPlainText())) {
      final painter = TextPainter(
        text: TextSpan(text: match.group(0), style: style),
        textDirection: TextDirection.ltr,
        textScaler: node.textScaler,
      )..layout();
      longest = math.max(longest, painter.width);
      painter.dispose();
    }
    _wordCache[node] = (span: span, scaler: node.textScaler, width: longest);
    return longest;
  }

  static TextStyle? _styleOf(InlineSpan span) {
    TextStyle? found;
    span.visitChildren((child) {
      if (child is TextSpan && child.style != null) {
        found = child.style;
        return false;
      }
      return true;
    });
    return found;
  }

  /// Width of the longest cell on one line.
  final double natural;

  /// Width of the longest unbreakable string (an English word, a URL, a
  /// number). CJK text breaks between characters, so this stays small.
  final double word;
}

/// Width limits used by [layoutColumns].
class TableLayoutLimits {
  const TableLayoutLimits({
    this.minimum = 64,
    this.readable = 112,
    this.maximum = 220,
  });

  /// Narrowest column for wrapped text (about four CJK characters).
  final double minimum;

  /// Comfortable width for long text (about seven CJK characters).
  final double readable;

  /// Widest a column gets before it wraps; also the point where long
  /// unbreakable strings are broken (about thirteen CJK characters).
  final double maximum;
}

/// Column widths for [columns] shown in [available] width.
///
/// Each column gets a **reasonable width**:
/// - at least its longest unbreakable string (capped at
///   [TableLayoutLimits.maximum], beyond which it breaks);
/// - short text may wrap onto about two lines, long text keeps a readable
///   width;
/// - long text aims for a few lines per cell — fewer when the table has
///   many [rows], so it does not grow too tall;
/// - never wider than the text on one line or [TableLayoutLimits.maximum].
///
/// Then: if everything fits on one line, nothing changes. If the reasonable
/// widths fit, the table fills the screen; spare width goes to longer
/// columns (by the square root of their one-line width). Otherwise the table
/// scrolls sideways with each column at its reasonable width, so cells still
/// wrap instead of becoming endless lines.
List<double> layoutColumns(
  List<TableColumnStats> columns,
  double available, {
  int rows = 1,
  TableLayoutLimits limits = const TableLayoutLimits(),
}) {
  final count = columns.length;
  if (count == 0) return const [];
  final naturals = [for (final column in columns) column.natural];
  final total = naturals.fold<double>(0, (sum, value) => sum + value);
  if (total <= available) return naturals;

  final targetLines = rows <= 3
      ? 5
      : rows <= 10
      ? 4
      : 3;
  final reasonable = [
    for (final column in columns) _reasonableWidth(column, limits, targetLines),
  ];
  final required = reasonable.fold<double>(0, (sum, value) => sum + value);
  if (required > available) return reasonable;
  return _fill(naturals, reasonable, available);
}

double _reasonableWidth(
  TableColumnStats column,
  TableLayoutLimits limits,
  int targetLines,
) {
  final natural = column.natural;
  final upper = math.min(natural, limits.maximum);
  final word = math.min(column.word, limits.maximum);
  final wrapped = math.min(
    natural,
    math.max(limits.minimum, math.min(limits.readable, natural / 2)),
  );
  final lower = math.min(upper, math.max(word, wrapped));
  return (natural / targetLines).clamp(lower, upper).toDouble();
}

/// Shares [available] width: every column gets at least its [floors] value
/// and at most its one-line width; the rest is split by the square root of
/// the one-line widths.
List<double> _fill(
  List<double> naturals,
  List<double> floors,
  double available,
) {
  final count = naturals.length;
  final widths = List<double?>.filled(count, null);
  var remaining = available;
  while (true) {
    final active = [
      for (var i = 0; i < count; i++)
        if (widths[i] == null) i,
    ];
    if (active.isEmpty) break;
    final weight = active.fold<double>(
      0,
      (sum, i) => sum + math.sqrt(math.max(naturals[i], 1)),
    );
    double proposal(int i) =>
        remaining * math.sqrt(math.max(naturals[i], 1)) / weight;

    final capped = active.where((i) => proposal(i) > naturals[i]).toList();
    if (capped.isNotEmpty) {
      for (final i in capped) {
        widths[i] = naturals[i];
        remaining -= naturals[i];
      }
      continue;
    }
    final floored = active.where((i) => proposal(i) < floors[i]).toList();
    if (floored.isNotEmpty) {
      for (final i in floored) {
        widths[i] = floors[i];
        remaining -= floors[i];
      }
      continue;
    }
    for (final i in active) {
      widths[i] = proposal(i);
    }
    break;
  }
  return [for (final width in widths) width!];
}
