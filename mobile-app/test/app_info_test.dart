import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:parchment_mobile/app/app_info.dart';

void main() {
  test('App 資訊的版本與 pubspec.yaml 一致', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match = RegExp(
      r'^version:\s*(\d+\.\d+\.\d+)\+(\d+)',
      multiLine: true,
    ).firstMatch(pubspec);
    expect(match, isNotNull);
    expect(AppInfo.version, match!.group(1));
    expect(AppInfo.buildNumber, int.parse(match.group(2)!));
  });

  test('最後更新日期為有效日期', () {
    expect(DateTime.tryParse(AppInfo.lastUpdated), isNotNull);
  });
}
