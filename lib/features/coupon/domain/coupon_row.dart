import 'package:tonsoku/core/i18n/app_locale.dart';
import 'package:tonsoku/core/i18n/app_messages.dart';
import 'package:tonsoku/core/utils/article_date.dart';
import 'package:tonsoku/core/utils/source_label.dart';
import 'package:tonsoku/features/coupon/domain/coupon_channels.dart';
import 'package:tonsoku/features/coupon/domain/coupon_format.dart';
import 'package:tonsoku/shared/models/coupon.dart';

/// 一覧の 1 行。web の `utils/coupon.ts` の `CouponOfferRow`
/// （gyumesy-frontend-app の `CouponRow` を写し、とん速の `offerRows` に合わせ直した）。
///
/// **見せるのは「誰の」「いくら戻る」「いつまで」の 3 つだけ。** キャンペーンの
/// 売り文句は読者の関心事ではないので、ブランドがあればブランド名に、倍率のものは
/// 対象の注文方法（「松弁ネット2倍」）に寄せる。
///
/// ## gyumesy との違い
///
/// - **絵は 0〜2 枚**（QR コードとチラシ。[images]）。gyumesy は 1 枚で、2 次元コードか
///   どうかを `how_to_get` から当てていた。とん速の配信は鍵を分けている
/// - **配布元の印**（`【X】` / `【TikTok】`）を名前の前に出す（[sourceMark]）
/// - **TikTok クーポン**がある（配布元のバッジ）
/// - **アイコンは CDN に置いてあるものだけ**を出す（[cdnIconIds]）
class CouponRow {
  const CouponRow({
    required this.id,
    required this.name,
    required this.sourceMark,
    required this.iconUrl,
    required this.badge,
    required this.upcoming,
    required this.primary,
    required this.capText,
    required this.terms,
    required this.period,
    required this.timeWindow,
    required this.articleSlug,
    required this.links,
    required this.images,
    required this.startText,
  });

  final String id;

  /// 表示名（ブランド名 / title / 松屋ポイント）。**配布元の印は含まない。**
  final String name;

  /// 名前の前に出す配布元の印（`【X】` / `【TikTok】`）。持たない行は null。
  ///
  /// **[name] と分けてある。** スケジュール帯は名前だけを使っていて幅が狭く、
  /// 混ぜると帯が印だけになる（web の実測）。
  final String? sourceMark;

  /// 公式アプリのアイコン URL（CDN のキー）。置いていなければ null。
  final String? iconUrl;

  /// アイコンの右下に重ねる種類バッジ。**決められない行は null**（[offerBadge]）。
  final CouponBadge? badge;

  /// これから始まるぶんか。
  final bool upcoming;

  /// 大きく出す値（`15%` / `100円引き` / `12%〜40%`）。**率も値引き額も持たない施策は
  /// null**（`0%` と出すと「還元がゼロ」という別の意味になる）。
  final String? primary;

  /// 付与上限。**大きく出す数字のすぐ下**に置く。
  final String? capText;

  /// 条件。**順番は固定**（事前エントリー → 金額 → notes）。
  final List<String> terms;

  /// 期限（`〜9/30 15:00`）。
  final String period;
  final String? timeWindow;

  /// 名前のリンク先。**記事一覧に居る slug だけ**（無ければ null）。
  final String? articleSlug;

  /// 恩恵を受けるための外部リンク。**空になりうる。**
  final List<CouponRowLink> links;

  /// クーポン画像。**QR コードを先に出す**（券売機の前で押すのはこちら）。
  final List<CouponRowImage> images;

  /// 開始日の表示（`9/1`）。
  final String startText;
}

class CouponRowLink {
  const CouponRowLink({required this.url, required this.label});
  final String url;
  final String label;
}

/// 行に出すクーポン画像。
class CouponRowImage {
  const CouponRowImage({
    required this.url,
    required this.label,
    required this.isCode,
    required this.source,
  });

  final String url;

  /// チップと拡大表示の見出し（「QRコード」「詳細画像」）。
  final String label;

  /// **機械に読ませる絵か**（券売機にかざす QR コード）。拡大した時の出し方が
  /// 写真と違う（web の `CouponRowImage.isCode`）。
  final bool isCode;

  /// **この絵の引用元**（拡大した面に出す）。**行のチップにはしない**
  /// （券売機の前で押してほしいものと競合する。web のユーザー指摘）。
  final ({String url, String label})? source;
}

