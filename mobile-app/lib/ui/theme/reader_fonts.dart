import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/models/reader_preferences.dart';

/// Font families for the reading text.
///
/// Google Fonts (Inter, Merriweather, Noto Sans/Serif) are fetched only when
/// chosen and then cached on the phone; the other CJK fonts are bundled
/// (see `pubspec.yaml` → `fonts`).
class ReaderFonts {
  const ReaderFonts._();

  /// Family names declared in `pubspec.yaml`.
  static const bundled = {
    ReaderCjkFont.taipeiSans: 'TaipeiSansTC',
    ReaderCjkFont.huninn: 'jfOpenHuninn',
    ReaderCjkFont.iansui: 'Iansui',
    ReaderCjkFont.naikai: 'NaikaiFont',
    ReaderCjkFont.genJyuuGothic: 'GenJyuuGothic',
    ReaderCjkFont.lineSeedJp: 'LINESeedJP',
    ReaderCjkFont.pretendard: 'Pretendard',
  };

  /// Family for CJK text, or `null` for the system font. Noto uses the
  /// regional variant of the interface language.
  static String? cjkFamily(ReaderCjkFont font, ReaderLocale locale) {
    return switch (font) {
      ReaderCjkFont.system => null,
      ReaderCjkFont.notoSans => switch (locale) {
        ReaderLocale.zhCn => GoogleFonts.notoSansSc().fontFamily,
        ReaderLocale.ja => GoogleFonts.notoSansJp().fontFamily,
        ReaderLocale.ko => GoogleFonts.notoSansKr().fontFamily,
        _ => GoogleFonts.notoSansTc().fontFamily,
      },
      ReaderCjkFont.notoSerif => switch (locale) {
        ReaderLocale.zhCn => GoogleFonts.notoSerifSc().fontFamily,
        ReaderLocale.ja => GoogleFonts.notoSerifJp().fontFamily,
        ReaderLocale.ko => GoogleFonts.notoSerifKr().fontFamily,
        _ => GoogleFonts.notoSerifTc().fontFamily,
      },
      ReaderCjkFont.zcoolXiaoWei => GoogleFonts.zcoolXiaoWei().fontFamily,
      ReaderCjkFont.mPlusRounded => GoogleFonts.mPlusRounded1c().fontFamily,
      ReaderCjkFont.nanumGothic => GoogleFonts.nanumGothic().fontFamily,
      ReaderCjkFont.nanumMyeongjo => GoogleFonts.nanumMyeongjo().fontFamily,
      ReaderCjkFont.wenkai => GoogleFonts.lxgwWenKaiTc().fontFamily,
      _ => bundled[font],
    };
  }

  /// Fonts offered for the interface language: only fonts that contain
  /// that language's characters (a font missing them falls back to the
  /// system font character by character, which looks like a bug). The
  /// current choice is always kept so switching language never hides it.
  ///
  /// Coverage of the bundled fonts, checked against GB2312 / Big5: only
  /// Taipei Sans has all simplified characters; the others miss over a
  /// thousand common ones (专, 业, 东, 为 …).
  static List<ReaderCjkFont> cjkChoices(
    ReaderLocale locale, {
    ReaderCjkFont? current,
  }) {
    final choices = <ReaderCjkFont>[
      ReaderCjkFont.system,
      ...switch (locale) {
        ReaderLocale.zhCn => const [
          ReaderCjkFont.notoSans,
          ReaderCjkFont.notoSerif,
          ReaderCjkFont.zcoolXiaoWei,
          ReaderCjkFont.taipeiSans,
        ],
        ReaderLocale.ja => const [
          ReaderCjkFont.notoSans,
          ReaderCjkFont.notoSerif,
          ReaderCjkFont.mPlusRounded,
          ReaderCjkFont.genJyuuGothic,
          ReaderCjkFont.lineSeedJp,
        ],
        ReaderLocale.ko => const [
          ReaderCjkFont.notoSans,
          ReaderCjkFont.nanumGothic,
          ReaderCjkFont.nanumMyeongjo,
          ReaderCjkFont.pretendard,
        ],
        // Traditional Chinese, and Chinese text in other languages.
        _ => const [
          ReaderCjkFont.notoSans,
          ReaderCjkFont.notoSerif,
          ReaderCjkFont.wenkai,
          ReaderCjkFont.taipeiSans,
          ReaderCjkFont.huninn,
          ReaderCjkFont.iansui,
          ReaderCjkFont.naikai,
        ],
      },
    ];
    if (current != null && !choices.contains(current)) choices.add(current);
    return choices;
  }

  /// Interface languages written in Latin letters. They have one font
  /// list of their own and no CJK font setting; Chinese, Japanese or
  /// Korean text in their documents uses the system font.
  static bool isLatinLocale(ReaderLocale locale) => switch (locale) {
    ReaderLocale.en ||
    ReaderLocale.fr ||
    ReaderLocale.de ||
    ReaderLocale.es => true,
    _ => false,
  };

