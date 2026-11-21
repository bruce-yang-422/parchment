import 'package:flutter/material.dart';

import '../theme/parchment_theme.dart';

/// Icon and colours of one callout type in one palette.
class CalloutVisual {
  const CalloutVisual({
    required this.accent,
    this.icon,
    this.emoji,
    this.background,
  });

  /// Icon and title colour.
  final Color accent;
  final IconData? icon;

  /// Notion uses emoji instead of icons.
  final String? emoji;

  /// Box colour when the palette defines one; otherwise a tint of [accent].
  final Color? background;
}

/// Callout types after aliases are resolved.
const calloutCategories = {
  'note',
  'abstract',
  'info',
  'todo',
  'tip',
  'success',
  'question',
  'warning',
  'failure',
  'danger',
  'bug',
  'example',
  'quote',
};

/// Icons and colours in the style of the app each palette imitates.
CalloutVisual calloutVisual(CalloutLook look, String category, bool dark) {
  return switch (look) {
    CalloutLook.edge => _parchment(category, dark),
    CalloutLook.soft => _obsidian(category, dark),
    CalloutLook.plain => _notion(category, dark),
    CalloutLook.infoBar => _fluent(category, dark),
    CalloutLook.inset => _apple(category, dark),
  };
}

/* Parchment: ink colours on paper, engraved outline icons. */
CalloutVisual _parchment(String category, bool dark) {
  Color ink(int light, int night) => Color(dark ? night : light);
  final slate = ink(0xFF4F6386, 0xFF9FB3D6);
  final olive = ink(0xFF5D7A3E, 0xFFA9C487);
  final ochre = ink(0xFFA8701F, 0xFFE2B062);
  final oxblood = ink(0xFF9A3324, 0xFFE0907F);
  final plum = ink(0xFF6E4F7E, 0xFFC1A3D1);
  final umber = ink(0xFF7A6450, 0xFFC4AE98);
  return switch (category) {
    'abstract' => CalloutVisual(icon: Icons.menu_book_outlined, accent: slate),
    'info' => CalloutVisual(icon: Icons.info_outline, accent: slate),
    'todo' => CalloutVisual(icon: Icons.task_alt, accent: slate),
    'tip' => CalloutVisual(icon: Icons.lightbulb_outline, accent: olive),
    'success' => CalloutVisual(icon: Icons.verified_outlined, accent: olive),
    'question' => CalloutVisual(icon: Icons.help_outline, accent: ochre),
    'warning' => CalloutVisual(
      icon: Icons.report_problem_outlined,
      accent: ochre,
    ),
    'failure' => CalloutVisual(icon: Icons.cancel_outlined, accent: oxblood),
    'danger' => CalloutVisual(
      icon: Icons.local_fire_department_outlined,
      accent: oxblood,
    ),
    'bug' => CalloutVisual(icon: Icons.pest_control_outlined, accent: oxblood),
    'example' => CalloutVisual(icon: Icons.auto_stories_outlined, accent: plum),
    'quote' => CalloutVisual(icon: Icons.format_quote, accent: umber),
    _ => CalloutVisual(icon: Icons.history_edu, accent: slate),
  };
}

/* Obsidian: its default callout colours and Lucide-like icons. */
CalloutVisual _obsidian(String category, bool dark) {
  final blue = Color(dark ? 0xFF027AFF : 0xFF086DDD);
  final cyan = Color(dark ? 0xFF53DFDD : 0xFF00BFBC);
  final green = Color(dark ? 0xFF44CF6E : 0xFF08B94E);
  final orange = Color(dark ? 0xFFFBA70F : 0xFFEC7500);
  final red = Color(dark ? 0xFFFB464C : 0xFFE93147);
  final purple = Color(dark ? 0xFFA882FF : 0xFF7852EE);
  const grey = Color(0xFF9E9E9E);
  return switch (category) {
    'abstract' => CalloutVisual(icon: Icons.content_paste, accent: cyan),
    'info' => CalloutVisual(icon: Icons.info_outline, accent: blue),
    'todo' => CalloutVisual(icon: Icons.check_circle_outline, accent: blue),
    'tip' => CalloutVisual(
      icon: Icons.local_fire_department_outlined,
      accent: cyan,
    ),
    'success' => CalloutVisual(icon: Icons.check, accent: green),
    'question' => CalloutVisual(icon: Icons.help_outline, accent: orange),
    'warning' => CalloutVisual(
      icon: Icons.warning_amber_rounded,
      accent: orange,
    ),
    'failure' => CalloutVisual(icon: Icons.close, accent: red),
    'danger' => CalloutVisual(icon: Icons.bolt, accent: red),
    'bug' => CalloutVisual(icon: Icons.bug_report_outlined, accent: red),
    'example' => CalloutVisual(
      icon: Icons.format_list_bulleted,
      accent: purple,
    ),
    'quote' => const CalloutVisual(icon: Icons.format_quote, accent: grey),
    _ => CalloutVisual(icon: Icons.edit_outlined, accent: blue),
  };
}