/// **配信 CDN に置いてあるアイコンのキー**（web の `CDN_ICON_IDS`）。
///
/// **無いものを絵にすると壊れた絵が並ぶ**ので、置いてあるものだけをここで持つ。
/// **足す前に、必ず `https://cdn.ton-soku.com/brands/{id}.webp` が 200 を返すことを
/// 自分で確かめること**（2026-09-25 に matsuya / x / tiktok / paypay を確認）。
const cdnIconIds = {
  'matsuya',
  'paypay',
  'au-pay',
  'rakuten-pay',
  'd-payment',
  'x',
  'tiktok',
};

/// 決済ブランドの絵を出すブランド（web の `BRAND_ICON_IDS`）。
const _brandIconIds = {'paypay', 'rakuten-pay', 'd-payment', 'au-pay'};

/// CDN のアイコンの**キー**（`brands/x.webp`）。置いていなければ null。
/// URL にするのは呼ぶ側（`AppConfig.cdnUrl`）。
String? cdnIconKey(String id) =>
    cdnIconIds.contains(id) ? 'brands/$id.webp' : null;

/// 他社（決済ブランド）の施策か。**下地のアイコンと種類バッジは同じ判定で決める**
/// （片方だけ直すと、PayPay のアイコンに松屋の種類バッジが載る）。
///
/// **倍率クーポンは配信の `brand` が空でも松屋の施策**として扱う。
bool isBrandOffer(CouponOffer offer) {
  if (offer.rateMultiplier != null) return false;
  return offer.brand != null && offer.brand != 'matsuya-point';
}

/// 行のアイコン。**下地が答えるのは「誰の施策か」だけ**（種類と配布元はバッジ）。
///
/// - 松屋自身の施策 → 松屋アイコン（**松屋に属するものは全部これ 1 つ**）
/// - 決済ブランド → 自社アイコン。引けなければ松屋へ落として絵を出す
String? offerIconKey(CouponOffer offer) {
  final brand = offer.brand;
  if (isBrandOffer(offer) && _brandIconIds.contains(brand)) {
    return cdnIconKey(brand!) ?? cdnIconKey('matsuya');
  }
  return cdnIconKey('matsuya');
}

/// アイコンの右下に重ねる種類バッジ。**種類表と同じ絵**を出す。
///
/// **絵そのものはここに書かない**（`IconData` は presentation の語彙）。
enum CouponBadge {
  /// 公式 X で配られる。**配布元**の軸。
  x,

  /// 公式 TikTok で配られる。**配布元**の軸。
  tiktok,

  /// 値引き。**特典の形**の軸。
  discount,

  /// モバイルオーダー限定。**注文方法**の軸。
  mobileOrder,

  /// 松弁ネット限定。**注文方法**の軸。
  matsubenNet,
}

const _channelBadges = <String, CouponBadge?>{
  'mobile_order': CouponBadge.mobileOrder,
  'matsuben_net': CouponBadge.matsubenNet,
  'matsuben_delivery': null,
  'store': null,
};

/// 行のアイコンに重ねる種類バッジ（web の `offerBadge`）。**上から順に最初に
/// 当たったものを出す。**
///
/// **配布元（X / TikTok）は他社ブランドの判定より先に見る。** 決済ブランドの
/// クーポンが公式 X で配られることがあり、後ろに置くと**X で配っているという情報が
/// 画面から消える**。
///
/// **値引きをチャネルより先に見るのは、`channels` が揺れる値だから。**
/// **どれにも当たらなければ出さない。**
CouponBadge? offerBadge(CouponOffer offer) {
  if (offer.howToGet == 'x') return CouponBadge.x;
  if (offer.howToGet == 'tiktok') return CouponBadge.tiktok;
  if (isBrandOffer(offer)) return null;
  if (offer.benefitType == 'discount') return CouponBadge.discount;
  final channels = displayChannels(offer.channels);
  if (channels.length != 1) return null;
  return _channelBadges[channels.first];
}

/// 配布元の呼び名。**訳さない**（サービス名なので 3 ロケールとも同じ字面）。
/// **ここに無い配布元には印を出さない**（読者の判断を変えるのは公式 SNS の 2 つだけ）。
const _distributorNames = {'x': 'X', 'tiktok': 'TikTok'};

