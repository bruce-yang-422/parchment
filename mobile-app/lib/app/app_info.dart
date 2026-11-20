/// About information shown at the bottom of the settings sheet.
///
/// Keep [version] and [buildNumber] in step with `pubspec.yaml`
/// (`test/app_info_test.dart` checks this) and update [lastUpdated] with
/// each release.
class AppInfo {
  const AppInfo._();

  static const name = 'Parchment';
  static const version = '1.1.1';
  static const buildNumber = 1;
  static const lastUpdated = '2026-11-20';
  static const author = 'Bruce Yang';
  static const license = 'MIT';

  static final website = Uri.parse('https://parchment.stack-base.com/');
  static final privacy = Uri.parse(
    'https://parchment.stack-base.com/privacy.html',
  );
}
