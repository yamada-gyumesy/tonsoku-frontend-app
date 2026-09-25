import 'package:freezed_annotation/freezed_annotation.dart';

part 'limited_menu.freezed.dart';
part 'limited_menu.g.dart';

/// 店舗限定メニュー 1 品（`app/limited.json` の 1 要素）。**配信側との契約**は
/// `https://cdn.ton-soku.com/schema/app-limited.json`（`additionalProperties: false`。
/// 鍵は 10 個とも必ず出る）。
///
/// - **前の 4 つ**（`campaign_id` / `name` / `start_date` / `shops`）は
///   牛めしレーダーの `LimitedMenu` と同じ形
/// - **後の 6 つ**は地図で売り切れ・終売を出すために足してもらったもの（Issue #8）
///
/// **配列が空（店舗限定が 1 件も無い週）は正常な状態**で、失敗ではない。
/// **全店で終売した品も 14 日間は残る**（[shops] は空、[endedAt] が入る）。
///
/// 店ごとの状態（販売中・売り切れ・終売）の読み方は
/// `lib/features/map/domain/limited_status.dart`。
@freezed
abstract class LimitedMenu with _$LimitedMenu {
  const factory LimitedMenu({
    /// 識別子。**昼の品の `cms_id`**（深夜料金版は配信側で 1 つにまとめてある）。
    /// とん速にキャンペーンという単位は無いが、鍵の名前は牛めしレーダーに揃えてある
    @JsonKey(name: 'campaign_id') required String campaignId,
    required String name,

    /// 発売の時刻（JST `YYYY-MM-DD HH:mm`）。
    @JsonKey(name: 'start_date') String? startDate,

    /// **いま掲載がある店**（売り切れ中の店も含む）。
    @Default(<String>[]) List<String> shops,

    /// [shops] のうち、**いま売り切れの店**（15 分ごとの巡回で更新される）。
    @JsonKey(name: 'sold_out_shops')
    @Default(<String>[])
    List<String> soldOutShops,

    /// 扱っていたが掲載が外れた店と、その時刻。**記事の取扱店の表の
    /// 「（9/13 21時 終売）」と同じ答え**。記事になっていない品は空。
    @JsonKey(name: 'ended_shops')
    @Default(<EndedShop>[])
    List<EndedShop> endedShops,

    /// **全店で終売した時刻。売っている間は null。** 時刻が分からない品だけ
    /// 日付（`YYYY-MM-DD`）で来る。
    @JsonKey(name: 'ended_at') String? endedAt,

    /// その品の記事（配信済みのものだけ）。
    @JsonKey(name: 'article_slug') String? articleSlug,

    /// 記事の一覧用サムネイル。
    @JsonKey(name: 'thumbnail_url') String? thumbnailUrl,

    /// 品の写真（自前の CDN に写したもの）。
    @JsonKey(name: 'image_url') String? imageUrl,
  }) = _LimitedMenu;

  factory LimitedMenu.fromJson(Map<String, dynamic> json) =>
      _$LimitedMenuFromJson(json);
}

/// 掲載が外れた店と、その時刻（JST `YYYY-MM-DD HH:mm`）。
@freezed
abstract class EndedShop with _$EndedShop {
  const factory EndedShop({
    required String code,
    @JsonKey(name: 'ended_at') required String endedAt,
  }) = _EndedShop;

  factory EndedShop.fromJson(Map<String, dynamic> json) =>
      _$EndedShopFromJson(json);
}
