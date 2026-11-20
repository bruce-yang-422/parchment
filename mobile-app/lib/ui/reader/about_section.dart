import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/app_info.dart';

/// "關於 Parchment" block at the bottom of the settings sheet.
class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  Future<void> _open(BuildContext context, Uri uri) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      messenger?.showSnackBar(SnackBar(content: Text('無法開啟網頁')));
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
            width: 84,
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
                    '關於 ${AppInfo.name}',
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(
                    '在手機上閱讀 .md 與 .txt 文件',
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
        row('版本', AppInfo.version),
        row('最後更新', AppInfo.lastUpdated),
        row('作者', AppInfo.author),
        row('授權', '免費使用（${AppInfo.license} 授權）'),
        const SizedBox(height: 4),
        link(Icons.public, '官方網站', AppInfo.website),
        link(Icons.privacy_tip_outlined, '隱私權政策', AppInfo.privacy),
        ListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          visualDensity: VisualDensity.compact,
          leading: Icon(
            Icons.description_outlined,
            size: 20,
            color: colors.primary,
          ),
          title: const Text('使用的開放原始碼元件'),
          trailing: Icon(
            Icons.chevron_right,
            size: 20,
            color: colors.onSurfaceVariant,
          ),
          onTap: () => showLicensePage(
            context: context,
            applicationName: AppInfo.name,
            applicationVersion: AppInfo.version,
            applicationLegalese:
                '© 2026 ${AppInfo.author}・${AppInfo.license} License',
          ),
        ),
      ],
    );
  }
}
