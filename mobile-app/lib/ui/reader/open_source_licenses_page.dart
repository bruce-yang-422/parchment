import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A compact alternative to Flutter's stock license page.
///
/// Components are searchable and collapsed by default, so users see a useful
/// overview instead of a continuous wall of legal text.
class OpenSourceLicensesPage extends StatefulWidget {
  const OpenSourceLicensesPage({super.key});

  @override
  State<OpenSourceLicensesPage> createState() => _OpenSourceLicensesPageState();
}

class _OpenSourceLicensesPageState extends State<OpenSourceLicensesPage> {
  late final Future<List<_PackageLicenses>> _licenses = _loadLicenses();
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  static Future<List<_PackageLicenses>> _loadLicenses() async {
    final packages = <String, List<LicenseEntry>>{};
    await for (final entry in LicenseRegistry.licenses) {
      for (final package in entry.packages) {
        packages.putIfAbsent(package, () => []).add(entry);
      }
    }
    final result = [
      for (final item in packages.entries)
        _PackageLicenses(name: item.key, entries: item.value),
    ];
    result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('開放原始碼元件')),
      body: FutureBuilder<List<_PackageLicenses>>(
        future: _licenses,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('無法讀取授權資訊'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snapshot.data!;
          final normalized = _query.trim().toLowerCase();
          final visible = normalized.isEmpty
              ? all
              : all
                    .where(
                      (item) => item.name.toLowerCase().contains(normalized),
                    )
                    .toList();
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.primaryContainer.withValues(
                            alpha: 0.42,
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.code_rounded, color: colors.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${all.length} 個開放原始碼元件',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Parchment 感謝這些專案。點選元件才會展開完整授權文字。',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _search,
                        onChanged: (value) => setState(() => _query = value),
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: '搜尋元件名稱',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _query.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: '清除',
                                  onPressed: () {
                                    _search.clear();
                                    setState(() => _query = '');
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        normalized.isEmpty
                            ? '所有元件'
                            : '找到 ${visible.length} 個元件',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (visible.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text('找不到符合的元件')),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                  sliver: SliverList.separated(
                    itemCount: visible.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) =>
                        _LicenseCard(package: visible[index]),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _LicenseCard extends StatelessWidget {
  const _LicenseCard({required this.package});

  final _PackageLicenses package;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.extension_outlined,
            size: 20,
            color: colors.primary,
          ),
        ),
        title: Text(package.name, style: theme.textTheme.titleSmall),
        subtitle: Text(
          package.entries.length == 1
              ? '授權資訊'
              : '${package.entries.length} 份授權資訊',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(),
          for (var index = 0; index < package.entries.length; index++) ...[
            if (package.entries.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Text(
                  '授權 ${index + 1}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colors.primary,
                  ),
                ),
              ),
            for (final paragraph in package.entries[index].paragraphs)
              Padding(
                padding: EdgeInsets.only(
                  left: (paragraph.indent * 12).clamp(0, 36).toDouble(),
                  top: 8,
                ),
                child: SelectableText(
                  paragraph.text,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _PackageLicenses {
  const _PackageLicenses({required this.name, required this.entries});

  final String name;
  final List<LicenseEntry> entries;
}