/// 出どころの `source_label` から配布元へ。**呼び名の表は 1 つ**（[_distributorNames]）。
const _sourceLabelToDistributor = {
  'official_x': 'x',
  'official_tiktok': 'tiktok',
};

/// 予定名から、右側の数字と重なるぶんと定型句を落とす（gyumesy・web と同じ）。
String trimOfferTitle(String title) {
  final trimmed = title
      .replaceAll(
        RegExp(r'[0-9,]+\s*円\s*(?:引き|OFF|オフ)', caseSensitive: false),
        '',
      )
      .replaceAll(RegExp(r'(?:クーポン|キャンペーン)?\s*(?:配信|開催|実施)?\s*$'), '')
      .trim();
  return trimmed.isNotEmpty ? trimmed : title;
}

/// 倍率クーポンで実際に付く率の**幅**（最下位〜最上位ランク）。**最大だけにしないこと**
/// （下位ランクの人が自分の還元を過大に読む）。
({double min, double max})? multiplierRange(
  CouponOffer offer,
  List<CouponRank> ranks,
) {
  final mult = offer.rateMultiplier;
  if (mult == null) return null;
  final keys = displayChannels(
    offer.channels,
  ).map(rateKeyOf).whereType<String>().toList();
  if (keys.isEmpty || ranks.isEmpty) return null;
  final rates = <double>[
    for (final rank in ranks)
      for (final key in keys)
        if (rank.rates[key] case final double v)
          if (v.isFinite) v,
  ];
  if (rates.isEmpty) return null;
  double round(double v) => (v * mult * 10).round() / 10;
  return (
    min: round(rates.reduce((a, b) => a < b ? a : b)),
    max: round(rates.reduce((a, b) => a > b ? a : b)),
  );
}

/// 会員ランクを下位から順に並べる（**配信順に依存しない**）。
List<CouponRank> sortedRanks(List<CouponRank> ranks) =>
    [...ranks]..sort((a, b) => a.order.compareTo(b.order));

/// ラベル表から引く。**表に無い値は ID をそのまま返す**（落ちるより、ID が出たまま
/// 他の行を描き切るほうがよい。web の `pickLabel`）。
String _pick(Map<String, String> table, String key) => table[key] ?? key;

String channelLabel(AppMessages t, String id) =>
    _pick(t.couponChannelNames, id);

/// 行の名前（web の `offerName`）。
String offerName(
  CouponOffer offer,
  AppMessages t,
  Map<String, String> tagLabels,
) {
  // **倍率は対象の注文方法で呼ぶ**（「モバイルオーダー3倍」）。キャンペーン名は出さない
  final mult = offer.rateMultiplier;
  if (mult != null) {
    final channels = displayChannels(offer.channels);
    final label = channels.length == 1
        ? channelLabel(t, channels.first)
        : t.couponMatsuyaPoint;
    return t.couponMultiplierName(label, mult);
  }
  // **定額のポイント付与は、キャンペーン名そのものが識別子**
  final title = offer.title;
  if (offer.pointAmount != null && title != null && title.isNotEmpty) {
    return trimOfferTitle(title);
  }
  final brand = offer.brand;
  if (brand != null && brand.isNotEmpty) {
    final label = tagLabels[brand] ?? brand;
    // **取得して使うもの（クーポン）と、エントリーして決済すると戻るもの（還元）は、
    // 読者の動きがまったく違う**
    const couponWays = {'app', 'x', 'tiktok', 'line', 'kiosk_qr'};
    return couponWays.contains(offer.howToGet)
        ? t.couponBrandCoupon(label)
        : t.couponBrandReward(label);
  }
  // **配布元を名前にしない**（「Xクーポン 70円引き」では何が 70 円引きなのか
  // 分からない）。**配布元の印は名前に混ぜない**（[CouponRow.sourceMark]）
  return title != null && title.isNotEmpty
      ? trimOfferTitle(title)
      : t.couponUnnamedOffer;
}

/// 名前の前に置く配布元の印（web の `offerSourceMark`）。
///
/// **アイコン右下のバッジだけでは、X と TikTok のクーポンが一覧で見分けられなかった**
/// （web のユーザー指摘）。絵で判別が付かないことが問題なので、字で出す。
String? offerSourceMark(CouponOffer offer, AppMessages t) {
  final name = _distributorNames[offer.howToGet];
  return name == null ? null : t.couponSourceMark(name);
}

