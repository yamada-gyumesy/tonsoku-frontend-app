import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tonsoku/core/i18n/locale_controller.dart';
import 'package:tonsoku/core/theme/app_colors.dart';
import 'package:tonsoku/features/shell/presentation/widgets/nav_item.dart';

/// 画面下に固定するグローバルナビ。
///
/// 並びは **ホーム / マップ / クーポン / メニュー**（ユーザーの指定）。web の下タブ
/// （ホーム / カレンダー / クーポン / ランキング / メニュー）とは違う ——
/// **アプリにはマップがあり、あぶれたカレンダー・ランキングはメニューに入る。**
///
/// **スクロールで隠さない。** 隠すと移動のたびに一度上へ払う操作が要る
/// （web・gyumesy と同じ）。
///
/// **「メニュー」だけはタブへ移らずシートを開く**（web と同じ）。シートは
/// メニューの Issue（#4）で入れる。
class AppShell extends ConsumerWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  /// web の `--spacing-bottom-nav-inner`（3.5rem）。
  static const _height = 56.0;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      // 同じタブをもう一度押した時は、そのタブのルートまで戻す
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(messagesProvider);
    final colors = context.colors;

    // **アイコンは Material の outlined**（web は Material Symbols Outlined の
    // `home` / `local_activity` / `menu` を使っている。マップは web に無いので
    // 同じ系統の `map`）
    final items = <({IconData icon, String label, int? branch})>[
      (icon: Icons.home_outlined, label: t.navHome, branch: 0),
      (icon: Icons.map_outlined, label: t.navMap, branch: 1),
      (icon: Icons.local_activity_outlined, label: t.navCoupon, branch: 2),
      // メニューはブランチを持たない（シートを開くだけ。#4）
      (icon: Icons.menu, label: t.navMenu, branch: null),
    ];

    return Scaffold(
      body: navigationShell,
      // **`NavigationBar` を使わない。** 既定の高さ（80px）と余白が web
      // （56px・アイコン 22px・ラベル 10px・間隔 4px）と合わず、画面下が
      // そのぶん狭くなる（gyumesy-frontend-app と同じ判断）
      bottomNavigationBar: Semantics(
        container: true,
        label: t.navLabel,
        child: Container(
          // **地は生成り（`bg`）。** web の `CoBottomNav` はヘッダーと同じ地色で、
          // 上罫を残している（本文の面と色が違っても、線が無いと境目が弱い）
          decoration: BoxDecoration(
            color: colors.bg,
            border: Border(top: BorderSide(color: colors.border)),
          ),
          // ホームバーのぶんは器が持つ（中身の高さは web と同じに保つ）
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: _height,
              child: Row(
                children: [
                  for (final item in items)
                    Expanded(
                      child: NavItem(
                        icon: item.icon,
                        label: item.label,
                        isActive:
                            item.branch != null &&
                            navigationShell.currentIndex == item.branch,
                        onTap: item.branch == null
                            // シートはメニューの Issue（#4）で入れる
                            ? () {}
                            : () => _goBranch(item.branch!),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
