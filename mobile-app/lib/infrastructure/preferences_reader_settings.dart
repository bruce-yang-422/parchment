import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/services/reader_settings.dart';

class PreferencesReaderSettings implements ReaderSettingsStore {
  static const _key = 'readerSettings.v1';

  @override
  Future<ReaderSettings?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key);
    if (raw == null) return null;
    try {
      return ReaderSettings.fromJson(jsonDecode(raw));
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> save(ReaderSettings settings) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key, jsonEncode(settings.toJson()));
  }
}
