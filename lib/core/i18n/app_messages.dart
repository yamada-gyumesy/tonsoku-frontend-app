import 'package:tonsoku/core/i18n/app_locale.dart';

/// 倍率の整形。**小数点以下が 0 の時は落とす**（`2.0倍` ではなく `2倍`。web の
/// テンプレート文字列が JS の数値をそのまま出すのと同じ見え方にする）。
String _times(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

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
    required this.commonBack,
    required this.commonClose,
    required this.commonShare,
    required this.commonShareArticle,
    required this.commonQuoteSource,
    required this.commonNoArticles,
    required this.filterAll,
    required this.homeLimitedHeading,
    required this.homeLimitedLead,
    required this.homeLimitedNoneThisWeek,
    required this.homeLimitedNonePast,
    required this.homeLimitedEnded,
    required this.homeLimitedShops,
    required this.homeLimitedShopsWithEnded,
    required this.homeLimitedWeek,
    required this.homeLatestHeading,
    required this.homePastArticles,
    required this.homeArchiveTitle,
    required this.articleRelated,
    required this.articleSuccessor,
    required this.articleCharacterComment,
    required this.articleProvisionalTranslation,
    required this.articleTiktokPlay,
    required this.imageViewerLabel,
    required this.homeDealCoupon,
    required this.homeViewCoupon,
    required this.imageViewerCodeNote,
    required this.couponChannelNames,
    required this.couponMatsuyaPoint,
    required this.couponMultiplierName,
    required this.couponBrandCoupon,
    required this.couponBrandReward,
    required this.couponUnnamedOffer,
    required this.couponSourceMark,
    required this.couponDiscountYen,
    required this.couponDiscountRange,
    required this.couponYen,
    required this.couponMultiplier,
    required this.couponPercentRange,
    required this.couponPointAmount,
    required this.couponRequiresEntry,
    required this.couponTier,
    required this.couponMinSpend,
    required this.couponLinkEntryRate,
    required this.couponLinkEntryBrand,
    required this.couponLinkEntry,
    required this.couponLinkDetailRate,
    required this.couponLinkDetailBrand,
    required this.couponLinkDetail,
    required this.couponQrImage,
    required this.couponDetailImage,
    required this.couponNoEndDate,
    required this.couponCapNote,
    required this.couponStartsOnUntil,
    required this.couponUntil,
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

  final String commonBack;
  final String commonClose;
  final String commonShare;

  /// 共有ボタンの読み上げ名（web の `common.shareArticle`）。
  final String commonShareArticle;

  /// 画像の出所の札（`引用元: matsuyafoods.co.jp`）の前置き（web の `common.quoteSource`）。
  final String commonQuoteSource;
  final String commonNoArticles;

  /// 絞り込みの「すべて」（web の `calendar.all`。記事一覧のフィルタも同じ語を使う）。
  final String filterAll;

  // ── ホーム（web の `home.*`）──────────────────────────
  final String homeLimitedHeading;

  /// 店舗限定の説明。**見出しの横にそのまま 1 行で見せる**（「？」で隠すと
  /// 押されない。web のユーザー判断）
  final String homeLimitedLead;
  final String homeLimitedNoneThisWeek;
  final String homeLimitedNonePast;

  /// 終売の判子。
  final String homeLimitedEnded;
  final String Function(int n) homeLimitedShops;
  final String Function(int live, int ended) homeLimitedShopsWithEnded;

  /// 週の見出し。`md` は `9/23` の形（web も数字で組む）。
  final String Function(String md) homeLimitedWeek;
  final String homeLatestHeading;
  final String homePastArticles;

  /// 記事一覧（「過去の記事を見る」の行き先）の見出し。
  final String homeArchiveTitle;

  // ── 記事（web の `article.*`）───────────────────────────
  final String articleRelated;
  final String articleSuccessor;

  /// のや子のひとことの見出し。
  final String articleCharacterComment;

  /// **仮訳の断り**（配信の `translation_stage` が `provisional` の時だけ出す）。
  /// **日本語は空**（原文そのものなので言うことが無い。空文字の時は出さない）。
  final String articleProvisionalTranslation;
  final String articleTiktokPlay;

  /// 全画面の画像の読み上げ名（web の `imageViewer.label`）。
  final String imageViewerLabel;

  // ── クーポン（web の `home.dealCoupon` 等と `coupon.*`）───────────────

  /// TOP の「お得なクーポン」節（券売機で使える X / TikTok のクーポンだけの窓）
  final String homeDealCoupon;

  /// 節の右のクーポンタブへの導線
  final String homeViewCoupon;

  /// QR コードを開いた時の一言
  final String imageViewerCodeNote;

  /// 注文方法の表示名。**表に無い値は ID のまま出る**（`coupon_row.dart` の `_pick`）
  final Map<String, String> couponChannelNames;
  final String couponMatsuyaPoint;
  final String Function(String channel, double times) couponMultiplierName;
  final String Function(String brand) couponBrandCoupon;
  final String Function(String brand) couponBrandReward;
  final String couponUnnamedOffer;

  /// 配布元の印（`【X】`）
  final String Function(String name) couponSourceMark;
  final String Function(String yen) couponDiscountYen;
  final String Function(String min, String max) couponDiscountRange;
  final String Function(String value) couponYen;
  final String Function(double times) couponMultiplier;
  final String Function(String min, String max) couponPercentRange;
  final String Function(String pt) couponPointAmount;
  final String couponRequiresEntry;
  final String Function(String yen, String percent) couponTier;
  final String Function(String yen) couponMinSpend;
  final String Function(String percent) couponLinkEntryRate;
  final String Function(String brand) couponLinkEntryBrand;
  final String couponLinkEntry;
  final String Function(String percent) couponLinkDetailRate;
  final String Function(String brand) couponLinkDetailBrand;
  final String couponLinkDetail;
  final String couponQrImage;
  final String couponDetailImage;
  final String couponNoEndDate;
  final String Function(String yen) couponCapNote;
  final String Function(String start, String end) couponStartsOnUntil;
  final String Function(String date) couponUntil;

  static AppMessages of(AppLocale locale) => switch (locale) {
    AppLocale.ja => ja,
    AppLocale.en => en,
    AppLocale.zh => zh,
  };

  static final ja = AppMessages(
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
    commonBack: '戻る',
    commonClose: '閉じる',
    commonShare: '共有',
    commonShareArticle: 'この記事を共有する',
    commonQuoteSource: '引用元',
    commonNoArticles: '記事がありません',
    filterAll: 'すべて',
    homeLimitedHeading: '店舗限定',
    homeLimitedLead: 'ごく一部の店舗に出現する裏メニュー',
    homeLimitedNoneThisWeek: '今週はなし',
    homeLimitedNonePast: 'この週はなし',
    homeLimitedEnded: '終売',
    homeLimitedShops: (n) => '$n店舗',
    homeLimitedShopsWithEnded: (live, ended) => '$live店舗（終売: $ended店舗）',
    homeLimitedWeek: (md) => '$md週',
    homeLatestHeading: '最新記事',
    homePastArticles: '過去の記事を見る',
    homeArchiveTitle: '記事一覧',
    articleRelated: '関連記事',
    articleSuccessor: 'この記事には最新の記事があります',
    articleCharacterComment: '松のやド素人お嬢のひとこと',
    articleProvisionalTranslation: '',
    articleTiktokPlay: '動画を見る',
    imageViewerLabel: '拡大した画像',
    homeDealCoupon: 'お得なクーポン',
    homeViewCoupon: 'クーポン一覧',
    imageViewerCodeNote: '券売機にかざしてください',
    couponChannelNames: const {
      'matsuben_net': '松弁ネット',
      'matsuben_delivery': '松弁デリバリー',
      'mobile_order': 'モバイルオーダー',
      'store': '店舗',
    },
    couponMatsuyaPoint: '松屋ポイント',
    couponMultiplierName: (channel, times) => '$channel${_times(times)}倍',
    couponBrandCoupon: (brand) => '$brandクーポン',
    couponBrandReward: (brand) => '$brand還元',
    couponUnnamedOffer: 'クーポン',
    couponSourceMark: (name) => '【$name】',
    couponDiscountYen: (yen) => '$yen引き',
    couponDiscountRange: (min, max) => '$min〜$max円引き',
    couponYen: (value) => '$value円',
    couponMultiplier: (times) => '${_times(times)}倍',
    couponPercentRange: (min, max) => '$min〜$max',
    couponPointAmount: (pt) => '+${pt}P',
    couponRequiresEntry: '事前エントリー',
    couponTier: (yen, percent) => '$yen以上で$percent',
    couponMinSpend: (yen) => '$yen以上',
    couponLinkEntryRate: (percent) => '$percentエントリー',
    couponLinkEntryBrand: (brand) => '$brandエントリー',
    couponLinkEntry: 'エントリー',
    couponLinkDetailRate: (percent) => '$percent詳細',
    couponLinkDetailBrand: (brand) => '$brand詳細',
    couponLinkDetail: '詳細',
    couponQrImage: 'QRコード',
    couponDetailImage: '詳細画像',
    couponNoEndDate: '終了未定',
    couponCapNote: (yen) => '上限 $yen',
    couponStartsOnUntil: (start, end) => '$start〜$end',
    couponUntil: (date) => '〜$date',
  );

  static final en = AppMessages(
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
    commonBack: 'Back',
    commonClose: 'Close',
    commonShare: 'Share',
    commonShareArticle: 'Share this article',
    commonQuoteSource: 'Source',
    commonNoArticles: 'No articles yet',
    filterAll: 'All',
    homeLimitedHeading: 'Store Exclusives',
    homeLimitedLead:
        'Secret menu items that appear at only a handful of stores',
    homeLimitedNoneThisWeek: 'None this week',
    homeLimitedNonePast: 'None that week',
    homeLimitedEnded: 'Ended',
    homeLimitedShops: (n) => '$n store${n == 1 ? '' : 's'}',
    homeLimitedShopsWithEnded: (live, ended) =>
        '$live store${live == 1 ? '' : 's'} ($ended ended)',
    homeLimitedWeek: (md) => 'Week of $md',
    homeLatestHeading: 'Latest',
    homePastArticles: 'See older articles',
    homeArchiveTitle: 'All articles',
    articleRelated: 'Related Articles',
    articleSuccessor: 'This article has a newer version',
    articleCharacterComment: 'A word from our Matsunoya novice',
    articleProvisionalTranslation: _enReferenceTranslation,
    articleTiktokPlay: 'Watch video',
    imageViewerLabel: 'Enlarged image',
    homeDealCoupon: 'Coupon deals',
    homeViewCoupon: 'All coupons',
    imageViewerCodeNote: 'Hold this up to the ticket machine.',
    couponChannelNames: const {
      'matsuben_net': 'Matsuben Net',
      'matsuben_delivery': 'Matsuben Delivery',
      'mobile_order': 'Mobile Order',
      'store': 'In store',
    },
    couponMatsuyaPoint: 'Matsuya Points',
    couponMultiplierName: (channel, times) => '$channel ${_times(times)}×',
    couponBrandCoupon: (brand) => '$brand coupon',
    couponBrandReward: (brand) => '$brand cashback',
    couponUnnamedOffer: 'Coupon',
    couponSourceMark: (name) => '[$name] ',
    couponDiscountYen: (yen) => '$yen off',
    couponDiscountRange: (min, max) => '¥$min–¥$max off',
    couponYen: (value) => '¥$value',
    couponMultiplier: (times) => '${_times(times)}×',
    couponPercentRange: (min, max) => '$min–$max',
    couponPointAmount: (pt) => '+$pt pts',
    couponRequiresEntry: 'Sign up first',
    couponTier: (yen, percent) => '$percent from $yen',
    couponMinSpend: (yen) => '$yen+',
    couponLinkEntryRate: (percent) => 'Get $percent',
    couponLinkEntryBrand: (brand) => '$brand sign-up',
    couponLinkEntry: 'Sign up',
    couponLinkDetailRate: (percent) => '$percent details',
    couponLinkDetailBrand: (brand) => '$brand details',
    couponLinkDetail: 'Details',
    couponQrImage: 'QR code',
    couponDetailImage: 'Detail image',
    couponNoEndDate: 'no end date',
    couponCapNote: (yen) => 'Cap $yen',
    couponStartsOnUntil: (start, end) => '$start – $end',
    couponUntil: (date) => 'until $date',
  );

  static final zh = AppMessages(
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
    commonBack: '返回',
    commonClose: '关闭',
    commonShare: '分享',
    commonShareArticle: '分享这篇报道',
    commonQuoteSource: '来源',
    commonNoArticles: '暂无报道',
    filterAll: '全部',
    homeLimitedHeading: '店铺限定',
    homeLimitedLead: '只在极少数门店出现的隐藏菜单',
    homeLimitedNoneThisWeek: '本周没有',
    homeLimitedNonePast: '该周没有',
    homeLimitedEnded: '已停售',
    homeLimitedShops: (n) => '$n家门店',
    homeLimitedShopsWithEnded: (live, ended) => '$live家门店（$ended家已停售）',
    homeLimitedWeek: (md) => '$md周',
    homeLatestHeading: '最新文章',
    homePastArticles: '查看以往文章',
    homeArchiveTitle: '全部文章',
    articleRelated: '相关报道',
    articleSuccessor: '本文有更新版报道',
    articleCharacterComment: '松乃家新手小姐的点评',
    articleProvisionalTranslation: _zhReferenceTranslation,
    articleTiktokPlay: '观看视频',
    imageViewerLabel: '放大的图片',
    homeDealCoupon: '超值优惠券',
    homeViewCoupon: '优惠券列表',
    imageViewerCodeNote: '请将此二维码对准售票机扫描。',
    couponChannelNames: const {
      'matsuben_net': '松弁网',
      'matsuben_delivery': '松弁外送',
      'mobile_order': '手机点餐',
      'store': '门店',
    },
    couponMatsuyaPoint: '松屋积分',
    couponMultiplierName: (channel, times) => '$channel${_times(times)}倍',
    couponBrandCoupon: (brand) => '$brand优惠券',
    couponBrandReward: (brand) => '$brand返还',
    couponUnnamedOffer: '优惠券',
    couponSourceMark: (name) => '【$name】',
    couponDiscountYen: (yen) => '减$yen',
    couponDiscountRange: (min, max) => '减$min〜$max日元',
    couponYen: (value) => '$value日元',
    couponMultiplier: (times) => '${_times(times)}倍',
    couponPercentRange: (min, max) => '$min〜$max',
    couponPointAmount: (pt) => '+$pt积分',
    couponRequiresEntry: '需事先报名',
    couponTier: (yen, percent) => '满$yen为$percent',
    couponMinSpend: (yen) => '$yen以上',
    couponLinkEntryRate: (percent) => '领取$percent',
    couponLinkEntryBrand: (brand) => '$brand报名',
    couponLinkEntry: '报名',
    couponLinkDetailRate: (percent) => '$percent详情',
    couponLinkDetailBrand: (brand) => '$brand详情',
    couponLinkDetail: '详情',
    couponQrImage: '二维码',
    couponDetailImage: '详情图片',
    couponNoEndDate: '结束日未定',
    couponCapNote: (yen) => '上限 $yen',
    couponStartsOnUntil: (start, end) => '$start〜$end',
    couponUntil: (date) => '至$date',
  );
}

/// 仮訳の断り。web の `REFERENCE_TRANSLATION`（`src/i18n/messages/en.ts` / `zh.ts`）。
const _enReferenceTranslation =
    'This is a reference translation. '
    'The Japanese version is the authoritative original.';
const _zhReferenceTranslation = '本文为参考译文，正式版本以日语原文为准。';
