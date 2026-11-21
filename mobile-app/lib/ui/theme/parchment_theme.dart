import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/models/reader_preferences.dart';

/// Task checkbox shape.
enum CheckLook {
  /// Square box (parchment, Notion).
  square,

  /// Rounded square (Obsidian, Windows 11).
  rounded,

  /// Circle, like iOS Reminders.
  circle,
}

/// How callouts (`> [!tip]`) are drawn.
enum CalloutLook {
  /// Coloured left edge on a tinted box.
  edge,

  /// Tinted box without an edge, coloured title (Obsidian).
  soft,

  /// Grey box, plain title in text colour (Notion).
  plain,

  /// Thin coloured border, icon in a filled circle (Windows 11 InfoBar).
  infoBar,

  /// Large rounded tinted card (iOS).
  inset,
}

/// How code blocks are drawn.
enum CodeLook {
  /// Bordered box with a header line (parchment).
  framed,

  /// Borderless, language in the top-right corner (Obsidian).
  flat,

  /// Grey box, small language label top-left (Notion).
  label,

  /// White card with a separate header bar (Windows 11).
  card,

  /// Rounded grey box (iOS).
  inset,
}

/// Small action buttons (copy chips and the like).
enum ButtonLook {
  /// Capsule with a thin outline (parchment).
  outlined,

  /// Small-radius grey fill, no outline (Obsidian).
  filled,

  /// Small-radius white button with a hairline border (Notion).
  subtle,

  /// Fluent standard button: white, rounded 4, darker bottom edge.
  fluent,

  /// Capsule tinted with the accent colour (iOS).
  tinted,
}

/// How quotes are drawn.
enum QuoteLook {
  /// Tinted box with a coloured left edge.
  tinted,

  /// Only a thick line on the left, no background.
  line,

  /// Bordered card with an accent line on the left.
  card,
}

/// How tables are drawn.
enum TableLook {
  /// Full grid with a tinted header and striped rows.
  grid,

  /// Horizontal lines only.
  lines,

  /// Bordered rounded card with row separators.
  card,
}

/// App frame of a palette: what makes it recognisable beyond colour.
@immutable
class ReaderChrome {
  const ReaderChrome({
    required this.controlRadius,
    required this.sheetRadius,
    required this.panelRadius,
    this.titleSize = 22,
    this.titleWeight = FontWeight.w600,
    this.headingFamily,
    this.linkUnderline = true,
    this.mutedUnderline = false,
    this.ornamentRule = false,
    this.paper = false,
    this.groupedSettings = false,
    required this.check,
    required this.callout,
    required this.code,
    required this.button,
    this.quoteWidth = 3,
    this.checkedColor,
    this.tableHeaderTint = true,
  });

  /// Buttons and chips; `null` gives capsule buttons.
  final double? controlRadius;

  /// Top corners of bottom sheets.
  final double sheetRadius;

  /// Cards, dialogs and list rows.
  final double panelRadius;

  /// App bar title.
  final double titleSize;
  final FontWeight titleWeight;

  /// Font of document headings (`serif` for parchment).
  final String? headingFamily;
  final bool linkUnderline;

  /// Grey underline instead of the link colour (Notion).
  final bool mutedUnderline;

  /// `❦` ornament instead of a plain horizontal rule.
  final bool ornamentRule;

  /// Paper background with a soft vignette.
  final bool paper;

  /// Settings shown as rounded grouped lists (iOS).
  final bool groupedSettings;

  final CheckLook check;
  final CalloutLook callout;
  final CodeLook code;
  final ButtonLook button;

  /// Width of the quote's left line.
  final double quoteWidth;

  /// Fill of a ticked checkbox when it differs from the primary colour
  /// (Notion's blue).
  final Color? checkedColor;

  /// Whether grid tables tint their header row.
  final bool tableHeaderTint;

  OutlinedBorder controlShape([double? fallback]) {
    final radius = controlRadius ?? fallback;
    return radius == null
        ? const StadiumBorder()
        : RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));
  }
}

