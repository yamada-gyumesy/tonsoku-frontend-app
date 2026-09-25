import 'package:tonsoku/core/i18n/app_locale.dart';
import 'package:tonsoku/core/i18n/app_messages.dart';

/// GA4 へ送る画面の識別子。gyumesy-frontend-app の同名のものを写した
/// （画面の一覧をとん速のものに合わせ直した）。
///
/// **web の URL と 1 文字違わず同じにする。** 揃っていないと、同じ記事の
/// アプリ側と web 側を突き合わせられない。アプリと web は GA4 の同じプロパティ
/// （`552748808`「とん速 | 松のや速報」）に入っている。
///
/// - **ロケールのプレフィックスと末尾スラッシュを web に合わせる。**
///   日本語はプレフィックス無し（`/`）、英語は `/en/`、中国語は `/zh/`
///   （web の `localePaths` / `withLocale`）
/// - アプリのルーターの内部パスは末尾スラッシュを持たず、ロケールも持たない
///   （`AppRoutes`）ので、**ここで変換を 1 箇所に閉じる**。画面から直接文字列を
///   組ませない
///
/// ## 題（web の `<title>`）の典拠
///
/// web は Zaraz が `page_view` を送り、題は `document.title`（`BaseLayout.astro`
/// の `<title>{title}</title>`）。各ページの `title` は
/// `{ページ名} | {site.titleSuffix}`、ホームだけ `site.defaultTitle`。
class ScreenPath {
  const ScreenPath({
    required this.path,
    required this.title,
    this.screenClassOverride,
    this.screenNameOverride,
  });

  /// [path] の代わりに使うスクリーン クラス。**アプリ固有画面だけが指定する。**
  final String? screenClassOverride;

  /// 題の代わりに使うスクリーン名。**アプリ固有画面だけが指定する**
  /// （[screenName] の doc）。
  final String? screenNameOverride;

  /// GA4 へ送るスクリーン名。**既定は web の `<title>`。**
  ///
  /// 統合ディメンション「ページタイトルとスクリーン名」で web と同じ行に
  /// 並べるため（[title] の doc）。**web に対応が無い画面だけ**、書き換わる
  /// 見出しではなく固定の識別子を使う（`ScreenPath.appOnly`）。
  String get screenName => screenNameOverride ?? title;

  /// web の URL。**[screenClass] としてそのまま GA4 へ送る。**
  ///
  /// 統合ディメンションで web のページパスと対になるのはアプリの
  /// **スクリーン クラス**なので、ここを入れることでパスの列でも web と同じ
  /// 行に並ぶ（[screenClass] の doc）。画面を見分ける識別子でもある
  /// （`TrackScreen` の重複判定・`==` に効く）。
  final String path;

  /// web の `<title>`。**`firebase_screen`（スクリーン名）に入れる。**
  ///
  /// GA4 の統合ディメンション「ページタイトルとスクリーン名」は、web なら
  /// ページタイトル、アプリならスクリーン名を**同じ列**に落とす。ここを
  /// web の `<title>` と 1 文字違わず揃えることで、**同じ画面の app と web が
  /// 1 行に並ぶ**。
  final String title;

  /// GA4 の「スクリーン クラス」（`firebase_screen_class`）。**web の URL。**
  ///
  /// 統合ディメンション「ページパスとスクリーン クラス」は、web ならページ
  /// パス、アプリならスクリーン クラスを**同じ列**に落とす。ここに [path] を
  /// そのまま入れることで、**パスの列でも web と同じ行に並ぶ**。
  ///
  /// **web に無い値を入れないこと。** gyumesy は以前ここに `Home` / `Article`
  /// のような「画面の種類」を入れていたが、**web 側は URL を出すので絶対に
  /// 並ばず、パスでの集計ができなくなっていた**。束ねたい時はスクリーン名の
  /// 前方一致か BigQuery で行う。**この列は web と揃えるためだけに使う。**
  ///
  /// **自動収集では使い物にならないのでここで持つ。** Flutter は Activity /
  /// ViewController が 1 つしか無く、自動の `screen_view` は全画面を
  /// `MainActivity` / `FlutterViewController` の 1 行に潰す（両 OS で自動
  /// 収集を切っている理由）。
  String get screenClass => screenClassOverride ?? path;

  /// ホーム。web は `index.astro` で、題は `site.defaultTitle`。
  factory ScreenPath.home(AppLocale locale, AppMessages t) =>
      ScreenPath(path: _p(locale, '/'), title: t.siteDefaultTitle);

