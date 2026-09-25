import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tonsoku/features/article/presentation/article_page.dart';
import 'package:tonsoku/features/home/presentation/article_list_page.dart';
import 'package:tonsoku/features/home/presentation/home_page.dart';
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

  /// 記事一覧（ホームの「過去の記事を見る」の先）。web の `/articles/`。
  static const articles = '/articles';

  static String article(String slug) => '/articles/$slug';
}

/// 記事詳細のルート。**どのタブの中にも積む**（タブを切り替えても読みかけの記事が
/// 残り、戻ると元の画面に戻れる。gyumesy と同じ）。
///
/// 関連記事・後継記事は**同じタブの中に積み重ねる**（戻るで辿ってきた記事へ順に
/// 戻れる）。積む先は `context.push` の相対パスではなく、そのタブの接頭辞を持った
/// 絶対パスで決める —— 接頭辞を落とすとホームのタブへ飛ばされる。
GoRoute articleRoute(String prefix) => GoRoute(
  path: 'articles/:slug',
  builder: (context, state) => ArticlePage(
    slug: state.pathParameters['slug']!,
    onOpenArticle: (next) => context.push('$prefix/articles/$next'),
  ),
);

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
                builder: (context, state) => HomePage(
                  onOpenArticle: (slug) =>
                      context.push(AppRoutes.article(slug)),
                  onOpenArchive: () => context.push(AppRoutes.articles),
                  // **クーポンはタブなので、積まずにタブごと切り替える**
                  onOpenCoupon: () => context.go(AppRoutes.coupon),
                ),
                routes: [
                  GoRoute(
                    path: 'articles',
                    builder: (context, state) => ArticleListPage(
                      onOpenArticle: (slug) =>
                          context.push(AppRoutes.article(slug)),
                    ),
                  ),
                  articleRoute(''),
                ],
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
