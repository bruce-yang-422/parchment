import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/app_info.dart';
import '../localization/reader_strings.dart';
import 'open_source_licenses_page.dart';

/// "About Parchment" block at the bottom of the settings sheet, in the
/// interface language.
class AboutSection extends StatelessWidget {
  const AboutSection({required this.strings, super.key});

  final ReaderStrings strings;

  Future<void> _open(BuildContext context, Uri uri) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      messenger?.showSnackBar(SnackBar(content: Text(strings.cannotOpenPage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: MediaQuery.textScalerOf(context).scale(96),
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
    Widget link(IconData icon, String label, Uri uri) => ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Icon(icon, size: 20, color: colors.primary),
      title: Text(label),
      trailing: Icon(
        Icons.open_in_new,
        size: 18,
        color: colors.onSurfaceVariant,
      ),
      onTap: () => _open(context, uri),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 32),
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/branding/app-icon.png',
                width: 44,
                height: 44,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.about(AppInfo.name),
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(
                    strings.aboutTagline,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        row(strings.version, AppInfo.version),
        row(strings.lastUpdated, AppInfo.lastUpdated),
        row(strings.author, AppInfo.author),
        row(strings.licenseLabel, strings.licenseValue(AppInfo.license)),
        const SizedBox(height: 4),
        link(Icons.public, strings.website, AppInfo.website),
        link(
          Icons.privacy_tip_outlined,
          strings.privacyPolicy,
          AppInfo.privacy,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          visualDensity: VisualDensity.compact,
          leading: Icon(
            Icons.description_outlined,
            size: 20,
            color: colors.primary,
          ),
          title: Text(strings.openSourceComponents),
          trailing: Icon(
            Icons.chevron_right,
            size: 20,
            color: colors.onSurfaceVariant,
          ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => OpenSourceLicensesPage(strings: strings),
            ),
          ),
        ),
      ],
    );
  }
}
