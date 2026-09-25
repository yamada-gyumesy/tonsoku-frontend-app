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
    required this.navRanking,
    required this.rankingPageTitle,
    required this.rankingDaily,
    required this.rankingWeekly,
    required this.rankingMonthly,
    required this.rankingTabGroup,
    required this.rankingUpdatedAt,
    required this.rankingRank,
    required this.rankingEmpty,
    required this.navCalendar,
    required this.calendarPageTitle,
    required this.calendarViewCalendar,
    required this.calendarPrevMonth,
    required this.calendarNextMonth,
    required this.calendarToday,
    required this.calendarAll,
    required this.calendarLineCategoryGroup,
    required this.calendarEventCount,
    required this.calendarWeekdays,
    required this.calendarWeekdayColumnWidth,
    required this.calendarMonthLabel,
    required this.calendarMonthOnly,
    required this.commonOfficial,
    required this.navAbout,
    required this.navTerms,
    required this.navPrivacy,
    required this.themeLabel,
    required this.themeLight,
    required this.themeDark,
    required this.languageLabel,
    required this.menuOther,
    required this.menuLicenses,
    required this.menuVersion,
    required this.licenseIntro,
    required this.licenseCount,
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
    required this.couponPageTitle,
    required this.couponUpdatedAt,
    required this.couponDisclaimer,
    required this.couponOffersHeading,
    required this.couponOffersEmpty,
    required this.couponPeriodLabel,
    required this.couponTimeWindowLabel,
    required this.couponConditionsLabel,
    required this.couponUpcomingHeading,
    required this.couponBestHeading,
    required this.couponCapOnlyNote,
    required this.couponRankAssumeNote,
    required this.couponTargetNote,
    required this.couponPatternsLead,
    required this.couponPatternsLeadPlain,
    required this.couponRewardLabel,
    required this.couponTotalLabel,
    required this.couponBackLabel,
    required this.couponNetLabel,
    required this.couponScheduleHeading,
    required this.couponTypesHeading,
    required this.couponTypeMobileOrder,
    required this.couponTypeMatsubenNet,
    required this.couponTypeXCoupon,
    required this.couponTypeTiktokCoupon,
    required this.couponTypeDiscountFair,
    required this.couponRankNames,
    required this.couponStartBracket,
    required this.couponStartsOn,
    required this.mapStandalone,
    required this.mapBrandMatsuya,
    required this.mapBrandMycurry,
    required this.mapIncludeInactive,
    required this.mapSelling,
    required this.mapUpcoming,
    required this.mapLegendLabel,
    required this.mapMyLocation,
    required this.mapNorthUp,
    required this.mapSearchHint,
    required this.mapShopsUnit,
    required this.mapMenuShops,
    required this.mapHeadingUp,
    required this.mapLocationUnavailable,
    required this.mapOpenInGoogleMaps,
    required this.mapAddress,
    required this.mapHours,
    required this.mapPhone,
    required this.mapCall,
    required this.mapDateTime,
    required this.mapDate,
    required this.mapStartsAt,
    required this.mapEndedAt,
    required this.mapTempClosed,
    required this.mapTempClosedUntil,
    required this.mapTempClosedPlanned,
    required this.mapOpensAt,
    required this.mapClosesAt,
    required this.mapClosed,
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

  /// ランキング（web の `nav.ranking` と `ranking.*`）。
  final String navRanking;
  final String rankingPageTitle;
  final String rankingDaily;
  final String rankingWeekly;
  final String rankingMonthly;
  final String rankingTabGroup;
  final String Function(String date) rankingUpdatedAt;
  final String Function(int rank) rankingRank;
  final String rankingEmpty;

  /// カレンダー（web の `nav.calendar` と `calendar.*`）。
  final String navCalendar;

  /// 画面の見出し。**「カレンダー」ではなく「松のやカレンダー」**（web と同じ。
  /// 何のカレンダーかがメニューの行の名前だけでは伝わらない）。
  final String calendarPageTitle;

  /// クーポンのスケジュールの見出しから飛ぶ導線（web の `calendar.viewCalendar`）。
  final String calendarViewCalendar;
  final String calendarPrevMonth;
  final String calendarNextMonth;
  final String calendarToday;

  /// 絞り込みの「すべて」。**この時だけ線を出さない**（線は 1 カテゴリに
  /// 絞らないと、常時並走するキャンペーンや一時閉店で画面が線だらけになる）。
  final String calendarAll;

  /// 線を出すカテゴリを選ぶ操作全体の読み上げ名。
  final String calendarLineCategoryGroup;

  /// 1 本の線がまとめている予定の件数（線の読み上げ名）。**英語は単数形を持つ**
  /// （`1 events` は誤り。web と同じ）。
  final String Function(int count) calendarEventCount;

  /// 曜日。**日曜始まり**（web の `calendar.weekdays` と同じ並び）。
  final List<String> calendarWeekdays;

  /// 日リストの日付列の幅。**[calendarWeekdays] の長さで決まるのでここに置く**
  /// （gyumesy と同じ）。日本語・中国語は 1 文字だが英語は 3 文字（`Wed`）で、
  /// web の `w-11`（44）のままだと溢れる。
  final double calendarWeekdayColumnWidth;

  /// 月の見出し。**言語で語順が違う**（`2026年9月` / `September 2026`）。
  final String Function(int year, int month) calendarMonthLabel;

  /// 日リストが月をまたぐ時の見出し（`10月`）。web の `calendar.monthOnly`。
  final String Function(int month) calendarMonthOnly;

  /// 出典チップの語（web の `common.official`）。**配信の `source_label` を
  /// 使わないこと**（全ロケールで日本語のまま届く。gyumesy と同じ判断）。
  ///
  /// **「公式」はとん速のことではない。** 出どころが松のや公式である、という意味
  /// （web の `CmSourceChip` の注記）。
  final String commonOfficial;

  /// メニューの行（web の `nav.*`。法務は web のフッターの `LEGAL_PAGES` のうち特商法を除く 2 つ）。
  final String navAbout;
  final String navTerms;
  final String navPrivacy;

  /// 外観の切替（web の `theme.*`）。
  final String themeLabel;
  final String themeLight;
  final String themeDark;
  final String languageLabel;

  /// メニューの「その他」（アプリ独自。web はフッターに置いている法務とライセンス・版）。
  /// 文言は gyumesy-frontend-app と同じ。
  final String menuOther;
  final String menuLicenses;
  final String menuVersion;
  final String licenseIntro;

  /// ライセンス表記の件数。**英語は単数形を持つ**（`1 licenses` は誤り。gyumesy と同じ）。
  final String Function(int count) licenseCount;

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

  // ── クーポン画面（web の `coupon.*`。`pages/[...locale]/coupon.astro` と
  // `CoCoupon*`）────────────────────────────────────────────
  final String couponPageTitle;

  /// 一覧の見出しに添える時点。**日付と「時点」の間は空ける**（詰めると
  /// 「2026年9月25日時点」の末尾が時刻に見える）。
  final String Function(String date) couponUpdatedAt;
  final String couponDisclaimer;
  final String couponOffersHeading;
  final String couponOffersEmpty;
  final String couponPeriodLabel;
  final String couponTimeWindowLabel;
  final String couponConditionsLabel;
  final String couponUpcomingHeading;
  final String couponBestHeading;
  final String Function(String cap) couponCapOnlyNote;
  final String Function(String rank, String percent) couponRankAssumeNote;
  final String Function(String target) couponTargetNote;
  final String Function(String target) couponPatternsLead;
  final String couponPatternsLeadPlain;
  final String couponRewardLabel;
  final String couponTotalLabel;
  final String couponBackLabel;
  final String couponNetLabel;
  final String couponScheduleHeading;
  final String couponTypesHeading;

  /// 種類表（`CouponTypesTable`）の 1 行。**一覧の行に用語を書く代わりに、
  /// ここで一度だけ説明する。**
  final CouponTypeText couponTypeMobileOrder;
  final CouponTypeText couponTypeMatsubenNet;
  final CouponTypeText couponTypeXCoupon;
  final CouponTypeText couponTypeTiktokCoupon;
  final CouponTypeText couponTypeDiscountFair;

  /// 会員ランクの表示名。**表に無い ID はそのまま出る**（`_pick`）。
  final Map<String, String> couponRankNames;
  final String Function(String start) couponStartBracket;

  /// スケジュールの帯の開始日（`9/5〜`）。**「〜」を落とさないこと**
  /// （日付だけだとその日限りの予定に見える）。
  final String Function(String start) couponStartsOn;

  // ── マップ（**web に無い面**。訳はこちらで決めた）──────────────

  /// 併設のフィルタ（`ShopBrand`）。**松屋・マイカリー食堂は固有名**なので訳さない
  /// （英語は `Matsuya` / `My Curry Shokudo`）。
  final String mapBrandMatsuya;
  final String mapBrandMycurry;

  /// 何も併設していない店の絞り込み（`isStandalone`）。併設のチップの先頭に置く。
  final String mapStandalone;

  /// 品のチップの下に出すチェック（品を選ぶまでは押せない）。
  final String mapIncludeInactive;

  /// 店ごとの品の状態（店の詳細の各行）。**終売は [homeLimitedEnded] を使う**
  /// （web の週カードの判子と同じ語）。凡例の販売中の印は「販売中」ではなく
  /// [homeLimitedHeading]（「店舗限定」。ユーザーの判断）。
  final String mapSelling;
  final String mapUpcoming;

  /// 凡例全体の読み上げ名。
  final String mapLegendLabel;
  final String mapMyLocation;

  /// 地図の向きのボタン（読み上げ）。いまの向きを言う。
  final String mapNorthUp;

  /// 地図の検索バー（店を店名・ローマ字名・店舗番号で探す）。
  final String mapSearchHint;

  /// 出している店の数の丸（`ShopCountBadge`）の、数の下の単位。
  final String mapShopsUnit;

  /// 店舗限定の品のチップの店の数（終売を含めた合計と、終売の数。
  /// 終売が無ければ合計だけ。ユーザーの指定の文言）。
  final String Function(int total, int ended) mapMenuShops;
  final String mapHeadingUp;
  final String mapLocationUnavailable;
  final String mapOpenInGoogleMaps;
  final String mapAddress;
  final String mapHours;
  final String mapPhone;

  /// 電話をかける操作の読み上げ名。
  final String Function(String phone) mapCall;

  /// 時刻つきの日付（JST）。**日本語・中国語は時まで**（記事の取扱店の表の
  /// 「9/13 21時 終売」と同じ粒度）。英語は分まで出す（`21時` に当たる短い
  /// 書き方が無く、`:00` を付けると分を丸めたことが読めなくなる）。
  final String Function(int month, int day, int hour, int minute) mapDateTime;
  final String Function(int month, int day) mapDate;
  final String Function(String when) mapStartsAt;
  final String Function(String when) mapEndedAt;

  /// 一時閉店・開店・閉店の状態（店の詳細の上に出す）。
  final String mapTempClosed;
  final String Function(String reopens) mapTempClosedUntil;

  /// これからの一時閉店。[until] は再開日で、無ければ null。
  final String Function(String from, String? until) mapTempClosedPlanned;
  final String Function(String when) mapOpensAt;
  final String Function(String when) mapClosesAt;
  final String mapClosed;

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
    navRanking: 'ランキング',
    rankingPageTitle: 'ランキング',
    rankingDaily: 'デイリー',
    rankingWeekly: 'ウィークリー',
    rankingMonthly: 'マンスリー',
    rankingTabGroup: '集計期間',
    rankingUpdatedAt: (date) => '更新日：$date',
    rankingRank: (rank) => '$rank位',
    rankingEmpty: 'まだランキングがありません',
    navCalendar: 'カレンダー',
    calendarPageTitle: '松のやカレンダー',
    calendarViewCalendar: 'カレンダーをみる',
    calendarPrevMonth: '前の月',
    calendarNextMonth: '次の月',
    calendarToday: '今日',
    calendarAll: 'すべて',
    calendarLineCategoryGroup: '線を表示するカテゴリ',
    calendarEventCount: (n) => '$n件の予定',
    calendarWeekdays: const ['日', '月', '火', '水', '木', '金', '土'],
    calendarWeekdayColumnWidth: 44,
    calendarMonthLabel: (year, month) => '$year年$month月',
    calendarMonthOnly: (month) => '$month月',
    commonOfficial: '公式',
    navAbout: 'とん速とは',
    navTerms: '利用規約',
    navPrivacy: 'プライバシーポリシー',
    themeLabel: '外観モード',
    themeLight: 'ライトモード',
    themeDark: 'ダークモード',
    languageLabel: '言語',
    menuOther: 'その他',
    menuLicenses: 'ライセンス表記',
    menuVersion: 'バージョン',
    licenseIntro: 'このアプリは次のオープンソースソフトウェアを利用しています。',
    licenseCount: (count) => 'ライセンス $count 件',
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
    couponPageTitle: '松のやのクーポン',
    couponUpdatedAt: (date) => '$date 時点',
    couponDisclaimer: '公開情報をもとにした独自まとめです。条件は各社の公式情報もあわせて確認してください。',
    couponOffersHeading: '現在使えるクーポン',
    couponOffersEmpty: '現在使用できるクーポンはありません。',
    couponPeriodLabel: '期限',
    couponTimeWindowLabel: '時間帯',
    couponConditionsLabel: '条件',
    couponUpcomingHeading: '今後の予定',
    couponBestHeading: '現在の最大還元率',
    couponCapOnlyNote: (cap) => '上限$cap',
    couponRankAssumeNote: (rank, percent) => '$rank会員$percent想定',
    couponTargetNote: (target) => '※最大$targetが理論値（これ以上は還元率が下がる）',
    couponPatternsLead: (target) => '$targetに近い注文の例',
    couponPatternsLeadPlain: '注文の例',
    couponRewardLabel: '還元',
    couponTotalLabel: '合計',
    couponBackLabel: '還元',
    couponNetLabel: '実質',
    couponScheduleHeading: 'スケジュール',
    couponTypesHeading: 'キャンペーンの種類',
    couponTypeMobileOrder: (
      name: 'モバイルオーダー',
      description: '松屋フーズ公式アプリで注文して店舗で受け取る（店内・持ち帰り）',
    ),
    couponTypeMatsubenNet: (
      name: '松弁ネット',
      description: '松屋フーズ公式アプリで受取時間を指定するテイクアウトの事前予約（配達は松弁デリバリー）',
    ),
    couponTypeXCoupon: (
      name: 'Xクーポン',
      description: '公式X（@matsu_noya）で配られる、券売機のみで使用できるクーポン',
    ),
    couponTypeTiktokCoupon: (
      name: 'TikTokクーポン',
      description: '公式TikTok（@matsu_noya）で配られる、券売機のみで使用できるクーポン',
    ),
    couponTypeDiscountFair: (name: '割引フェア', description: '対象商品が期間限定で値引きになるもの'),
    couponRankNames: {
      'bronze': 'ブロンズ',
      'silver': 'シルバー',
      'gold': 'ゴールド',
      'platinum': 'プラチナ',
      'diamond': 'ダイヤモンド',
      'black': 'ブラック',
    },
    couponStartBracket: (start) => '[$start]',
    couponStartsOn: (start) => '$start〜',
    mapStandalone: '松のや専門店',
    mapBrandMatsuya: '松屋併設',
    mapBrandMycurry: 'マイカリー食堂併設',
    mapIncludeInactive: '終売の店も含める',
    mapSelling: '販売中',
    mapUpcoming: '発売前',
    mapLegendLabel: '凡例',
    mapMyLocation: '現在地',
    mapNorthUp: '北が上',
    mapSearchHint: '店舗を探す',
    mapShopsUnit: '店舗',
    mapMenuShops: (total, ended) =>
        ended > 0 ? '$total店舗（終売: $ended件）' : '$total店舗',
    mapHeadingUp: '進行方向が上',
    mapLocationUnavailable: '現在地を取得できません',
    mapOpenInGoogleMaps: 'Google マップで開く',
    mapAddress: '住所',
    mapHours: '営業時間',
    mapPhone: '電話',
    mapCall: (phone) => '$phone に電話をかける',
    mapDateTime: (m, d, h, _) => '$m/$d $h時',
    mapDate: (m, d) => '$m/$d',
    mapStartsAt: (when) => '$when 発売',
    mapEndedAt: (when) => '$when 終売',
    mapTempClosed: '一時閉店中（再開日未定）',
    mapTempClosedUntil: (reopens) => '一時閉店中（$reopens 再開）',
    mapTempClosedPlanned: (from, until) =>
        until == null ? '$from から一時閉店' : '$from〜$until 一時閉店',
    mapOpensAt: (when) => '$when 開店',
    mapClosesAt: (when) => '$when 閉店',
    mapClosed: '閉店',
  );

  static final en = AppMessages(
    appName: 'Tonsoku',
    tagline: 'Matsunoya News',
    navLabel: 'Main navigation',
    navHome: 'Home',
    navMap: 'Map',
    navCoupon: 'Coupons',
    navMenu: 'Menu',
    navRanking: 'Ranking',
    rankingPageTitle: 'Ranking',
    rankingDaily: 'Daily',
    rankingWeekly: 'Weekly',
    rankingMonthly: 'Monthly',
    rankingTabGroup: 'Ranking period',
    rankingUpdatedAt: (date) => 'Updated: $date',
    rankingRank: (rank) => 'No. $rank',
    rankingEmpty: 'No ranking yet',
    navCalendar: 'Calendar',
    calendarPageTitle: 'Matsunoya Calendar',
    calendarViewCalendar: 'Open calendar',
    calendarPrevMonth: 'Previous month',
    calendarNextMonth: 'Next month',
    calendarToday: 'Today',
    calendarAll: 'All',
    calendarLineCategoryGroup: 'Category to show as a timeline',
    calendarEventCount: (n) => n == 1 ? '1 event' : '$n events',
    calendarWeekdays: const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
    calendarWeekdayColumnWidth: 66,
    calendarMonthLabel: (year, month) =>
        '${_calendarEnMonths[month - 1]} $year',
    calendarMonthOnly: (month) => _calendarEnMonths[month - 1],
    commonOfficial: 'Official',
    navAbout: 'About Tonsoku',
    navTerms: 'Terms of Service',
    navPrivacy: 'Privacy Policy',
    themeLabel: 'Theme',
    themeLight: 'Light mode',
    themeDark: 'Dark mode',
    languageLabel: 'Language',
    menuOther: 'More',
    menuLicenses: 'Licenses',
    menuVersion: 'Version',
    licenseIntro: 'This app uses the following open source software.',
    licenseCount: (count) => count == 1 ? '1 license' : '$count licenses',
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
    couponPageTitle: 'Matsunoya coupons',
    couponUpdatedAt: (date) => 'As of $date',
    couponDisclaimer:
        'Compiled independently from public sources. Please check the official announcements for the exact terms.',
    couponOffersHeading: 'Available now',
    couponOffersEmpty: 'No coupons are available right now.',
    couponPeriodLabel: 'Period',
    couponTimeWindowLabel: 'Hours',
    couponConditionsLabel: 'Conditions',
    couponUpcomingHeading: 'Coming up',
    couponBestHeading: 'Best rate right now',
    couponCapOnlyNote: (cap) => 'Cap $cap',
    couponRankAssumeNote: (rank, percent) => 'Assumes $rank ($percent)',
    couponTargetNote: (target) =>
        '* $target is the sweet spot — spend more and the rate drops',
    couponPatternsLead: (target) => 'Orders close to $target',
    couponPatternsLeadPlain: 'Example orders',
    couponRewardLabel: 'back',
    couponTotalLabel: 'Total',
    couponBackLabel: 'Back',
    couponNetLabel: 'Net',
    couponScheduleHeading: 'Schedule',
    couponTypesHeading: 'Types of campaign',
    couponTypeMobileOrder: (
      name: 'Mobile Order',
      description:
          'Order in the Matsuya Foods app and pick it up in store (eat in or take away)',
    ),
    couponTypeMatsubenNet: (
      name: 'Matsuben Net',
      description:
          'Takeaway pre-order in the Matsuya Foods app with a pickup time (delivery is Matsuben Delivery)',
    ),
    couponTypeXCoupon: (
      name: 'X coupon',
      description:
          'Coupons handed out on the official X account (@matsu_noya); usable only at the ticket machine',
    ),
    couponTypeTiktokCoupon: (
      name: 'TikTok coupon',
      description:
          'Coupons handed out on the official TikTok account (@matsu_noya); usable only at the ticket machine',
    ),
    couponTypeDiscountFair: (
      name: 'Discount fair',
      description: 'A set price cut on selected items for a limited period',
    ),
    couponRankNames: {
      'bronze': 'Bronze',
      'silver': 'Silver',
      'gold': 'Gold',
      'platinum': 'Platinum',
      'diamond': 'Diamond',
      'black': 'Black',
    },
    couponStartBracket: (start) => '[$start]',
    couponStartsOn: (start) => 'From $start',
    mapStandalone: 'Matsunoya only',
    mapBrandMatsuya: 'With Matsuya',
    mapBrandMycurry: 'With My Curry Shokudo',
    mapIncludeInactive: 'Include ended stores',
    mapSelling: 'Available',
    mapUpcoming: 'Coming soon',
    mapLegendLabel: 'Legend',
    mapMyLocation: 'My location',
    mapNorthUp: 'North up',
    mapSearchHint: 'Search stores',
    mapShopsUnit: 'stores',
    mapMenuShops: (total, ended) =>
        ended > 0 ? '$total stores ($ended ended)' : '$total stores',
    mapHeadingUp: 'Heading up',
    mapLocationUnavailable: 'Your location is unavailable',
    mapOpenInGoogleMaps: 'Open in Google Maps',
    mapAddress: 'Address',
    mapHours: 'Hours',
    mapPhone: 'Phone',
    mapCall: (phone) => 'Call $phone',
    mapDateTime: (m, d, h, min) => '$m/$d $h:${min.toString().padLeft(2, '0')}',
    mapDate: (m, d) => '$m/$d',
    mapStartsAt: (when) => 'From $when',
    mapEndedAt: (when) => 'Ended $when',
    mapTempClosed: 'Temporarily closed (reopening date TBA)',
    mapTempClosedUntil: (reopens) => 'Temporarily closed (reopens $reopens)',
    mapTempClosedPlanned: (from, until) => until == null
        ? 'Temporarily closed from $from'
        : 'Temporarily closed $from – $until',
    mapOpensAt: (when) => 'Opens $when',
    mapClosesAt: (when) => 'Closing for good $when',
    mapClosed: 'Closed for good',
  );

  static final zh = AppMessages(
    appName: '豚速',
    tagline: '松乃家快报',
    navLabel: '主导航',
    navHome: '首页',
    navMap: '地图',
    navCoupon: '优惠券',
    navMenu: '菜单',
    navRanking: '排行榜',
    rankingPageTitle: '排行榜',
    rankingDaily: '每日',
    rankingWeekly: '每周',
    rankingMonthly: '每月',
    rankingTabGroup: '统计期间',
    rankingUpdatedAt: (date) => '更新日期：$date',
    rankingRank: (rank) => '第$rank名',
    rankingEmpty: '暂无排行榜',
    navCalendar: '日历',
    calendarPageTitle: '松乃家日历',
    calendarViewCalendar: '查看日历',
    calendarPrevMonth: '上个月',
    calendarNextMonth: '下个月',
    calendarToday: '今天',
    calendarAll: '全部',
    calendarLineCategoryGroup: '显示时间线的分类',
    calendarEventCount: (n) => '$n项日程',
    calendarWeekdays: const ['日', '一', '二', '三', '四', '五', '六'],
    calendarWeekdayColumnWidth: 44,
    calendarMonthLabel: (year, month) => '$year年$month月',
    calendarMonthOnly: (month) => '$month月',
    commonOfficial: '官方',
    navAbout: '关于豚速',
    navTerms: '使用条款',
    navPrivacy: '隐私政策',
    themeLabel: '外观模式',
    themeLight: '浅色模式',
    themeDark: '深色模式',
    languageLabel: '语言',
    menuOther: '其他',
    menuLicenses: '许可信息',
    menuVersion: '版本',
    licenseIntro: '本应用使用了以下开源软件。',
    licenseCount: (count) => '$count 项许可',
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
    couponPageTitle: '松乃家的优惠券',
    couponUpdatedAt: (date) => '截至$date',
    couponDisclaimer: '本页依据公开信息独立整理，具体条件请同时确认各公司的官方说明。',
    couponOffersHeading: '当前可用的优惠券',
    couponOffersEmpty: '当前没有可用的优惠券。',
    couponPeriodLabel: '期限',
    couponTimeWindowLabel: '时段',
    couponConditionsLabel: '条件',
    couponUpcomingHeading: '今后的日程',
    couponBestHeading: '当前最高返还比例',
    couponCapOnlyNote: (cap) => '上限$cap',
    couponRankAssumeNote: (rank, percent) => '按$rank会员$percent计算',
    couponTargetNote: (target) => '※$target为理论最大值（超过后返还比例下降）',
    couponPatternsLead: (target) => '接近$target的点单示例',
    couponPatternsLeadPlain: '点单示例',
    couponRewardLabel: '返还',
    couponTotalLabel: '合计',
    couponBackLabel: '返还',
    couponNetLabel: '实付',
    couponScheduleHeading: '日程',
    couponTypesHeading: '活动类型',
    couponTypeMobileOrder: (
      name: '手机点餐',
      description: '在松屋食品官方应用下单后到店取餐（堂食或外带）',
    ),
    couponTypeMatsubenNet: (
      name: '松弁网',
      description: '在松屋食品官方应用指定取餐时间的外带预约（配送为松弁外送）',
    ),
    couponTypeXCoupon: (
      name: 'X优惠券',
      description: '官方X（@matsu_noya）发放、仅可在售票机使用的优惠券',
    ),
    couponTypeTiktokCoupon: (
      name: 'TikTok优惠券',
      description: '官方TikTok（@matsu_noya）发放、仅可在售票机使用的优惠券',
    ),
    couponTypeDiscountFair: (name: '折扣活动', description: '指定商品在限定期间内降价'),
    couponRankNames: {
      'bronze': '青铜',
      'silver': '白银',
      'gold': '黄金',
      'platinum': '铂金',
      'diamond': '钻石',
      'black': '黑卡',
    },
    couponStartBracket: (start) => '[$start]',
    couponStartsOn: (start) => '$start起',
    mapStandalone: '松乃家专门店',
    mapBrandMatsuya: '附设松屋',
    mapBrandMycurry: '附设My Curry食堂',
    mapIncludeInactive: '包括已停售的门店',
    mapSelling: '销售中',
    mapUpcoming: '即将发售',
    mapLegendLabel: '图例',
    mapMyLocation: '当前位置',
    mapNorthUp: '北方朝上',
    mapSearchHint: '搜索门店',
    mapShopsUnit: '家门店',
    mapMenuShops: (total, ended) =>
        ended > 0 ? '$total家门店（已停售: $ended家）' : '$total家门店',
    mapHeadingUp: '前进方向朝上',
    mapLocationUnavailable: '无法获取当前位置',
    mapOpenInGoogleMaps: '在 Google 地图中打开',
    mapAddress: '地址',
    mapHours: '营业时间',
    mapPhone: '电话',
    mapCall: (phone) => '拨打 $phone',
    mapDateTime: (m, d, h, _) => '$m/$d $h时',
    mapDate: (m, d) => '$m/$d',
    mapStartsAt: (when) => '$when 开售',
    mapEndedAt: (when) => '$when 停售',
    mapTempClosed: '暂停营业中（恢复日期未定）',
    mapTempClosedUntil: (reopens) => '暂停营业中（$reopens 恢复营业）',
    mapTempClosedPlanned: (from, until) =>
        until == null ? '$from 起暂停营业' : '$from–$until 暂停营业',
    mapOpensAt: (when) => '$when 开业',
    mapClosesAt: (when) => '$when 闭店',
    mapClosed: '已闭店',
  );
}

/// 種類表の 1 行（名前と説明）。
typedef CouponTypeText = ({String name, String description});

/// 仮訳の断り。web の `REFERENCE_TRANSLATION`（`src/i18n/messages/en.ts` / `zh.ts`）。
const _enReferenceTranslation =
    'This is a reference translation. '
    'The Japanese version is the authoritative original.';
const _zhReferenceTranslation = '本文为参考译文，正式版本以日语原文为准。';

/// カレンダーの英語の月名（web の `calendar.monthLabel` / `monthOnly`）。
/// **略さない**（記事の日付の `Sep` とは別。web も月の見出しは全綴り）。
const _calendarEnMonths = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
