import 'package:freezed_annotation/freezed_annotation.dart';

part 'coupon.freezed.dart';
part 'coupon.g.dart';

/// クーポン配信（`coupon.json`）。web の `src/models/coupon.ts` と同じ形
/// （gyumesy-frontend-app の `Coupon` を写し、とん速にしか無い鍵を足した）。
///
/// **404 を正常系として扱ってよい数少ない配信物**（`CdnPaths` 参照）。
///
/// **配信は無検証で素通しする。** ネストした配列ごと欠けた JSON も来うるので、
/// 配列は `@Default([])`、任意の値は null 許容にする。
///
/// **`combos` は読まない**（web も画面に出していない）。
///
/// **施策の `basis`（実効率の根拠の品と値段）も読まない。** web も描いていない
/// （英語・中国語の面では `basis.menu_name` が null になりうるが、読まないので
/// 解析には関わらない）。
@freezed
abstract class Coupon with _$Coupon {
  const factory Coupon({
    @JsonKey(name: 'generated_at') required String generatedAt,
    @Default(<CouponRank>[]) List<CouponRank> ranks,

    /// 今使えるぶん。**並びは配信の順をそのまま使う**（並べ替えは配信側の仕事）。
    @Default(<CouponOffer>[]) List<CouponOffer> offers,

    /// これから始まるぶん。**契約上 `start_date` 昇順**で届く。
    @Default(<CouponOffer>[]) List<CouponOffer> upcoming,

    /// 最大還元の組み合わせ。**無い日がある。**
    @JsonKey(name: 'best_deal') CouponBestDeal? bestDeal,
  }) = _Coupon;

  factory Coupon.fromJson(Map<String, dynamic> json) => _$CouponFromJson(json);
}

/// 会員ランク。**倍率クーポンが何%になるかを計算するため**にだけ使う。
@freezed
abstract class CouponRank with _$CouponRank {
  const factory CouponRank({
    required String id,
    required int order,

    /// 系統ごとの付与率（`matsuben` / `mobile_order`）。**店舗払いは系統が無い**。
    @Default(<String, double>{}) Map<String, double> rates,
  }) = _CouponRank;

  factory CouponRank.fromJson(Map<String, dynamic> json) =>
      _$CouponRankFromJson(json);
}

/// 1 件の施策。**値はほとんどが null を取りうる。**
@freezed
abstract class CouponOffer with _$CouponOffer {
  const factory CouponOffer({
    required String id,

    /// 決済ブランド（`paypay` 等）。松屋ポイントの施策は `matsuya-point`、
    /// ブランドを持たないものは null。
    String? brand,

    /// 施策名。**倍率クーポンでは使わない**（`offerName` が組み立てる）。
    String? title,
    @JsonKey(name: 'rate_percent') double? ratePercent,
    @JsonKey(name: 'rate_multiplier') double? rateMultiplier,
    @JsonKey(name: 'point_amount') int? pointAmount,
    @JsonKey(name: 'discount_yen') int? discountYen,
    @JsonKey(name: 'discount_max_yen') int? discountMaxYen,
    @JsonKey(name: 'cap_yen') int? capYen,
    @JsonKey(name: 'min_spend_yen') int? minSpendYen,
    @Default(<CouponTier>[]) List<CouponTier> tiers,
    @JsonKey(name: 'requires_entry') @Default(false) bool requiresEntry,
    @JsonKey(name: 'benefit_type') String? benefitType,
    @Default(<String>[]) List<String> channels,

    /// 取得方法。**配布元（`x` / `tiktok`）の判定はここを見る。** null を取りうる。
    @JsonKey(name: 'how_to_get') String? howToGet,
    @JsonKey(name: 'start_date') required String startDate,
    @JsonKey(name: 'end_date') String? endDate,

    /// 終了の時刻（ISO 8601）。**決まっているものは時刻まで出す**（日付だけだと、
    /// その日の何時までなのかが分からず最終日に取りこぼす。web と同じ）。
    @JsonKey(name: 'end_at') String? endAt,
    @JsonKey(name: 'time_window') String? timeWindow,
    @Default(<CouponLink>[]) List<CouponLink> links,

    /// チラシ（対象商品と値段が載っている元の告知画像を自前へ写したもの）。
    @JsonKey(name: 'image_url') String? imageUrl,

    /// **券売機にかざす QR コード。** とん速にしか無い鍵（gyumesy は元画像を
    /// そのまま出している）。配信側が読み直して作り直したもので、元の投稿には無い。
    @JsonKey(name: 'qr_image_url') String? qrImageUrl,

    /// 出どころの投稿。チラシの引用元に使う（絵と出所は必ず同じ投稿を指す）。
    @JsonKey(name: 'source_url') String? sourceUrl,

    /// 出どころの種類（`official_x` / `official_tiktok` / `official_news` …）。
    /// **開いた集合**（知らない値はホスト名に落とす）。
    @JsonKey(name: 'source_label') String? sourceLabel,
    @Default(<String>[]) List<String> notes,
    @JsonKey(name: 'article_slug') String? articleSlug,
  }) = _CouponOffer;

