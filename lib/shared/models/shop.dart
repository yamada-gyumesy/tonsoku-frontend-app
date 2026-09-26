import 'package:freezed_annotation/freezed_annotation.dart';

part 'shop.freezed.dart';
part 'shop.g.dart';

/// マップの店 1 軒（`app/shop.json` の 1 要素）。**配信側との契約**は
/// `https://cdn.ton-soku.com/schema/app-shop.json`（tonsoku-backend-batch の
/// `schema/app-shop.json`）で、**鍵は 12 個とも必ず出る**（値が null になるものはある）。
/// スキーマは `additionalProperties: false` なので、ここの鍵と 1 対 1 に揃えてある。
///
/// - **前の 8 つ**（`code` 〜 `brands`）は牛めしレーダー（`gyumeshi-rader-app` の
///   `lib/data/models/shop.dart`）と同じ形
/// - **後の 4 つ**（`address` 〜 `temp_closed`）はとん速のマップが店の情報を
///   出すために足してもらったもの（Issue #8）
///
/// **座標を持たない店は配信に載らない**（地図に置けないため。配信側の判断）。
///
/// 時刻はすべて JST の `YYYY-MM-DD HH:mm`（`temp_closed` の中だけ `YYYY-MM-DD`）。
/// 読み方は `lib/features/map/domain/jst.dart`。
@freezed
abstract class Shop with _$Shop {
  const factory Shop({
    required String code,

    /// 「松のや 西新宿店」のように**ブランド名から始まる**正式名。
    ///
    /// **英語・中国語の面（`i18n/{en,zh}/app/shop.json`）では訳が無ければ null**
    /// （日本語に落とさない。tonsoku-backend-batch#286）。日本語の面は必ず入る。
    /// 画面に出す名前は `shopLabel`（`lib/features/map/domain/map_format.dart`）
    String? name,

    /// 店名のローマ字（`NISHISHINJUKU`）。**大文字だけで読みにくい**ので、
    /// [name] がある時は画面に出さない（牛めしレーダーは検索の照合に使っている）。
    /// **[name] が null の時の代わり**にだけ使う（配信側のスキーマが
    /// 「name_roman に落とせる」としている。`shopLabel`）
    @JsonKey(name: 'name_roman') String? nameRoman,
    required double lat,
    required double lon,

    /// 閉店する（した）時刻。**意味は [openingDate] との前後で変わる**
    /// （`lib/features/map/domain/shop_state.dart`）
    @JsonKey(name: 'closing_date') String? closingDate,

    /// 開店する（した）時刻。
    @JsonKey(name: 'opening_date') String? openingDate,

    /// 併設しているブランド（`matsuya` / `mycurry`）。**松のや自身
    /// （`matsunoya`）が入ることもある**ので、併設として数えるのは
    /// `lib/features/map/domain/shop_filter.dart` の [ShopBrand] に載っているものだけ
    @Default(<String>[]) List<String> brands,

    /// 住所（Navitime）。**英語・中国語の面では訳が無ければ null**（行を出さない）
    String? address,

    /// 営業時間。**Navitime の表記そのまま**（「月から土：5時から翌2時、…」）で、
    /// 形が決まっていないので**組み替えずにそのまま出す**。**英語・中国語の面では
    /// 訳が無ければ null**（行を出さない）
    @JsonKey(name: 'business_hours') String? businessHours,
    String? phone,

    /// 一時閉店中、またはこれから一時閉店する期間。**カレンダーの「一時閉店」と
    /// 同じ答え**。無ければ null
    @JsonKey(name: 'temp_closed') TempClosed? tempClosed,
  }) = _Shop;

  factory Shop.fromJson(Map<String, dynamic> json) => _$ShopFromJson(json);
}

/// 一時閉店の期間。**日付だけ**（時刻は持たない）。
@freezed
abstract class TempClosed with _$TempClosed {
  const factory TempClosed({
    @JsonKey(name: 'start_date') required String startDate,

    /// 再開日。**告知されていなければ null**（「再開日未定」）
    @JsonKey(name: 'end_date') String? endDate,
  }) = _TempClosed;

  factory TempClosed.fromJson(Map<String, dynamic> json) =>
      _$TempClosedFromJson(json);
}