/// 右の列に出す主値（web の `offerPrimary`）。**数字だけ**にする。
String? offerPrimary(CouponOffer offer, AppMessages t, List<CouponRank> ranks) {
  final discount = offer.discountYen;
  if (discount != null) {
    final max = offer.discountMaxYen;
    return max != null && max != discount
        ? t.couponDiscountRange(formatNumber(discount), formatNumber(max))
        : t.couponDiscountYen(t.couponYen(formatNumber(discount)));
  }

  final mult = offer.rateMultiplier;
  if (mult != null) {
    final range = multiplierRange(offer, ranks);
    return range == null
        ? t.couponMultiplier(mult)
        : t.couponPercentRange(
            formatPercent(range.min),
            formatPercent(range.max),
          );
  }

  if (offer.tiers.isNotEmpty) {
    // **1 段階しかない時も `tiers` から出す**（`rate_percent` は null を取りうる契約）
    final percents = offer.tiers.map((e) => e.ratePercent).toList();
    final min = percents.reduce((a, b) => a < b ? a : b);
    final max = percents.reduce((a, b) => a > b ? a : b);
    return min == max
        ? formatPercent(max)
        : t.couponPercentRange(formatPercent(min), formatPercent(max));
  }

  final rate = offer.ratePercent;
  if (rate != null) return formatPercent(rate);

  final points = offer.pointAmount;
  if (points != null) return t.couponPointAmount(formatNumber(points));

  // **率も値引き額もポイント付与も無い施策は数字を出さない**
  return null;
}

/// 行に出す条件（web の `offerTerms`）。**並べる順番を固定する**
/// （事前の手続き → 金額の条件 → 対象の絞り込み）。
List<String> offerTerms(CouponOffer offer, AppMessages t) {
  final terms = <String>[];
  if (offer.requiresEntry) terms.add(t.couponRequiresEntry);
  if (offer.tiers.isNotEmpty) {
    for (final tier in offer.tiers) {
      terms.add(
        t.couponTier(
          t.couponYen(formatNumber(tier.minSpendYen)),
          formatPercent(tier.ratePercent),
        ),
      );
    }
    // **`> 0` まで見る。** 下限なしを `0` で表す配信が来ると「0円以上」という
    // 何も言っていない行が出る（web が gyumesy から写した時に落とした）
  } else if (offer.minSpendYen case final int min when min > 0) {
    terms.add(t.couponMinSpend(t.couponYen(formatNumber(min))));
  }
  terms.addAll(offer.notes);
  return terms;
}

/// 外部リンクの表示名（web の `linkLabel`）。**率を持つリンクは率を頭に出す**
/// （PayPay は 10% と 15% で取得先が別）。
String _linkLabel(CouponLink link, AppMessages t, String? brand) {
  final rate = link.ratePercent;
  final percent = rate == null ? null : formatPercent(rate);
  if (link.kind == 'detail') {
    if (percent != null) return t.couponLinkDetailRate(percent);
    return brand == null ? t.couponLinkDetail : t.couponLinkDetailBrand(brand);
  }
  if (percent != null) return t.couponLinkEntryRate(percent);
  return brand == null ? t.couponLinkEntry : t.couponLinkEntryBrand(brand);
}

/// http(s) の URL だけを通す（web の `safeExternalUrl`。配信の値はこちらの管理下に無い）。
String? _safeExternalUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  final uri = Uri.tryParse(url);
  if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) {
    return null;
  }
  return url;
}

/// 行に出す外部リンク（web の `offerLinks`）。**`source` はここに出さない**
/// （出どころは絵を拡大した面に置いてある）。
List<CouponRowLink> _offerLinks(
  CouponOffer offer,
  AppMessages t,
  Map<String, String> tagLabels,
) {
  final brand = offer.brand == null
      ? null
      : tagLabels[offer.brand] ?? offer.brand;
  return [
    for (final link in offer.links)
      if (link.kind != 'source')
        if (_safeExternalUrl(link.url) case final String url)
          CouponRowLink(url: url, label: _linkLabel(link, t, brand)),
  ];
}