  /// 記事一覧（ホームの「過去の記事を見る」の先）。web の `articles/index.astro`。
  ///
  /// **絞り込みを変えても送り直さない。** web の絞り込み（`CoArticleFilter`）は
  /// 同じページの中で JS が切り替えるだけで、URL も Pageview も変わらない。
  factory ScreenPath.articles(AppLocale locale, AppMessages t) => ScreenPath(
    path: _p(locale, '/articles/'),
    title: _suffixed(t.homeArchiveTitle, t),
  );

  factory ScreenPath.article(
    AppLocale locale,
    AppMessages t, {
    required String slug,
    required String articleTitle,
  }) => ScreenPath(
    path: _p(locale, '/articles/$slug/'),
    title: _suffixed(articleTitle, t),
  );

  factory ScreenPath.calendar(AppLocale locale, AppMessages t) => ScreenPath(
    path: _p(locale, '/calendar/'),
    title: _suffixed(t.calendarPageTitle, t),
  );

  factory ScreenPath.coupon(AppLocale locale, AppMessages t) => ScreenPath(
    path: _p(locale, '/coupon/'),
    title: _suffixed(t.couponPageTitle, t),
  );

  factory ScreenPath.ranking(AppLocale locale, AppMessages t) => ScreenPath(
    path: _p(locale, '/ranking/'),
    title: _suffixed(t.rankingPageTitle, t),
  );

  factory ScreenPath.notifications(AppLocale locale, AppMessages t) =>
      ScreenPath(
        path: _p(locale, '/notifications/'),
        title: _suffixed(t.notificationsTitle, t),
      );

  /// マップ。**web に無い面**なので [ScreenPath.appOnly]（スクリーン名・
  /// スクリーン クラスとも `map`）。
  ///
  /// **`/map/` を名乗らない。** スクリーン クラスは web のページパスと同じ列に
  /// 落ちるので、`/map/` と送ると**web に存在する URL のような行**ができる。
  /// web にいつか `/map/` ができた時、中身の違う 2 つが黙って 1 行に混ざる。
  /// スラッシュの無い `map` なら、パスの列でもアプリだけの行だと一目で分かる
  /// （gyumesy のオンボーディングと同じ扱い）。
  factory ScreenPath.map(AppLocale locale, AppMessages t) =>
      ScreenPath.appOnly(locale, t, name: 'map', title: t.navMap);

  /// ライセンス表記（メニューの「ライセンス」）。**web に無い面**
  /// （[ScreenPath.map] と同じ扱い）。
  factory ScreenPath.licenses(AppLocale locale, AppMessages t) =>
      ScreenPath.appOnly(locale, t, name: 'licenses', title: t.menuLicenses);

  /// **アプリにしか無い画面。** web に対応が無いので `/app/` の下に置く。
  ///
  /// **[path] は GA4 へ届かない**（下で [screenClassOverride] を指定するため）
  /// が、画面を見分ける識別子として web のパスと混ざらない形にしておく。
  ///
  /// **[title] は GA4 へ送らない。** web に対応が無い以上、題を送る理由
  /// （web と同じ行に並べる）が当てはまらない。そのうえ画面の見出しは
  /// 書き換わりうる（オンボーディングの見出しは 2 行組みで改行まで持つ）。
  /// 送ってしまうと、**文言を直した瞬間に GA4 の行が別物になって履歴が割れる。**
  /// web に対応がある画面ならそちらも一緒に動くので揃ったままだが、
  /// ここは片側しか無い。
  ///
  /// なので **[name] をそのままスクリーン名にする**（`onboarding/intro` の
  /// ような単一行の識別子）。[title] は画面の見分け（`==`）には使う。
  factory ScreenPath.appOnly(
    AppLocale locale,
    AppMessages t, {
    required String name,
    required String title,
  }) => ScreenPath(
    path: _p(locale, '/app/$name/'),
    title: _suffixed(title, t),
    screenNameOverride: name,
    // **web に対応が無いので URL で揃える相手が居ない。** 名前をそのまま入れる
    screenClassOverride: name,
  );

  /// ロケールのプレフィックスを付ける。**日本語は付けない**（web と同じ）。
  static String _p(AppLocale locale, String path) =>
      '${locale.pathPrefix}$path';

  /// web の `{ページ名} | {接尾辞}`。
  static String _suffixed(String name, AppMessages t) =>
      '$name | ${t.siteTitleSuffix}';

  @override
  bool operator ==(Object other) =>
      other is ScreenPath &&
      other.path == path &&
      other.title == title &&
      other.screenName == screenName &&
      other.screenClass == screenClass;

  @override
  int get hashCode => Object.hash(path, title, screenName, screenClass);

  @override
  String toString() => 'ScreenPath($path, $title)';
}
