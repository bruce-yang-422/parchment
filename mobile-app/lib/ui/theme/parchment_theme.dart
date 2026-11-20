import 'package:flutter/material.dart';

import '../../core/models/reader_preferences.dart';

class ParchmentTheme {
  static ThemeData light(ReaderPalette palette) {
    return _build(Brightness.light, palette);
  }

  static ThemeData dark(ReaderPalette palette) {
    return _build(Brightness.dark, palette);
  }

  static ThemeData _build(Brightness brightness, ReaderPalette palette) {
    final colors = _colors[palette]!;
    final surface = brightness == Brightness.light ? colors.light : colors.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: colors.seed,
      brightness: brightness,
      surface: surface,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  static const _colors =
      <ReaderPalette, ({Color seed, Color light, Color dark})>{
        ReaderPalette.parchment: (
          seed: Color(0xFF6B3E26),
          light: Color(0xFFF8F1E7),
          dark: Color(0xFF18130F),
        ),
        ReaderPalette.amethyst: (
          seed: Color(0xFF71508F),
          light: Color(0xFFF8F3FC),
          dark: Color(0xFF17121C),
        ),
        ReaderPalette.ink: (
          seed: Color(0xFF3F454A),
          light: Color(0xFFF7F7F5),
          dark: Color(0xFF121416),
        ),
        ReaderPalette.lake: (
          seed: Color(0xFF276B7A),
          light: Color(0xFFF1F8F9),
          dark: Color(0xFF0F191C),
        ),
        ReaderPalette.aluminum: (
          seed: Color(0xFF626B73),
          light: Color(0xFFF2F4F5),
          dark: Color(0xFF141719),
        ),
      };
}