/// Reading styles of one palette in one brightness, matching the web
/// version's palettes: colours plus heading, quote, code and table shapes.
@immutable
class ReaderLook extends ThemeExtension<ReaderLook> {
  const ReaderLook({
    required this.background,
    required this.surface,
    required this.border,
    required this.text,
    required this.muted,
    required this.primary,
    required this.link,
    required this.codeBackground,
    required this.codeBorder,
    required this.inlineCode,
    required this.quoteBorder,
    required this.quoteBackground,
    required this.heading1,
    required this.heading2,
    required this.mark,
    required this.radius,
    required this.quote,
    required this.table,
    required this.headingScale,
    required this.headingWeight,
    this.headingLetterSpacing = 0,
    this.bodyScale = 1,
    this.blockSpacing = 8,
    this.codeBorderVisible = true,
    this.calloutLine = true,
    this.cardBackground,
    this.minimal = false,
    required this.chrome,
  });

  final Color background;
  final Color surface;
  final Color border;
  final Color text;
  final Color muted;
  final Color primary;
  final Color link;
  final Color codeBackground;
  final Color codeBorder;
  final Color inlineCode;
  final Color quoteBorder;

  /// `null` means transparent.
  final Color? quoteBackground;
  final Color heading1;
  final Color heading2;
  final Color mark;

  /// Corner radius of code blocks, callouts, cards and images.
  final double radius;
  final QuoteLook quote;
  final TableLook table;

  /// h1, h2 and h3 size relative to body text.
  final List<double> headingScale;
  final FontWeight headingWeight;

  /// Letter spacing of headings, in em.
  final double headingLetterSpacing;

  /// Body text size relative to the default.
  final double bodyScale;
  final double blockSpacing;
  final bool codeBorderVisible;

  /// Whether callouts have a thick coloured left edge.
  final bool calloutLine;

  /// Background of card-style blocks when it differs from [surface].
  final Color? cardBackground;

  /// Ink style: larger quote text and muted table headers.
  final bool minimal;

  /// App frame shared by the light and dark variant.
  final ReaderChrome chrome;

  static ReaderLook of(BuildContext context) =>
      Theme.of(context).extension<ReaderLook>() ??
      ParchmentTheme.look(
        ReaderPalette.parchment,
        Theme.of(context).brightness,
      );

  @override
  ReaderLook copyWith() => this;

  @override
  ReaderLook lerp(covariant ReaderLook? other, double t) =>
      other == null || t < 0.5 ? this : other;
}

class ParchmentTheme {
  // The app rebuilds on every controller change; handing MaterialApp the
  // same ThemeData instance keeps the document from being rebuilt as if
  // the theme had changed.
  static final Map<(Brightness, ReaderPalette), ThemeData> _themes = {};

  static ThemeData light(ReaderPalette palette) => _themes.putIfAbsent(
    (Brightness.light, palette),
    () => _build(Brightness.light, palette),
  );

  static ThemeData dark(ReaderPalette palette) => _themes.putIfAbsent(
    (Brightness.dark, palette),
    () => _build(Brightness.dark, palette),
  );

  static ReaderLook look(ReaderPalette palette, Brightness brightness) =>
      brightness == Brightness.dark ? _dark[palette]! : _light[palette]!;

