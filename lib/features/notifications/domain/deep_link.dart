/// 外から渡された URL（通知の `data.url`・ユニバーサルリンク / App Links）の
/// 開き先の解決。**受け口はここ 1 本。**
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
/// **ユニバーサルリンク / App Links もここへ合流させている**（`app.dart` の
/// `_listenAppLinks`）。入口は別でも行き先の決め方は同じなので、分けて持つと
/// 片方だけ面が増えた時に食い違う。**名乗る面（`AndroidManifest.xml` の
/// intent-filter と、web の `apple-app-site-association`）は、ここが開ける面
/// だけにすること**（Android 側は `deep_link_test.dart` が止める。web 側の
/// 中身は `docs/deep-links.md`）。**ここで開ける面を増やしたら、両方も広げる。**
library;

import 'package:tonsoku/core/router/app_router.dart';
import 'package:tonsoku/features/map/domain/map_link_filter.dart';

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
  const MenuScreenTarget(this.screen, {this.category, this.month});

  final MenuScreen screen;

  /// カレンダーを絞るカテゴリ（web の `/calendar/#category=campaign`）。
  final String? category;

  /// カレンダーで開く月（`YYYY-MM`。web の `/calendar/#month=2026-09`）。
  /// **ここでは確かめない。** 形と範囲はカレンダーの画面が見て、外れていれば
  /// 既定の月で開く（`CalendarPage` の `_openingMonth`）。
  final String? month;

  /// 積む先の行き先。[prefix] は [AppRoutes.branchPrefixes] の 1 つ。
  String location(String prefix) => switch (screen) {
    MenuScreen.calendar => AppRoutes.calendar(
      prefix,
      category: category,
      month: month,
    ),
    MenuScreen.ranking => AppRoutes.ranking(prefix),
    MenuScreen.notifications => AppRoutes.notifications(prefix),
  };

  @override
  bool operator ==(Object other) =>
      other is MenuScreenTarget &&
      other.screen == screen &&
      other.category == category &&
      other.month == month;

  @override
  int get hashCode => Object.hash(screen, category, month);

  @override
  String toString() =>
      'MenuScreenTarget($screen, category: $category, month: $month)';
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
    // **マップのタブ。絞り込みは web ではハッシュで渡る**（`#menu=…&brand=…`。
    // カレンダーと同じ形。web の `/map/` はアプリへ誘導する LP で、そこの
    // リンクがこの形で来る）。アプリはクエリで持つので読み替える
    // （[MapLinkFilter]）。**読めなければ素の `/map`**（今の絞り込みに触らない）
    ['map'] => RouteTarget(
      MapLinkFilter.fromFragment(uri.fragment)?.location ?? AppRoutes.map,
    ),
    // **カレンダーの絞り込みは web ではハッシュで渡る**（`#category=campaign`・
    // `#month=2026-09`。クエリだと別 URL としてクロールされるのを避けた web の
    // 都合）。アプリはクエリで持つので読み替える（[AppRoutes.calendar]）
    ['calendar'] => MenuScreenTarget(
      MenuScreen.calendar,
      category: _hashParam(uri.fragment, 'category'),
      month: _hashParam(uri.fragment, 'month'),
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
