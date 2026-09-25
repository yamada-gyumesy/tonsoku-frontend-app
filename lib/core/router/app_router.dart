import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tonsoku/features/article/presentation/article_page.dart';
import 'package:tonsoku/features/calendar/presentation/calendar_page.dart';
import 'package:tonsoku/features/coupon/presentation/coupon_page.dart';
import 'package:tonsoku/features/ranking/presentation/ranking_page.dart';
import 'package:tonsoku/features/home/presentation/article_list_page.dart';
import 'package:tonsoku/features/home/presentation/home_page.dart';
import 'package:tonsoku/features/map/presentation/map_page.dart';
import 'package:tonsoku/features/shell/presentation/app_shell.dart';

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

  /// タブごとの接頭辞（**ブランチの並びと同じ順**）。メニューから開く画面を
  /// **今のタブの中に積む**時に使う（下タブを隠さず、戻るとそのタブへ帰る。
  /// 記事詳細を各タブに積むのと同じ考え方）。
  static const branchPrefixes = ['', map, coupon];

  /// ランキング（web の `/ranking/`）。[prefix] は [branchPrefixes] の 1 つ。
  static String ranking(String prefix) => '$prefix/ranking';

  /// カレンダー（web の `/calendar/`）。[prefix] は [branchPrefixes] の 1 つ。
  ///
  /// [category] を渡すとそのカテゴリで絞って開く（`?category=campaign`。
  /// クーポンの「カレンダーをみる」が使う）。web は `#category=` のハッシュで
  /// 渡しているが、あれはクエリだと別 URL としてクロールされるのを避けるため
  /// で、アプリには当たらない。**クエリで持つ**のは、ルートの外（通知・
  /// Universal Links）から来る時にも同じ形で書けるから。
  ///
  /// **省略できる引数しか足さない**（メニューの `_openFromMenu` が
  /// `String Function(String prefix)` として受け取る）。
  static String calendar(String prefix, {String? category}) => Uri(
    path: '$prefix/calendar',
    queryParameters: category == null ? null : {'category': category},
  ).toString();
}

/// 記事詳細のルート。**どのタブの中にも積む**（タブを切り替えても読みかけの記事が
/// 残り、戻ると元の画面に戻れる。gyumesy と同じ）。
///
/// 関連記事・後継記事は**同じタブの中に積み重ねる**（戻るで辿ってきた記事へ順に
/// 戻れる）。積む先は `context.push` の相対パスではなく、そのタブの接頭辞を持った
/// 絶対パスで決める —— 接頭辞を落とすとホームのタブへ飛ばされる。
/// ランキングのルート。**どのタブの中にも積む**（メニューはタブを持たないので、
/// 開いた時にいたタブの中に積む。[articleRoute] と同じ理由で接頭辞を持つ）。
GoRoute rankingRoute(String prefix) => GoRoute(
  path: 'ranking',
  builder: (context, state) => RankingPage(
    onOpenArticle: (slug) => context.push('$prefix/articles/$slug'),
  ),
);

/// カレンダーのルート。**どのタブの中にも積む**（[rankingRoute] と同じ理由）。
///
/// **絞るカテゴリは `?category=` で受ける**（[AppRoutes.calendar]）。画面は
/// 開くたびに積むので、値は画面の `initState` で 1 度読めば足りる
/// （gyumesy はカレンダーがタブで、同じ画面に何度も値が届くので URL と
/// 画面を揃え続けていた）。
GoRoute calendarRoute(String prefix) => GoRoute(
  path: 'calendar',
  builder: (context, state) => CalendarPage(
    initialCategory: state.uri.queryParameters['category'],
    onOpenArticle: (slug) => context.push('$prefix/articles/$slug'),
  ),
);

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
                  calendarRoute(''),
                  rankingRoute(''),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: branchNavigatorKeys[1],
            routes: [
              GoRoute(
                path: AppRoutes.map,
                builder: (context, state) => MapPage(
                  // **品の記事はマップのタブの上に積む**（戻るとマップへ帰る。
                  // 見ていた位置と絞り込みはそのまま残る）
                  onOpenArticle: (slug) =>
                      context.push('${AppRoutes.map}/articles/$slug'),
                ),
                // メニューから開く画面と、そこから開く記事を積む
                routes: [
                  articleRoute(AppRoutes.map),
                  calendarRoute(AppRoutes.map),
                  rankingRoute(AppRoutes.map),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: branchNavigatorKeys[2],
            routes: [
              GoRoute(
                path: AppRoutes.coupon,
                builder: (context, state) => CouponPage(
                  // **記事はクーポンタブの上に積む**（戻るとクーポンへ帰る）
                  onOpenArticle: (slug) =>
                      context.push('${AppRoutes.coupon}/articles/$slug'),
                  // **カレンダーもクーポンタブの上に積む**（記事と同じく、戻ると
                  // クーポンへ帰る。メニューから開いた時と違い、タブを移っても
                  // 畳まない —— クーポンの画面から開いたものなので、そのタブに属する）
                  onOpenCalendar: (category) => context.push(
                    AppRoutes.calendar(AppRoutes.coupon, category: category),
                  ),
                ),
                routes: [
                  articleRoute(AppRoutes.coupon),
                  calendarRoute(AppRoutes.coupon),
                  rankingRoute(AppRoutes.coupon),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
