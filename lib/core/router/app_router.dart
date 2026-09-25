import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tonsoku/features/shell/presentation/app_shell.dart';
import 'package:tonsoku/features/shell/presentation/placeholder_page.dart';

/// ルート定義。
///
/// **パスは Web の URL 構造に合わせてある**（`/coupon` など）。ディープリンク
/// （通知タップ・Universal Links）を後から足す時に、URL からルートへの対応を
/// 書き直さずに済ませるため。ただし**ロケールのパスプレフィックスは持たない**——
/// アプリの表示言語は設定であって URL ではない（gyumesy-frontend-app と同じ）。
///
/// **`/map` は web に無い。** アプリにしか無い面で、URL としても web に存在しない。
abstract final class AppRoutes {
  static const home = '/';
  static const map = '/map';
  static const coupon = '/coupon';
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// タブごとのナビゲータ。**メニューから開く画面を「今のタブの中」に積むために要る**
/// （gyumesy-frontend-app と同じ。シートから普通に push するとルートのナビゲータに
/// 載って下タブごと隠れる）。数はブランチの数と同じ。
final branchNavigatorKeys = List.generate(
  3,
  (_) => GlobalKey<NavigatorState>(),
  growable: false,
);

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.home,
    routes: [
      // **ブランチは下タブの並びと同じ順。** `AppShell` が index で `goBranch` を
      // 呼ぶので、並べ替えるとタブと行き先がずれる。
      //
      // **メニューはブランチを持たない。** web と同じくボトムシートを開くだけで、
      // 画面としては存在しない（`/menu` という URL も web に無い）。
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: branchNavigatorKeys[0],
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const PlaceholderPage(),
              ),
            ],
          ),
          // **マップは中身の無い画面で出す**（ユーザーの判断。実装は後の Issue）。
          // web の「中身の無い面はタブごと出さない」とは逆で、**4 タブの並びを
          // 先に見せることを優先した**。中身を入れる時にこの注記も外すこと
          StatefulShellBranch(
            navigatorKey: branchNavigatorKeys[1],
            routes: [
              GoRoute(
                path: AppRoutes.map,
                builder: (context, state) => const PlaceholderPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: branchNavigatorKeys[2],
            routes: [
              GoRoute(
                path: AppRoutes.coupon,
                builder: (context, state) => const PlaceholderPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
