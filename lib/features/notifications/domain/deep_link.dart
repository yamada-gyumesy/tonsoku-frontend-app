/// 外から渡された URL（通知の `data.url`）の開き先の解決。**受け口はここ 1 本。**
///
/// gyumesy-frontend-app の `deep_link.dart`（#90 で一本化したもの）を写し、
/// とん速の画面構成に合わせ直した。
///
/// **入力は配信の `data.url` だけ。** 送る側（tonsoku-backend-batch の
/// `app/notify/push.py`）は `https://ton-soku.com/articles/{slug}/` を入れてくる。
/// `slug` / `category` から組み立て直すと、**面が増えるたびにアプリ側も
/// 直さないと落とす**。URL のパスを見れば増えた面も同じ経路で拾える。
///
/// **アプリに無い面は外部ブラウザへ逃がす。** 配信側に面が増えた時、アプリの
/// 更新を待たずに読めるようにする（落とすより開くほうがまし）。
///
/// **ユニバーサルリンク / App Links（リリース整備の Issue #9）もここへ合流させる。**
/// 入口は別でも行き先の決め方は同じなので、分けて持つと片方だけ面が増えた時に
/// 食い違う。**名乗る面（`AndroidManifest.xml` の intent-filter）は、ここが開ける
/// 面だけにすること**（`deep_link_test.dart` が止める）。
library;

import 'package:tonsoku/core/router/app_router.dart';

/// 開く先。**開けなければ null**（呼び手が外部ブラウザへ回す）。
///
/// **2 種類ある。** とん速ではカレンダー・ランキング・通知設定が**メニューから
/// 開く画面**で、どのタブにも属さない（下タブはホーム / マップ / クーポン）。
/// これらは「いま居るタブの中に積む」ので、**どのタブに積むかを知っている
/// シェル（`AppShell`）に任せる**（[MenuScreenTarget]）。gyumesy は通知設定だけが
/// これに当たり（カレンダー・ランキングは下タブ）、`NotificationsTarget` として
/// 持っていたものを広げた。
///
/// gyumesy にある `CategoryTarget` は持たない —— とん速のホームにはカテゴリの
/// タブが無く、`/category/{slug}/` は開けない面（外部ブラウザへ回す）。
sealed class DeepLinkTarget {
  const DeepLinkTarget();
}

/// go_router の行き先（`go` で移る）。
final class RouteTarget extends DeepLinkTarget {
  const RouteTarget(this.location);

  final String location;

  @override
  bool operator ==(Object other) =>
      other is RouteTarget && other.location == location;

  @override
  int get hashCode => location.hashCode;

  @override
  String toString() => 'RouteTarget($location)';
}

/// メニューから開く画面。**いま居るタブの接頭辞を渡して行き先を組む**
/// （[AppRoutes.branchPrefixes] の 1 つ）。
///
/// **比較できるよう、関数ではなく種類とクエリで持つ。** 関数を持たせると
/// テストで同じ行き先かを確かめられない。
final class MenuScreenTarget extends DeepLinkTarget {
  const MenuScreenTarget(this.screen, {this.category});

  final MenuScreen screen;

  /// カレンダーを絞るカテゴリ（web の `/calendar/#category=campaign`）。
  final String? category;

  /// 積む先の行き先。[prefix] は [AppRoutes.branchPrefixes] の 1 つ。
  String location(String prefix) => switch (screen) {
    MenuScreen.calendar => AppRoutes.calendar(prefix, category: category),
    MenuScreen.ranking => AppRoutes.ranking(prefix),
    MenuScreen.notifications => AppRoutes.notifications(prefix),
  };

  @override
  bool operator ==(Object other) =>
      other is MenuScreenTarget &&
      other.screen == screen &&
      other.category == category;

  @override
  int get hashCode => Object.hash(screen, category);

  @override
  String toString() => 'MenuScreenTarget($screen, category: $category)';
}

/// メニューから開く画面の種類。
enum MenuScreen { calendar, ranking, notifications }

/// アプリ内で開ける先。**開けなければ null**（呼び手が外部ブラウザへ回す）。
///
/// 受け取るのは `https://ton-soku.com/articles/xxx/` のような正準 URL。
/// [siteHost] は web 版のホスト（`AppConfig.siteHost`。ドメインを直書きしない）。
DeepLinkTarget? deepLinkTarget(String? url, {required String siteHost}) {
  if (url == null || url.isEmpty) return null;
  final uri = Uri.tryParse(url.trim());
  if (uri == null) return null;

  // **自分のサイト以外は開かない。** 通知に他所の URL が入っていても、
  // アプリの画面として開くと出所が分からなくなる。
  // **ホストの無い値（`not a url` のような文字列）も開かない。** 相対パスとして
  // 解釈されて、たまたま面の名前と一致すると開いてしまう
  if (uri.host != siteHost) return null;

  // **空のセグメントを落とす。** 正準 URL は末尾スラッシュ付きなので
  // `pathSegments` の末尾に `''` が入る（`/en/` は `['en', '']`）
  final segments = [
    for (final s in uri.pathSegments)
      if (s.isNotEmpty) s,
  ];
  // **ロケールのプレフィックスは捨てる。** アプリの表示言語は設定であって
  // URL ではない（`AppRoutes` の doc）。`/en/articles/x/` も記事へ送る
  if (segments.isNotEmpty && const {'en', 'zh'}.contains(segments.first)) {
    segments.removeAt(0);
  }

  if (segments.isEmpty) return const RouteTarget(AppRoutes.home);

  return switch (segments) {
    // 記事。**ホームのタブの中に積む**（gyumesy と同じ）
    ['articles', final slug] => RouteTarget(AppRoutes.article(slug)),
    // 記事一覧（web の `/articles/`。ホームの「過去の記事を見る」の先）
    ['articles'] => const RouteTarget(AppRoutes.articles),
    ['coupon'] => const RouteTarget(AppRoutes.coupon),
    // **カレンダーの絞り込みは web ではハッシュで渡る**（`#category=campaign`。
    // クエリだと別 URL としてクロールされるのを避けた web の都合）。
    // アプリはクエリで持つので読み替える（[AppRoutes.calendar]）
    ['calendar'] => MenuScreenTarget(
      MenuScreen.calendar,
      category: _hashParam(uri.fragment, 'category'),
    ),
    ['ranking'] => const MenuScreenTarget(MenuScreen.ranking),
    ['notifications'] => const MenuScreenTarget(MenuScreen.notifications),
    // **about・legal・category はアプリに画面が無い**（about・legal は意図して
    // web で表示する方針。category はホームにタブが無い）。ここで無理に近い
    // 画面へ寄せると、押した見出しと違うものが出る。
    // **知らない深さも開かない**（`/articles/x/y/` など。web に無い URL）
    _ => null,
  };
}

/// `category=campaign&month=2026-09` の形のハッシュから 1 つ取り出す。
String? _hashParam(String fragment, String key) {
  if (fragment.isEmpty) return null;
  try {
    final value = Uri.splitQueryString(fragment)[key];
    return value == null || value.isEmpty ? null : value;
  } on FormatException {
    return null;
  }
}