/// 絵の引用元（web の `offerSource`）。名前は `source_label` から、引けなければ
/// ホスト名に落とす。
({String url, String label})? _offerSource(CouponOffer offer) {
  final url = _safeExternalUrl(offer.sourceUrl);
  if (url == null) return null;
  final distributor = _sourceLabelToDistributor[offer.sourceLabel];
  final label = _distributorNames[distributor] ?? sourceLabelOf(url);
  return label == null ? null : (url: url, label: label);
}

/// 行に出すクーポン画像（web の `offerImages`）。**QR コードを先に出す。**
///
/// **QR コードに引用元は付けない**（こちらが読み直して作り直したもので、元の投稿に
/// この絵は無い）。**チラシには付ける**（元の告知画像を自前へ写したもの）。
List<CouponRowImage> _offerImages(CouponOffer offer, AppMessages t) => [
  if (offer.qrImageUrl case final String qr when qr.isNotEmpty)
    CouponRowImage(url: qr, label: t.couponQrImage, isCode: true, source: null),
  if (offer.imageUrl case final String flyer when flyer.isNotEmpty)
    CouponRowImage(
      url: flyer,
      label: t.couponDetailImage,
      isCode: false,
      source: _offerSource(offer),
    ),
];

CouponRow _toRow(
  CouponOffer offer,
  AppLocale locale,
  AppMessages t,
  Map<String, String> tagLabels,
  List<CouponRank> ranks, {
  required bool upcoming,
  required Set<String> slugs,
}) {
  final start = formatMonthDay(offer.startDate, locale);
  final endAt = offer.endAt == null ? null : DateTime.tryParse(offer.endAt!);
  final endDate = offer.endDate;
  // **終了時刻が決まっているものは時刻まで出す**（日付だけだと最終日に取りこぼす）
  final end = endAt != null
      ? formatMonthDayTime(endAt, locale)
      : endDate != null
      ? formatMonthDay(endDate, locale)
      : t.couponNoEndDate;
  final cap = offer.capYen;
  final slug = offer.articleSlug;

  return CouponRow(
    id: offer.id,
    name: offerName(offer, t, tagLabels),
    sourceMark: offerSourceMark(offer, t),
    iconUrl: offerIconKey(offer),
    badge: offerBadge(offer),
    upcoming: upcoming,
    primary: offerPrimary(offer, t, ranks),
    capText: cap == null
        ? null
        : t.couponCapNote(t.couponYen(formatNumber(cap))),
    terms: offerTerms(offer, t),
    // **終了未定は「〜」で包まない**（「〜終了未定」になり、スケジュール側の表記と
    // 食い違う。web と同じ）
    period: upcoming
        ? t.couponStartsOnUntil(start, end)
        : endAt == null && endDate == null
        ? t.couponNoEndDate
        : t.couponUntil(end),
    timeWindow: offer.timeWindow,
    // **記事一覧に居る slug だけリンクにする**（施策は記事より寿命が長く、記事が
    // 消えても施策は残る。web と同じ不変条件）
    articleSlug: slug != null && slugs.contains(slug) ? slug : null,
    links: _offerLinks(offer, t, tagLabels),
    images: _offerImages(offer, t),
    startText: start,
  );
}

/// 現在使えるクーポンの行（web の `offerRows`）。**並びは配信の順をそのまま使う**
/// （還元の形が揃っていないので、1 つの尺度に並べる根拠が無い）。
List<CouponRow> offerRows(
  Coupon coupon, {
  required AppLocale locale,
  required AppMessages t,
  required Map<String, String> tagLabels,
  required Set<String> slugs,
  bool Function(CouponOffer offer)? where,
}) {
  final ranks = sortedRanks(coupon.ranks);
  return [
    for (final offer in coupon.offers)
      if (where == null || where(offer))
        _toRow(
          offer,
          locale,
          t,
          tagLabels,
          ranks,
          upcoming: false,
          slugs: slugs,
        ),
  ];
}

/// 今後の予定（web の `upcomingRows`）。**並びは配信の順**（`start_date` 昇順で届く）。
List<CouponRow> upcomingRows(
  Coupon coupon, {
  required AppLocale locale,
  required AppMessages t,
  required Map<String, String> tagLabels,
  required Set<String> slugs,
}) {
  final ranks = sortedRanks(coupon.ranks);
  return [
    for (final offer in coupon.upcoming)
      _toRow(offer, locale, t, tagLabels, ranks, upcoming: true, slugs: slugs),
  ];
}