  static ThemeData _build(Brightness brightness, ReaderPalette palette) {
    final look = ParchmentTheme.look(palette, brightness);
    final isDark = brightness == Brightness.dark;
    final surface = look.background;
    final onPrimary = look.primary.computeLuminance() > 0.45
        ? const Color(0xFF111111)
        : Colors.white;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: look.primary,
          brightness: brightness,
        ).copyWith(
          primary: look.primary,
          onPrimary: onPrimary,
          primaryContainer: Color.lerp(surface, look.primary, 0.16),
          onPrimaryContainer: look.text,
          surface: surface,
          onSurface: look.text,
          onSurfaceVariant: look.muted,
          outline: Color.lerp(look.border, look.muted, 0.5),
          outlineVariant: look.border,
          surfaceContainerLowest: surface,
          surfaceContainerLow: look.surface,
          surfaceContainer: look.surface,
          surfaceContainerHigh: Color.lerp(look.surface, look.border, 0.3),
          surfaceContainerHighest: Color.lerp(look.surface, look.border, 0.5),
        );
    final chrome = look.chrome;
    // Paper is painted behind the app (see [PaperBackground]).
    final page = chrome.paper ? Colors.transparent : surface;
    final hairline = scheme.outlineVariant.withValues(
      alpha: isDark ? 0.7 : 0.9,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      extensions: [look],
      scaffoldBackgroundColor: page,
      splashFactory: NoSplash.splashFactory,
      visualDensity: VisualDensity.standard,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: page,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: chrome.titleSize,
          fontWeight: chrome.titleWeight,
          letterSpacing: chrome.titleSize > 24 ? -0.6 : -0.35,
        ),
        iconTheme: IconThemeData(color: scheme.onSurface, size: 22),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        modalBackgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: Colors.black.withValues(alpha: isDark ? 0.5 : 0.32),
        showDragHandle: true,
        dragHandleColor: scheme.onSurfaceVariant.withValues(alpha: 0.72),
        dragHandleSize: const Size(36, 5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(chrome.sheetRadius),
          ),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(chrome.panelRadius),
          side: BorderSide(color: hairline, width: 0.5),
        ),
      ),
      dialogTheme: DialogThemeData(
        elevation: 12,
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(chrome.panelRadius + 6),
        ),
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.25,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: chrome.controlShape(),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          side: BorderSide(color: hairline),
          shape: chrome.controlShape(),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(44, 44),
          shape: chrome.controlShape(12),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(
          alpha: isDark ? 0.45 : 0.58,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: hairline, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      listTileTheme: ListTileThemeData(
        minTileHeight: 52,
        minVerticalPadding: 8,
        iconColor: scheme.onSurfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(chrome.panelRadius),
        ),
      ),
      dividerTheme: DividerThemeData(color: hairline, thickness: 0.5, space: 1),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.surfaceContainerHighest,
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withValues(alpha: 0.1),
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 8,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  // Colours follow the web version (src/styles/palettes.css and
  // shell.css); shapes follow src/styles/palette-reader.css.

  static const _parchmentChrome = ReaderChrome(
    controlRadius: null,
    sheetRadius: 28,
    panelRadius: 16,
    headingFamily: 'serif',
    ornamentRule: true,
    paper: true,
    check: CheckLook.square,
    callout: CalloutLook.edge,
    code: CodeLook.framed,
    button: ButtonLook.outlined,
  );

  /// Obsidian: square-ish controls, purple links without underline.
  static const _amethystChrome = ReaderChrome(
    controlRadius: 4,
    sheetRadius: 10,
    panelRadius: 6,
    titleSize: 19,
    linkUnderline: false,
    check: CheckLook.rounded,
    callout: CalloutLook.soft,
    code: CodeLook.flat,
    button: ButtonLook.filled,
    quoteWidth: 2,
    tableHeaderTint: false,
  );

  /// Notion: black and white, small radii, grey link underline.
  static const _inkChrome = ReaderChrome(
    controlRadius: 4,
    sheetRadius: 12,
    panelRadius: 4,
    titleSize: 20,
    titleWeight: FontWeight.w700,
    mutedUnderline: true,
    check: CheckLook.square,
    callout: CalloutLook.plain,
    code: CodeLook.label,
    button: ButtonLook.subtle,
    checkedColor: Color(0xFF2383E2),
    tableHeaderTint: false,
  );

  /// Windows 11: Mica grey, white cards, 4 px buttons, 8 px panels.
  static const _lakeChrome = ReaderChrome(
    controlRadius: 4,
    sheetRadius: 8,
    panelRadius: 8,
    titleSize: 20,
    linkUnderline: false,
    groupedSettings: true,
    check: CheckLook.rounded,
    callout: CalloutLook.infoBar,
    code: CodeLook.card,
    button: ButtonLook.fluent,
  );

  /// iOS / macOS: large titles, capsule buttons, grouped lists.
  static const _aluminumChrome = ReaderChrome(
    controlRadius: null,
    sheetRadius: 14,
    panelRadius: 12,
    titleSize: 30,
    titleWeight: FontWeight.w700,
    linkUnderline: false,
    groupedSettings: true,
    check: CheckLook.circle,
    callout: CalloutLook.inset,
    code: CodeLook.inset,
    button: ButtonLook.tinted,
  );

  static const _light = <ReaderPalette, ReaderLook>{
    // 羊皮紙：暖色紙張、棕色標題。
    ReaderPalette.parchment: ReaderLook(
      chrome: _parchmentChrome,
      background: Color(0xFFF8F1E7),
      surface: Color(0xFFF1E6D6),
      border: Color(0xFFDDCDB8),
      text: Color(0xFF33251C),
      muted: Color(0xFF756351),
      primary: Color(0xFF7B3F20),
      link: Color(0xFF854621),
      codeBackground: Color(0xFFF0E5D5),
      codeBorder: Color(0xFFD9C6AE),
      inlineCode: Color(0xFF984331),
      quoteBorder: Color(0xFFB47A3C),
      quoteBackground: Color(0xFFFFF7E9),
      heading1: Color(0xFF5D2E18),
      heading2: Color(0xFF7A4526),
      mark: Color(0xFFF5DDA0),
      radius: 6,
      quote: QuoteLook.tinted,
      table: TableLook.grid,
      headingScale: [1.75, 1.45, 1.22],
      headingWeight: FontWeight.w700,
    ),
    // 紫晶：白底、紫色強調、小圓角的知識庫筆記風格。
    ReaderPalette.amethyst: ReaderLook(
      chrome: _amethystChrome,
      background: Color(0xFFFFFFFF),
      surface: Color(0xFFF6F6F8),
      border: Color(0xFFE0DFE5),
      text: Color(0xFF222222),
      muted: Color(0xFF6B6876),
      primary: Color(0xFF7C4DDB),
      link: Color(0xFF6D43D0),
      codeBackground: Color(0xFFF5F4F8),
      codeBorder: Color(0xFFE1DFE8),
      inlineCode: Color(0xFFB0306A),
      quoteBorder: Color(0xFF9B7BE8),
      quoteBackground: Color(0xFFF6F2FF),
      heading1: Color(0xFF2A2340),
      heading2: Color(0xFF3B3157),
      mark: Color(0xFFF3E58A),
      radius: 4,
      quote: QuoteLook.line,
      table: TableLook.grid,
      headingScale: [1.8, 1.55, 1.35],
      headingWeight: FontWeight.w700,
      codeBorderVisible: false,
    ),
    // 墨白：黑白極簡、緊湊段落。
    ReaderPalette.ink: ReaderLook(
      chrome: _inkChrome,
      background: Color(0xFFFFFFFF),
      surface: Color(0xFFF7F7F5),
      border: Color(0xFFE9E9E7),
      text: Color(0xFF37352F),
      muted: Color(0xFF6F6E6A),
      primary: Color(0xFF37352F),
      link: Color(0xFF2B6F99),
      codeBackground: Color(0xFFF7F6F3),
      codeBorder: Color(0xFFEBEAE6),
      inlineCode: Color(0xFFC13B38),
      quoteBorder: Color(0xFF37352F),
      quoteBackground: null,
      heading1: Color(0xFF37352F),
      heading2: Color(0xFF37352F),
      mark: Color(0xFFFBF3DB),
      radius: 4,
      quote: QuoteLook.line,
      table: TableLook.grid,
      headingScale: [1.875, 1.5, 1.25],
      headingWeight: FontWeight.w600,
      blockSpacing: 5,
      codeBorderVisible: false,
      calloutLine: false,
      minimal: true,
    ),
    // 湖藍：淺灰底、白色卡片的系統文件風格。
    ReaderPalette.lake: ReaderLook(
      chrome: _lakeChrome,
      background: Color(0xFFF3F3F3),
      surface: Color(0xFFF3F3F3),
      border: Color(0xFFDCDCDC),
      text: Color(0xFF1B1B1B),
      muted: Color(0xFF616161),
      primary: Color(0xFF005FB8),
      link: Color(0xFF005FB8),
      codeBackground: Color(0xFFFFFFFF),
      codeBorder: Color(0xFFDCDCDC),
      inlineCode: Color(0xFFC4314B),
      quoteBorder: Color(0xFF0F6CBD),
      quoteBackground: Color(0xFFF0F6FC),
      heading1: Color(0xFF1B1B1B),
      heading2: Color(0xFF0B3A6B),
      mark: Color(0xFFFFF4B3),
      radius: 8,
      quote: QuoteLook.card,
      table: TableLook.card,
      headingScale: [1.9, 1.45, 1.2],
      headingWeight: FontWeight.w600,
      bodyScale: 0.95,
      cardBackground: Color(0xFFFFFFFF),
    ),
    // 鋁銀：大標題、大圓角的桌面說明文件風格。
    ReaderPalette.aluminum: ReaderLook(
      chrome: _aluminumChrome,
      background: Color(0xFFFFFFFF),
      surface: Color(0xFFF5F5F7),
      border: Color(0xFFD8D8DC),
      text: Color(0xFF1D1D1F),
      muted: Color(0xFF6E6E73),
      primary: Color(0xFF0066CC),
      link: Color(0xFF0066CC),
      codeBackground: Color(0xFFF5F5F7),
      codeBorder: Color(0xFFE0E0E5),
      inlineCode: Color(0xFFAD3DA4),
      quoteBorder: Color(0xFF8E8E93),
      quoteBackground: null,
      heading1: Color(0xFF1D1D1F),
      heading2: Color(0xFF1D1D1F),
      mark: Color(0xFFFFF2A8),
      radius: 10,
      quote: QuoteLook.line,
      table: TableLook.lines,
      headingScale: [2.2, 1.6, 1.25],
      headingWeight: FontWeight.w700,
      headingLetterSpacing: -0.02,
      codeBorderVisible: false,
    ),
  };

  static const _dark = <ReaderPalette, ReaderLook>{
    ReaderPalette.parchment: ReaderLook(
      chrome: _parchmentChrome,
      background: Color(0xFF17120F),
      surface: Color(0xFF241B15),
      border: Color(0xFF4C392B),
      text: Color(0xFFF2E5D3),
      muted: Color(0xFFB6A189),
      primary: Color(0xFFE2A467),
      link: Color(0xFFE2A467),
      codeBackground: Color(0xFF201711),
      codeBorder: Color(0xFF4A3527),
      inlineCode: Color(0xFFF0A087),
      quoteBorder: Color(0xFFC18A4B),
      quoteBackground: Color(0xFF2B2016),
      heading1: Color(0xFFF0BC7F),
      heading2: Color(0xFFDFA064),
      mark: Color(0xFF6A5522),
      radius: 6,
      quote: QuoteLook.tinted,
      table: TableLook.grid,
      headingScale: [1.75, 1.45, 1.22],
      headingWeight: FontWeight.w700,
    ),
    // 紫晶深色：石墨灰底。
    ReaderPalette.amethyst: ReaderLook(
      chrome: _amethystChrome,
      background: Color(0xFF1E1E1E),
      surface: Color(0xFF262626),
      border: Color(0xFF3A3A3A),
      text: Color(0xFFDCDDDE),
      muted: Color(0xFF9A9A9F),
      primary: Color(0xFFA88BFA),
      link: Color(0xFFA88BFA),
      codeBackground: Color(0xFF262626),
      codeBorder: Color(0xFF3A3A3A),
      inlineCode: Color(0xFFF08CB3),
      quoteBorder: Color(0xFF8C6CF0),
      quoteBackground: Color(0xFF262330),
      heading1: Color(0xFFE6E0FF),
      heading2: Color(0xFFCFC3FA),
      mark: Color(0xFF5C4F1A),
      radius: 4,
      quote: QuoteLook.line,
      table: TableLook.grid,
      headingScale: [1.8, 1.55, 1.35],
      headingWeight: FontWeight.w700,
      codeBorderVisible: false,
    ),
    ReaderPalette.ink: ReaderLook(
      chrome: _inkChrome,
      background: Color(0xFF191919),
      surface: Color(0xFF202020),
      border: Color(0xFF2F2F2F),
      text: Color(0xFFD4D4D4),
      muted: Color(0xFF9B9B9B),
      primary: Color(0xFFE3E3E3),
      link: Color(0xFF529CCA),
      codeBackground: Color(0xFF252525),
      codeBorder: Color(0xFF333333),
      inlineCode: Color(0xFFFF7369),
      quoteBorder: Color(0xFFD4D4D4),
      quoteBackground: null,
      heading1: Color(0xFFE6E6E6),
      heading2: Color(0xFFDCDCDC),
      mark: Color(0xFF59563B),
      radius: 4,
      quote: QuoteLook.line,
      table: TableLook.grid,
      headingScale: [1.875, 1.5, 1.25],
      headingWeight: FontWeight.w600,
      blockSpacing: 5,
      codeBorderVisible: false,
      calloutLine: false,
      minimal: true,
    ),
    ReaderPalette.lake: ReaderLook(
      chrome: _lakeChrome,
      background: Color(0xFF202020),
      surface: Color(0xFF2D2D2D),
      border: Color(0xFF3D3D3D),
      text: Color(0xFFF0F0F0),
      muted: Color(0xFFC5C5C5),
      primary: Color(0xFF4CC2FF),
      link: Color(0xFF60CDFF),
      codeBackground: Color(0xFF2B2B2B),
      codeBorder: Color(0xFF3D3D3D),
      inlineCode: Color(0xFFFF99A4),
      quoteBorder: Color(0xFF60CDFF),
      quoteBackground: Color(0xFF1F2B33),
      heading1: Color(0xFFFFFFFF),
      heading2: Color(0xFF99EBFF),
      mark: Color(0xFF5C5420),
      radius: 8,
      quote: QuoteLook.card,
      table: TableLook.card,
      headingScale: [1.9, 1.45, 1.2],
      headingWeight: FontWeight.w600,
      bodyScale: 0.95,
      cardBackground: Color(0xFF2B2B2B),
    ),
    ReaderPalette.aluminum: ReaderLook(
      chrome: _aluminumChrome,
      background: Color(0xFF1E1E1E),
      surface: Color(0xFF2A2A2C),
      border: Color(0xFF3A3A3C),
      text: Color(0xFFF5F5F7),
      muted: Color(0xFF98989D),
      primary: Color(0xFF4EA2FF),
      link: Color(0xFF4EA2FF),
      codeBackground: Color(0xFF2A2A2C),
      codeBorder: Color(0xFF3A3A3C),
      inlineCode: Color(0xFFFF7AB2),
      quoteBorder: Color(0xFF8E8E93),
      quoteBackground: null,
      heading1: Color(0xFFF5F5F7),
      heading2: Color(0xFFE5E5EA),
      mark: Color(0xFF5A5320),
      radius: 10,
      quote: QuoteLook.line,
      table: TableLook.lines,
      headingScale: [2.2, 1.6, 1.25],
      headingWeight: FontWeight.w700,
      headingLetterSpacing: -0.02,
      codeBorderVisible: false,
    ),
  };
}

/// Parchment's paper: a warm sheet with a soft darker edge, painted behind
/// the whole app. Other palettes draw nothing.
class PaperBackground extends StatelessWidget {
  const PaperBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final look = ReaderLook.of(context);
    if (!look.chrome.paper) return child;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: look.background,
        gradient: RadialGradient(
          radius: 1.15,
          colors: dark
              ? const [Color(0xFF1E1813), Color(0xFF17120F), Color(0xFF0E0B09)]
              : const [Color(0xFFFBF5EA), Color(0xFFF5EBDB), Color(0xFFE9D8BD)],
          stops: const [0, 0.62, 1],
        ),
      ),
      child: child,
    );
  }
}
