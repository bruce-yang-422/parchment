enum ReaderLocale { zhTw, zhCn, en, ja, ko, fr, de, es }

/// Chinese, Japanese and Korean text font.
///
/// Google Fonts ([notoSans] and [notoSerif] in the interface language's
/// regional variant, plus each language's popular picks) are downloaded
/// when chosen, as is [wenkai]; [taipeiSans] … [pretendard] are bundled
/// with the app.
enum ReaderCjkFont {
  system,
  notoSans,
  notoSerif,
  zcoolXiaoWei,
  mPlusRounded,
  nanumGothic,
  nanumMyeongjo,
  wenkai,
  taipeiSans,
  huninn,
  iansui,
  naikai,
  genJyuuGothic,
  lineSeedJp,
  pretendard,
}

/// Latin letters and numbers from Google Fonts ([sans] is Inter, [serif]
/// Merriweather); [system] follows the chosen CJK font. Each interface
/// language lists its own choices (see `ReaderFonts.latinChoices`).
enum ReaderLatinFont {
  system,
  sans,
  serif,
  roboto,
  openSans,
  lato,
  montserrat,
  mono,
}

enum ReaderPalette { parchment, amethyst, ink, lake, aluminum }