  /// Latin font list of each interface language. No per-country usage
  /// ranking is published, so English, French, German and Spanish use the
  /// global Google Fonts top four (Roboto, Open Sans, Lato, Montserrat), all
  /// with full accent support; then Inter, Merriweather and monospace. The
  /// lists stay separate per language so they can follow local data later.
  /// The current choice is always kept.
  static List<ReaderLatinFont> latinChoices(
    ReaderLocale locale, {
    ReaderLatinFont? current,
  }) {
    final choices = switch (locale) {
      ReaderLocale.en ||
      ReaderLocale.fr ||
      ReaderLocale.de ||
      ReaderLocale.es => [
        ReaderLatinFont.system,
        ReaderLatinFont.roboto,
        ReaderLatinFont.openSans,
        ReaderLatinFont.lato,
        ReaderLatinFont.montserrat,
        ReaderLatinFont.sans,
        ReaderLatinFont.serif,
        ReaderLatinFont.mono,
      ],
      _ => [
        ReaderLatinFont.system,
        ReaderLatinFont.sans,
        ReaderLatinFont.serif,
        ReaderLatinFont.roboto,
        ReaderLatinFont.openSans,
        ReaderLatinFont.lato,
        ReaderLatinFont.mono,
      ],
    };
    if (current != null && !choices.contains(current)) choices.add(current);
    return choices;
  }

  /// Family for Latin letters and numbers, or `null` for the system font.
  static String? latinFamily(ReaderLatinFont font) {
    return switch (font) {
      ReaderLatinFont.system => null,
      ReaderLatinFont.sans => GoogleFonts.inter().fontFamily,
      ReaderLatinFont.serif => GoogleFonts.merriweather().fontFamily,
      ReaderLatinFont.roboto => GoogleFonts.roboto().fontFamily,
      ReaderLatinFont.openSans => GoogleFonts.openSans().fontFamily,
      ReaderLatinFont.lato => GoogleFonts.lato().fontFamily,
      ReaderLatinFont.montserrat => GoogleFonts.montserrat().fontFamily,
      ReaderLatinFont.mono => 'monospace',
    };
  }

  /// `fontFamily` and `fontFamilyFallback` for body text: Latin first, CJK
  /// as the fallback. With the system Latin font, letters follow the CJK
  /// font too, so a rounded or handwritten font stays consistent.
  static ({String? family, List<String> fallback}) resolve({
    required ReaderLatinFont latin,
    required ReaderCjkFont cjk,
    required ReaderLocale locale,
  }) {
    // Latin-script interfaces have no CJK setting: CJK text uses the system.
    final cjkName = isLatinLocale(locale) ? null : cjkFamily(cjk, locale);
    final latinName = latin == ReaderLatinFont.system
        ? cjkName
        : latinFamily(latin);
    return (family: latinName, fallback: [?cjkName]);
  }

  /// Google Fonts family name of a downloadable choice, or `null` for the
  /// system font and bundled fonts. Used to check the download cache
  /// without starting a download.
  static String? googleFamily(ReaderCjkFont font, ReaderLocale locale) {
    String regional(String base) => switch (locale) {
      ReaderLocale.zhCn => '$base SC',
      ReaderLocale.ja => '$base JP',
      ReaderLocale.ko => '$base KR',
      _ => '$base TC',
    };
    return switch (font) {
      ReaderCjkFont.notoSans => regional('Noto Sans'),
      ReaderCjkFont.notoSerif => regional('Noto Serif'),
      ReaderCjkFont.wenkai => 'LXGW WenKai TC',
      ReaderCjkFont.zcoolXiaoWei => 'ZCOOL XiaoWei',
      ReaderCjkFont.mPlusRounded => 'M PLUS Rounded 1c',
      ReaderCjkFont.nanumGothic => 'Nanum Gothic',
      ReaderCjkFont.nanumMyeongjo => 'Nanum Myeongjo',
      _ => null,
    };
  }

  static String? googleLatinFamily(ReaderLatinFont font) => switch (font) {
    ReaderLatinFont.sans => 'Inter',
    ReaderLatinFont.serif => 'Merriweather',
    ReaderLatinFont.roboto => 'Roboto',
    ReaderLatinFont.openSans => 'Open Sans',
    ReaderLatinFont.lato => 'Lato',
    ReaderLatinFont.montserrat => 'Montserrat',
    _ => null,
  };

  /// Google Fonts already downloaded on this phone (family names such as
  /// `Noto Serif TC`). google_fonts caches each file in the app support
  /// folder as `Family-Weight_hash.ttf`.
  static Future<Set<String>> downloadedGoogleFonts() async {
    if (kIsWeb) return const {};
    try {
      final directory = await getApplicationSupportDirectory();
      return {
        for (final entity in directory.listSync())
          if (entity is File && entity.path.endsWith('.ttf'))
            File(entity.path).uri.pathSegments.last.split('-').first,
      };
    } on Object {
      return const {};
    }
  }

  static bool isDownloaded(String googleFamily, Set<String> downloaded) =>
      downloaded.contains(googleFamily) ||
      downloaded.contains(googleFamily.replaceAll(' ', ''));

  /// Sample line for the font list, in the interface language; the
  /// punctuation shows how each font places commas and full stops.
  static String cjkSample(ReaderLocale locale) => switch (locale) {
    ReaderLocale.zhCn => '简体中文，标点。“引号”？Aa 123',
    ReaderLocale.ja => '日本語、句読点。「かぎ括弧」Aa 123',
    ReaderLocale.ko => '한국어, 문장 부호. 「따옴표」 Aa 123',
    _ => '台灣，標點。「引號」？Aa 123',
  };

  /// Latin sample in the interface language, with its accented letters.
  static String latinSample(ReaderLocale locale) => switch (locale) {
    ReaderLocale.fr => 'Où êtes-vous, déjà ? 0123',
    ReaderLocale.de => 'Größe, Übung, Straße 0123',
    ReaderLocale.es => '¿Qué año? Mañana, señor 0123',
    _ => 'The quick brown fox 0123',
  };
}
