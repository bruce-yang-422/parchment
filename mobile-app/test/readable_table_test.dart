import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parchment_mobile/ui/reader/readable_table.dart';

const _screen = 360.0;

/// CJK-like column: breaks between characters (word ≈ one character).
TableColumnStats cjk(double natural) =>
    TableColumnStats(natural: natural, word: 16);

double sum(List<double> values) => values.reduce((a, b) => a + b);

Future<void> pumpTable(WidgetTester tester, String markdown) async {
  tester.view.physicalSize = const Size(_screen, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => MarkdownBody(
            data: markdown,
            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                .copyWith(
                  tableColumnWidth: const ReadableColumnWidth(
                    availableWidth: _screen,
                  ),
                ),
          ),
        ),
      ),
    ),
  );
}

double tableWidth(WidgetTester tester) =>
    tester.getSize(find.byType(Table)).width;

void main() {
  group('欄寬判斷', () {
    test('一行放得下：維持原寬', () {
      expect(layoutColumns([cjk(100), cjk(120)], 340), [100, 120]);
    });

    test('五欄短資料：短字換成兩行也不要水平捲動', () {
      final widths = layoutColumns(
        [cjk(56), cjk(150), cjk(140), cjk(48), cjk(48)],
        340,
        rows: 2,
      );
      expect(sum(widths), closeTo(340, 0.01));
      expect(widths[0], 56);
    });

    test('兩欄長內容：滿版，長欄分到較多寬度', () {
      final widths = layoutColumns([cjk(300), cjk(744)], 340, rows: 3);
      expect(sum(widths), closeTo(340, 0.01));
      expect(widths[1], greaterThan(widths[0]));
      expect(widths[0], greaterThanOrEqualTo(112));
    });

    test('極長段落仍滿版換行，不會因為長而捲動', () {
      final widths = layoutColumns([cjk(200), cjk(4000)], 340, rows: 3);
      expect(sum(widths), lessThanOrEqualTo(340.01));
    });

    test('多欄長資料：水平捲動，每欄仍有上限會換行', () {
      final widths = layoutColumns(
        [cjk(60), cjk(500), cjk(500), cjk(500), cjk(80)],
        340,
        rows: 2,
      );
      expect(sum(widths), greaterThan(340));
      for (final width in widths) {
        expect(width, lessThanOrEqualTo(220));
      }
    });

    test('資料列多時每格少換幾行，避免表格過高', () {
      final few = layoutColumns([cjk(800), cjk(800)], 340, rows: 2);
      final many = layoutColumns([cjk(800), cjk(800)], 340, rows: 30);
      expect(many[0], greaterThanOrEqualTo(few[0]));
    });

    test('網址等長字串不被硬拆，超過上限才斷', () {
      final widths = layoutColumns(
        [const TableColumnStats(natural: 180, word: 180), cjk(600)],
        340,
        rows: 2,
      );
      expect(widths[0], 180);
      final capped = layoutColumns([
        const TableColumnStats(natural: 500, word: 500),
        cjk(100),
      ], 340);
      // Spare width may widen it, but it still breaks to fit the screen.
      expect(capped[0] + capped[1], lessThanOrEqualTo(340.01));
    });
  });

  // The test font has no CJK glyphs and does not break between them, so
  // widget tests use space-separated words; CJK cases are covered by the
  // layoutColumns tests above.
  testWidgets('兩欄長內容：滿版換行，不需左右滑動', (tester) async {
    final notes = List.filled(40, 'word').join(' ');
    await pumpTable(
      tester,
      '| key | notes |\n| --- | --- |\n| short one | $notes |\n',
    );
    expect(tester.takeException(), isNull);
    expect(tableWidth(tester), lessThanOrEqualTo(_screen));
    final left = tester.getSize(find.text('short one'));
    final right = tester.getSize(find.text(notes));
    expect(right.width, greaterThan(left.width));
    expect(right.height, greaterThan(left.height));
  });

  testWidgets('五欄短資料：不需左右滑動', (tester) async {
    await pumpTable(
      tester,
      '| y | a | b | c | d |\n|---|---|---|---|---|\n'
      '| 98 | ab cd | ef gh | ij | kl |\n'
      '| 14 | mn | op qr | st | uv |\n',
    );
    expect(tester.takeException(), isNull);
    expect(tableWidth(tester), lessThanOrEqualTo(_screen));
  });

  testWidgets('多欄長資料：可左右滑動，長內容仍換行', (tester) async {
    final long = List.filled(12, 'text').join(' ');
    await pumpTable(
      tester,
      '| y | a | b | c | d |\n|---|---|---|---|---|\n'
      '| 98 | $long | $long | $long | ok |\n',
    );
    expect(tester.takeException(), isNull);
    expect(tableWidth(tester), greaterThan(_screen));
    final cell = tester.getSize(find.text(long).first);
    expect(cell.width, lessThanOrEqualTo(220));
    expect(cell.height, greaterThan(30));
  });
}