  factory CouponOffer.fromJson(Map<String, dynamic> json) =>
      _$CouponOfferFromJson(json);
}

/// 金額の段階（「800円以上で10%」）。
@freezed
abstract class CouponTier with _$CouponTier {
  const factory CouponTier({
    @JsonKey(name: 'rate_percent') required double ratePercent,
    @JsonKey(name: 'min_spend_yen') required int minSpendYen,
  }) = _CouponTier;

  factory CouponTier.fromJson(Map<String, dynamic> json) =>
      _$CouponTierFromJson(json);
}

/// 外部リンク。**表示名は配信されない**ので、`kind` と `rate_percent` から組む。
@freezed
abstract class CouponLink with _$CouponLink {
  const factory CouponLink({
    required String url,
    required String kind,
    @JsonKey(name: 'rate_percent') double? ratePercent,
  }) = _CouponLink;

  factory CouponLink.fromJson(Map<String, dynamic> json) =>
      _$CouponLinkFromJson(json);
}

/// 最大還元の組み合わせ（gyumesy-frontend-app の `CouponBestDeal` の写し）。
@freezed
abstract class CouponBestDeal with _$CouponBestDeal {
  const factory CouponBestDeal({
    required String channel,

    /// 前提にしている会員ランク。**倍率クーポンの率はこれに掛かっている。**
    required String rank,
    @Default(<CouponBestDealPart>[]) List<CouponBestDealPart> parts,
    @JsonKey(name: 'total_percent') required double totalPercent,

    /// 効いている付与上限。**null なら上限が無い**（率が下がらないので、
    /// 「これ以上は還元率が下がる」の但し書きを出してはいけない）。
    @JsonKey(name: 'cap_yen') int? capYen,

    /// その率で頼める上限の金額。**`cap_yen` があっても null を取りうる。**
    @JsonKey(name: 'target_spend_yen') int? targetSpendYen,
    @Default(<CouponPattern>[]) List<CouponPattern> patterns,
  }) = _CouponBestDeal;

  factory CouponBestDeal.fromJson(Map<String, dynamic> json) =>
      _$CouponBestDealFromJson(json);
}

/// 掛け合わせの 1 要素。**契約上 `offerId` / `brand` がどちらも null なのが
/// 松屋ポイントぶん。**
@freezed
abstract class CouponBestDealPart with _$CouponBestDealPart {
  const factory CouponBestDealPart({
    @JsonKey(name: 'offer_id') String? offerId,
    String? brand,
    required double percent,
  }) = _CouponBestDealPart;

  factory CouponBestDealPart.fromJson(Map<String, dynamic> json) =>
      _$CouponBestDealPartFromJson(json);
}

/// 取り切る買い方 1 件。
///
/// **`back_yen` / `net_yen` は契約では非 null だが null で受ける。** web は
/// 配信が契約に反した回に還元・実質の行だけを消して踏みとどまっている
/// （`utils/coupon.ts` の `?? null`）。
@freezed
abstract class CouponPattern with _$CouponPattern {
  const factory CouponPattern({
    @Default(<CouponPatternItem>[]) List<CouponPatternItem> items,
    @JsonKey(name: 'total_yen') required int totalYen,
    @JsonKey(name: 'back_yen') int? backYen,
    @JsonKey(name: 'net_yen') int? netYen,
  }) = _CouponPattern;

  factory CouponPattern.fromJson(Map<String, dynamic> json) =>
      _$CouponPatternFromJson(json);
}

/// 買い方に含まれるメニュー 1 品。**絵・値段・記事は配信が出している時だけ**。
@freezed
abstract class CouponPatternItem with _$CouponPatternItem {
  const factory CouponPatternItem({
    /// メニュー名。**英語・中国語の面では訳が無ければ null**（日本語に落とさない。
    /// tonsoku-backend-batch#286）。その時は名前を描かず、記事へのリンクも付けない
    /// （`coupon_best_card.dart` の `_Item`。web の `CoCouponBest` と同じ）
    String? name,
    @JsonKey(name: 'price_yen') int? priceYen,
    @JsonKey(name: 'article_slug') String? articleSlug,
    @Default('') String thumbnail,
  }) = _CouponPatternItem;

  factory CouponPatternItem.fromJson(Map<String, dynamic> json) =>
      _$CouponPatternItemFromJson(json);
}
