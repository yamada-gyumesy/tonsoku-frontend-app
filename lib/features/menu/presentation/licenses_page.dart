import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tonsoku/core/i18n/locale_controller.dart';
import 'package:tonsoku/core/licenses/dev_only_packages.dart';
import 'package:tonsoku/core/theme/app_colors.dart';
import 'package:tonsoku/features/menu/presentation/app_version_provider.dart';
import 'package:tonsoku/features/menu/presentation/widgets/menu_list_row.dart';
import 'package:tonsoku/shared/widgets/async_list_view.dart';

/// 同梱物のライセンス表記。
///
/// **Flutter の `showLicensePage` を使わない。** 理由が 2 つある。
///
/// 1. **載せてはいけないものが載る。** Flutter が集める `NOTICES` は
///    `.dart_tool/package_config.json` を元にしていて、生成器（build_runner・
///    freezed・json_serializable など 23 件）まで含む。ビルド時にしか動かず
///    配布物に入らないので、載せると事実と違う（除外リストは
///    `dev_only_packages.dart`。作り方は `tool/build_licenses.py`）。
///    **完全には絞り込めない**ので、残るものは残す（理由はその手順に書いてある）
/// 2. 既定の画面は本文とだけ向き合う作りで、行間も罫線もアプリの他の画面と
///    揃わない
class LicensesPage extends ConsumerWidget {
  const LicensesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(messagesProvider);
    final colors = context.colors;
    final entries = ref.watch(bundledLicensesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.menuLicenses)),
      body: entries.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        // **黙って白紙にしない。** 集める側が 1 つでも落ちると全件消えるが、
        // これは法令順守のための画面で、消えたこと自体が問題になる。
        // 気づけないまま出荷するより、読み直せる形で出す
        error: (_, _) =>
            LoadFailure(onRetry: () => ref.invalidate(bundledLicensesProvider)),
        data: (packages) => ListView.separated(
          itemCount: packages.length + 1,
          separatorBuilder: (context, _) =>
              Divider(height: 1, thickness: 1, color: colors.border),
          itemBuilder: (context, index) {
            if (index == 0) return _Intro(colors: colors);
            final package = packages[index - 1];
            return MenuListRow(
              label: package.name,
              value: t.licenseCount(package.licenses.length),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => _LicenseDetailPage(package: package),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 一覧の先頭に置く前書き。
///
/// **何の一覧なのかを言う。** パッケージ名だけが並ぶと、利用者には何を見せられて
/// いるのか分からない。
class _Intro extends ConsumerWidget {
  const _Intro({required this.colors});

  final AppColors colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(messagesProvider);
    final version = ref.watch(appVersionProvider).value;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            version == null ? t.appName : '${t.appName} $version',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            t.licenseIntro,
            style: TextStyle(fontSize: 13, height: 1.6, color: colors.textSub),
          ),
        ],
      ),
    );
  }
}

class _LicenseDetailPage extends StatelessWidget {
  const _LicenseDetailPage({required this.package});

  final BundledPackage package;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(title: Text(package.name)),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        itemCount: package.licenses.length,
        separatorBuilder: (context, _) =>
            Divider(height: 48, thickness: 1, color: colors.border),
        itemBuilder: (context, index) => SelectableText(
          package.licenses[index],
          style: TextStyle(fontSize: 13, height: 1.7, color: colors.text),
        ),
      ),
    );
  }
}

/// ライセンス 1 件ぶん（同じパッケージに複数付くことがある）。
@immutable
class BundledPackage {
  const BundledPackage({required this.name, required this.licenses});

  final String name;
  final List<String> licenses;
}

/// 同梱物のライセンスを集めて、パッケージ名で並べる。
///
/// **[devOnlyPackages] は落とす**（理由は [LicensesPage]）。
final bundledLicensesProvider = FutureProvider<List<BundledPackage>>((
  ref,
) async {
  final byPackage = <String, List<String>>{};

  await for (final entry in LicenseRegistry.licenses) {
    final text = entry.paragraphs
        .map(
          (p) => p.indent == LicenseParagraph.centeredIndent
              ? p.text.trim()
              : '${'  ' * p.indent}${p.text.trim()}',
        )
        .join('\n\n');

    for (final package in entry.packages) {
      if (devOnlyPackages.contains(package)) continue;
      byPackage.putIfAbsent(package, () => []).add(text);
    }
  }

  final names = byPackage.keys.toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return [
    for (final name in names)
      BundledPackage(name: name, licenses: byPackage[name]!),
  ];
});
