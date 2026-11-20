import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/services/recent_folders.dart';

class PreferencesRecentFolders implements RecentFoldersStore {
  static const _key = 'recentFolders.v1';

  @override
  Future<List<RecentFolder>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [for (final item in decoded) ?RecentFolder.fromJson(item)];
    } on FormatException {
      return const [];
    }
  }

  @override
  Future<void> save(List<RecentFolder> folders) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _key,
      jsonEncode([for (final folder in folders) folder.toJson()]),
    );
  }
}
