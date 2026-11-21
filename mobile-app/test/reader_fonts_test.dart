import 'package:flutter_test/flutter_test.dart';
import 'package:parchment_mobile/core/models/reader_preferences.dart';
import 'package:parchment_mobile/ui/theme/reader_fonts.dart';

void main() {
  test('內建字型：英數字跟著中文字型，系統預設不指定字型', () {
    final huninn = ReaderFonts.resolve(
      latin: ReaderLatinFont.system,
      cjk: ReaderCjkFont.huninn,
      locale: ReaderLocale.zhTw,
    );
    expect(huninn.family, 'jfOpenHuninn');
    expect(huninn.fallback, ['jfOpenHuninn']);

    final system = ReaderFonts.resolve(
      latin: ReaderLatinFont.system,
      cjk: ReaderCjkFont.system,
      locale: ReaderLocale.zhTw,
    );
    expect(system.family, isNull);
    expect(system.fallback, isEmpty);

    final mono = ReaderFonts.resolve(
      latin: ReaderLatinFont.mono,
      cjk: ReaderCjkFont.iansui,
      locale: ReaderLocale.zhTw,
    );
    expect(mono.family, 'monospace');
    expect(mono.fallback, ['Iansui']);
  });

  test('每個內建字型都有對應的字型家族', () {
    const bundled = [
      ReaderCjkFont.taipeiSans,
      ReaderCjkFont.huninn,
      ReaderCjkFont.iansui,
      ReaderCjkFont.naikai,
      ReaderCjkFont.genJyuuGothic,
      ReaderCjkFont.lineSeedJp,
      ReaderCjkFont.pretendard,
    ];
    expect(ReaderFonts.bundled.keys, bundled);
  });

  test('字型清單只列收錄該語言文字的字型，目前選擇不會消失', () {
    expect(ReaderFonts.cjkChoices(ReaderLocale.zhTw), [
      ReaderCjkFont.system,
      ReaderCjkFont.notoSans,
      ReaderCjkFont.notoSerif,
      ReaderCjkFont.wenkai,
      ReaderCjkFont.taipeiSans,
      ReaderCjkFont.huninn,
      ReaderCjkFont.iansui,
      ReaderCjkFont.naikai,
    ]);
    // Only Taipei Sans of the bundled fonts has every simplified character.
    expect(ReaderFonts.cjkChoices(ReaderLocale.zhCn), [
      ReaderCjkFont.system,
      ReaderCjkFont.notoSans,
      ReaderCjkFont.notoSerif,
      ReaderCjkFont.zcoolXiaoWei,
      ReaderCjkFont.taipeiSans,
    ]);
    expect(ReaderFonts.cjkChoices(ReaderLocale.ja), [
      ReaderCjkFont.system,
      ReaderCjkFont.notoSans,
      ReaderCjkFont.notoSerif,
      ReaderCjkFont.mPlusRounded,
      ReaderCjkFont.genJyuuGothic,
      ReaderCjkFont.lineSeedJp,
    ]);
    expect(ReaderFonts.cjkChoices(ReaderLocale.ko), [
      ReaderCjkFont.system,
      ReaderCjkFont.notoSans,
      ReaderCjkFont.nanumGothic,
      ReaderCjkFont.nanumMyeongjo,
      ReaderCjkFont.pretendard,
    ]);
    expect(
      ReaderFonts.cjkChoices(ReaderLocale.zhCn, current: ReaderCjkFont.huninn),
      contains(ReaderCjkFont.huninn),
    );
  });

  test('英法德西列出全球最常用的 Google 字型，且不使用中文字型設定', () {
    for (final locale in [
      ReaderLocale.en,
      ReaderLocale.fr,
      ReaderLocale.de,
      ReaderLocale.es,
    ]) {
      expect(ReaderFonts.latinChoices(locale).sublist(1, 5), [
        ReaderLatinFont.roboto,
        ReaderLatinFont.openSans,
        ReaderLatinFont.lato,
        ReaderLatinFont.montserrat,
      ]);
    }
    expect(
      ReaderFonts.latinChoices(ReaderLocale.zhTw),
      isNot(contains(ReaderLatinFont.montserrat)),
    );
    // A CJK font chosen earlier does not apply in an English interface.
    final english = ReaderFonts.resolve(
      latin: ReaderLatinFont.system,
      cjk: ReaderCjkFont.huninn,
      locale: ReaderLocale.en,
    );
    expect(english.family, isNull);
    expect(english.fallback, isEmpty);
  });
}
