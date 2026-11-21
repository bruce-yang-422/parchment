import '../models/reader_preferences.dart';

/// Reading settings kept between launches.
class ReaderSettings {
  const ReaderSettings({
    this.themeMode = 'system',
    this.textScale = 1,
    this.lineHeight = 1.75,
    this.locale = ReaderLocale.zhTw,
    this.cjkFont = ReaderCjkFont.system,
    this.latinFont = ReaderLatinFont.system,
    this.palette = ReaderPalette.parchment,
  });

  /// `system`, `light` or `dark`.
  final String themeMode;
  final double textScale;
  final double lineHeight;
  final ReaderLocale locale;
  final ReaderCjkFont cjkFont;
  final ReaderLatinFont latinFont;
  final ReaderPalette palette;

  Map<String, Object> toJson() => {
    'themeMode': themeMode,
    'textScale': textScale,
    'lineHeight': lineHeight,
    'locale': locale.name,
    'cjkFont': cjkFont.name,
    'latinFont': latinFont.name,
    'palette': palette.name,
  };

  /// Reads saved settings; unknown or broken values fall back to defaults,
  /// so an older or newer app version never fails to start.
  static ReaderSettings fromJson(Object? value) {
    const defaults = ReaderSettings();
    if (value is! Map) return defaults;
    T pick<T extends Enum>(List<T> values, Object? name, T fallback) {
      for (final item in values) {
        if (item.name == name) return item;
      }
      return fallback;
    }

    double number(Object? raw, double fallback, double min, double max) =>
        raw is num && raw.isFinite
        ? raw.toDouble().clamp(min, max).toDouble()
        : fallback;

    final themeMode = value['themeMode'];
    final locale = pick(ReaderLocale.values, value['locale'], defaults.locale);
    return ReaderSettings(
      themeMode: const {'system', 'light', 'dark'}.contains(themeMode)
          ? themeMode as String
          : defaults.themeMode,
      textScale: number(value['textScale'], defaults.textScale, 0.85, 1.35),
      lineHeight: number(value['lineHeight'], defaults.lineHeight, 1.3, 2.2),
      locale: locale,
      cjkFont: pick(
        ReaderCjkFont.values,
        // Names used before the bundled fonts were added.
        switch (value['cjkFont']) {
          'jhenghei' => 'notoSans',
          'ming' => 'notoSerif',
          'kai' => 'wenkai',
          final other => other,
        },
        defaults.cjkFont,
      ),
      latinFont: pick(
        ReaderLatinFont.values,
        value['latinFont'],
        defaults.latinFont,
      ),
      palette: pick(ReaderPalette.values, value['palette'], defaults.palette),
    );
  }
}

abstract interface class ReaderSettingsStore {
  /// Saved settings, or `null` on first launch.
  Future<ReaderSettings?> load();
  Future<void> save(ReaderSettings settings);
}
