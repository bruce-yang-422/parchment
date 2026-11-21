import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parchment_mobile/core/models/local_document.dart';
import 'package:parchment_mobile/core/models/reader_preferences.dart';
import 'package:parchment_mobile/core/services/document_picker.dart';
import 'package:parchment_mobile/core/services/reader_settings.dart';
import 'package:parchment_mobile/features/reader/reader_controller.dart';

class _MemoryStore implements ReaderSettingsStore {
  final saved = <ReaderSettings>[];

  @override
  Future<ReaderSettings?> load() async => saved.isEmpty ? null : saved.last;

  @override
  Future<void> save(ReaderSettings settings) async => saved.add(settings);
}

class _NoPicker implements DocumentPicker {
  @override
  Future<LocalDocument?> pickDocument() async => null;
}

void main() {
  test('設定可以存成 JSON 再讀回來', () {
    const settings = ReaderSettings(
      themeMode: 'dark',
      textScale: 1.2,
      lineHeight: 2,
      locale: ReaderLocale.ja,
      cjkFont: ReaderCjkFont.huninn,
      latinFont: ReaderLatinFont.serif,
      palette: ReaderPalette.lake,
      fullscreen: true,
    );
    final restored = ReaderSettings.fromJson(settings.toJson());
    expect(restored.toJson(), settings.toJson());
  });

  test('壞掉或未知的值改用預設，不會讓 App 無法啟動', () {
    final restored = ReaderSettings.fromJson({
      'themeMode': 'sepia',
      'textScale': 9,
      'lineHeight': 'big',
      'palette': 'neon',
      'locale': 'ko',
    });
    expect(restored.themeMode, 'system');
    expect(restored.textScale, 2);
    expect(restored.lineHeight, 1.75);
    expect(restored.palette, ReaderPalette.parchment);
    expect(restored.locale, ReaderLocale.ko);
    // Font names saved by older versions map to their replacements.
    expect(
      ReaderSettings.fromJson({'cjkFont': 'kai'}).cjkFont,
      ReaderCjkFont.wenkai,
    );
    expect(
      ReaderSettings.fromJson({'cjkFont': 'jhenghei'}).cjkFont,
      ReaderCjkFont.notoSans,
    );
    // Fonts removed from the app fall back to a close or default choice.
    expect(
      ReaderSettings.fromJson({'cjkFont': 'taipeiSans'}).cjkFont,
      ReaderCjkFont.taipeiSans,
    );
    expect(
      ReaderSettings.fromJson({'cjkFont': 'seto'}).cjkFont,
      ReaderCjkFont.system,
    );
    // Every language starts with the system font; the font list shows a
    // sample of each choice.
    expect(const ReaderSettings().cjkFont, ReaderCjkFont.system);
    expect(
      ReaderSettings.fromJson('not a map').palette,
      ReaderPalette.parchment,
    );
  });

  test('啟動時套用已儲存的設定', () {
    final controller = ReaderController(
      documentPicker: _NoPicker(),
      initialSettings: const ReaderSettings(
        themeMode: 'dark',
        palette: ReaderPalette.aluminum,
        textScale: 1.1,
        fullscreen: true,
      ),
    );
    expect(controller.themeMode, ThemeMode.dark);
    expect(controller.palette, ReaderPalette.aluminum);
    expect(controller.textScale, 1.1);
    expect(controller.fullscreen, isTrue);
  });

  test('文字大小支援 0.5 到 2 倍並限制超出範圍的值', () {
    final controller = ReaderController(documentPicker: _NoPicker());
    controller.setTextScale(0.1);
    expect(controller.textScale, 0.5);
    controller.setTextScale(3);
    expect(controller.textScale, 2);
    controller.dispose();
  });

  testWidgets('連續調整只在停手後儲存一次', (tester) async {
    final store = _MemoryStore();
    final controller = ReaderController(
      documentPicker: _NoPicker(),
      settingsStore: store,
    );
    controller
      ..setTextScale(1.1)
      ..setTextScale(1.2)
      ..setPalette(ReaderPalette.ink);
    expect(store.saved, isEmpty);
    await tester.pump(const Duration(milliseconds: 500));
    expect(store.saved, hasLength(1));
    expect(store.saved.single.textScale, 1.2);
    expect(store.saved.single.palette, ReaderPalette.ink);
    controller.dispose();
  });
}