/* Notion: emoji icons on its soft block background colours. */
CalloutVisual _notion(String category, bool dark) {
  CalloutVisual block(String emoji, int light, int night, int text) =>
      CalloutVisual(
        emoji: emoji,
        accent: Color(text),
        background: Color(dark ? night : light),
      );
  // Background colours: gray, brown, orange, yellow, green, blue, purple,
  // pink, red.
  final text = dark ? 0xFFD4D4D4 : 0xFF37352F;
  return switch (category) {
    'abstract' => block('📋', 0xFFF1F1EF, 0xFF252525, text),
    'info' => block('ℹ️', 0xFFE7F3F8, 0xFF1F282D, text),
    'todo' => block('☑️', 0xFFE7F3F8, 0xFF1F282D, text),
    'tip' => block('💡', 0xFFFBF3DB, 0xFF372E20, text),
    'success' => block('✅', 0xFFEDF3EC, 0xFF242B26, text),
    'question' => block('❓', 0xFFFAEBDD, 0xFF36291F, text),
    'warning' => block('⚠️', 0xFFFBF3DB, 0xFF372E20, text),
    'failure' => block('❌', 0xFFFDEBEC, 0xFF332523, text),
    'danger' => block('🚨', 0xFFFDEBEC, 0xFF332523, text),
    'bug' => block('🐛', 0xFFFDEBEC, 0xFF332523, text),
    'example' => block('📌', 0xFFF6F3F9, 0xFF2A2430, text),
    'quote' => block('💬', 0xFFF1F1EF, 0xFF252525, text),
    _ => block('📝', 0xFFF1F1EF, 0xFF252525, text),
  };
}

/* Windows 11: Fluent InfoBar severities with filled icons. */
CalloutVisual _fluent(String category, bool dark) {
  final informational = CalloutVisual(
    icon: Icons.info,
    accent: Color(dark ? 0xFF60CDFF : 0xFF005FB8),
    background: Color(dark ? 0xFF2B2B2B : 0xFFFBFBFB),
  );
  final success = CalloutVisual(
    icon: Icons.check_circle,
    accent: Color(dark ? 0xFF6CCB5F : 0xFF0F7B0F),
    background: Color(dark ? 0xFF393D1B : 0xFFDFF6DD),
  );
  final caution = CalloutVisual(
    icon: Icons.error,
    accent: Color(dark ? 0xFFFCE100 : 0xFF9D5D00),
    background: Color(dark ? 0xFF433519 : 0xFFFFF4CE),
  );
  final critical = CalloutVisual(
    icon: Icons.cancel,
    accent: Color(dark ? 0xFFFF99A4 : 0xFFC42B1C),
    background: Color(dark ? 0xFF442726 : 0xFFFDE7E9),
  );
  return switch (category) {
    'tip' || 'success' || 'todo' => success,
    'warning' || 'question' => caution,
    'failure' || 'danger' || 'bug' => critical,
    _ => informational,
  };
}

/* iOS / macOS: system colours with filled, rounded symbols. */
CalloutVisual _apple(String category, bool dark) {
  Color system(int light, int night) => Color(dark ? night : light);
  final blue = system(0xFF007AFF, 0xFF0A84FF);
  final green = system(0xFF34C759, 0xFF30D158);
  final orange = system(0xFFFF9500, 0xFFFF9F0A);
  final yellow = system(0xFFE5A000, 0xFFFFD60A);
  final red = system(0xFFFF3B30, 0xFFFF453A);
  final purple = system(0xFFAF52DE, 0xFFBF5AF2);
  final indigo = system(0xFF5856D6, 0xFF5E5CE6);
  final teal = system(0xFF30B0C7, 0xFF40CBE0);
  final gray = system(0xFF8E8E93, 0xFF98989D);
  return switch (category) {
    'abstract' => CalloutVisual(icon: Icons.description_rounded, accent: teal),
    'info' => CalloutVisual(icon: Icons.info_rounded, accent: blue),
    'todo' => CalloutVisual(icon: Icons.check_circle_rounded, accent: blue),
    'tip' => CalloutVisual(icon: Icons.lightbulb_rounded, accent: yellow),
    'success' => CalloutVisual(icon: Icons.check_circle_rounded, accent: green),
    'question' => CalloutVisual(icon: Icons.help_rounded, accent: purple),
    'warning' => CalloutVisual(icon: Icons.warning_rounded, accent: orange),
    'failure' => CalloutVisual(icon: Icons.cancel_rounded, accent: red),
    'danger' => CalloutVisual(icon: Icons.error_rounded, accent: red),
    'bug' => CalloutVisual(icon: Icons.bug_report_rounded, accent: red),
    'example' => CalloutVisual(icon: Icons.list_alt_rounded, accent: indigo),
    'quote' => CalloutVisual(icon: Icons.format_quote_rounded, accent: gray),
    _ => CalloutVisual(icon: Icons.edit_note_rounded, accent: blue),
  };
}
