import 'package:tonsoku/core/i18n/app_locale.dart';

/// UI 固定文言。配信データ側の文言（カテゴリ名・タグ名・カレンダーの予定名）は
/// 多言語化済みで届くので、**受け取った値をそのまま出す**。ここには入れない。
///
/// **文言は web（`tonsoku-frontend-web` の `src/i18n/messages/`）から写す。**
/// 同じ面を同じ言葉で呼ばないと、web とアプリを行き来した人が別物だと思う。
/// web に無い語（マップ）だけがこちらの責任。
///
/// **キーの追加は日本語から。** Web も `ja.ts` を `Messages` 型の元にしており、
/// 訳が用意できていないキーが型で止まるようにしてある（コンストラクタの
/// `required` がその役を持つ）。
class AppMessages {
  const AppMessages({
    required this.appName,
    required this.tagline,
    required this.navLabel,
    required this.navHome,
    required this.navMap,
    required this.navCoupon,
    required this.navMenu,
    required this.commonLoading,
    required this.commonError,
    required this.commonRetry,
  });

  /// アプリ名・ヘッダーのロゴの右（web の `site.name`）。
  final String appName;

  /// ロゴの右に出す短い説明（web の `site.tagline`）。
  final String tagline;

  /// 下タブ全体の読み上げ名（web の `nav.label`）。
  final String navLabel;

  final String navHome;

  /// **web に無い面。** 訳はこちらで決めた（en は `Map`、zh は `地图`）。
  final String navMap;
  final String navCoupon;
  final String navMenu;

  final String commonLoading;
  final String commonError;

  /// 取得に失敗した時の「もう一度」（gyumesy-frontend-app と同じ語）。
  final String commonRetry;

  static AppMessages of(AppLocale locale) => switch (locale) {
    AppLocale.ja => ja,
    AppLocale.en => en,
    AppLocale.zh => zh,
  };

  static const ja = AppMessages(
    appName: 'とん速',
    tagline: '松のや速報',
    navLabel: 'メインメニュー',
    navHome: 'ホーム',
    navMap: 'マップ',
    navCoupon: 'クーポン',
    navMenu: 'メニュー',
    commonLoading: '読み込み中...',
    commonError: 'エラーが発生しました',
    commonRetry: '再読み込み',
  );

  static const en = AppMessages(
    appName: 'Tonsoku',
    tagline: 'Matsunoya News',
    navLabel: 'Main navigation',
    navHome: 'Home',
    navMap: 'Map',
    navCoupon: 'Coupons',
    navMenu: 'Menu',
    commonLoading: 'Loading...',
    commonError: 'Something went wrong',
    commonRetry: 'Retry',
  );

  static const zh = AppMessages(
    appName: '豚速',
    tagline: '松乃家快报',
    navLabel: '主导航',
    navHome: '首页',
    navMap: '地图',
    navCoupon: '优惠券',
    navMenu: '菜单',
    commonLoading: '加载中…',
    commonError: '发生错误',
    commonRetry: '重新加载',
  );
}
