import 'package:freezed_annotation/freezed_annotation.dart';

part 'limited_week.freezed.dart';
part 'limited_week.g.dart';

/// 店舗限定の週ごとの状態（`limited/weeks.json`）。**配信側との契約**
/// （tonsoku-backend-batch の `schema/limited-weeks.json`）。形の説明は web の
/// `src/models/limited-weeks.ts` が正。
///
/// - **週は水曜から翌週火曜まで**（`week_start` は水曜）。松のやは店舗限定を水曜 15 時に出す
/// - **新しい順に 12 週**
/// - `status` は `items` / `none` / `pending`。**`none` は出なかったと確定した週だけ**
///   （発売枠の巡回で全店を見た）。`pending` は未確定で、画面には何も出さない
///   （「なし」と推測で出すと、検知が遅れただけの週に嘘が出る）
@freezed
abstract class LimitedWeeks with _$LimitedWeeks {
  const factory LimitedWeeks({
    @Default(<LimitedWeek>[]) List<LimitedWeek> weeks,
  }) = _LimitedWeeks;

  factory LimitedWeeks.fromJson(Map<String, dynamic> json) =>
      _$LimitedWeeksFromJson(json);
}

@freezed
abstract class LimitedWeek with _$LimitedWeek {
  const factory LimitedWeek({
    @JsonKey(name: 'week_start') required String weekStart,
    @JsonKey(name: 'week_end') required String weekEnd,

    /// **enum にせず文字列で受ける。** 知らない値が増えた時に一覧ごと
    /// 読めなくなるのを避ける（知らない値は `pending` と同じく出さない）
    required String status,
    @Default(<LimitedWeekItem>[]) List<LimitedWeekItem> items,
  }) = _LimitedWeek;

  const LimitedWeek._();

  factory LimitedWeek.fromJson(Map<String, dynamic> json) =>
      _$LimitedWeekFromJson(json);

  bool get hasItems => status == 'items';

  /// 出なかったと確定した週。
  bool get isNone => status == 'none';
}

@freezed
abstract class LimitedWeekItem with _$LimitedWeekItem {
  const factory LimitedWeekItem({
    @JsonKey(name: 'cms_id') required String cmsId,

    /// 品名。ロケール別の面では公式訳（無ければ日本語）
    required String name,
    @JsonKey(name: 'image_url') @Default('') String imageUrl,

    /// 配信済みの記事だけ。無ければ null
    @JsonKey(name: 'article_slug') String? articleSlug,

    /// 取扱店を確定した時点の数。**常に `shops_live + shops_ended`**
    @JsonKey(name: 'shop_count') @Default(0) int shopCount,

    /// いま売っている店の数。**全店で終売した品（`ended_at` あり）は 0**
    @JsonKey(name: 'shops_live') @Default(0) int shopsLive,

    /// 売り終わった店の数
    @JsonKey(name: 'shops_ended') @Default(0) int shopsEnded,

    /// 全店から消えて終売が確定した日。売っている間と、分からない間は null
    @JsonKey(name: 'ended_at') String? endedAt,
  }) = _LimitedWeekItem;

  const LimitedWeekItem._();

  factory LimitedWeekItem.fromJson(Map<String, dynamic> json) =>
      _$LimitedWeekItemFromJson(json);

  bool get ended => endedAt != null;
}
