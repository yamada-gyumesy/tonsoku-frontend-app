import 'package:freezed_annotation/freezed_annotation.dart';

part 'ranking.freezed.dart';
part 'ranking.g.dart';

/// 集計窓。**並び順もこれに従う**（web の `RANKING_WINDOWS`）。
enum RankingWindow { daily, weekly, monthly }

/// この順位までを「上位」として大きく見せる。web の `RANKING_TOP_RANK`。
const rankingTopRank = 3;

/// `ranking.json` 全体。
@freezed
abstract class RankingPayload with _$RankingPayload {
  const factory RankingPayload({
    @JsonKey(name: 'computed_at') @Default('') String computedAt,
    @Default(<String, RankingWindowData>{})
    Map<String, RankingWindowData> windows,
  }) = _RankingPayload;

  const RankingPayload._();

  factory RankingPayload.fromJson(Map<String, dynamic> json) =>
      _$RankingPayloadFromJson(json);

  RankingWindowData? window(RankingWindow window) => windows[window.name];
}

/// 窓 1 つぶん。
@freezed
abstract class RankingWindowData with _$RankingWindowData {
  const factory RankingWindowData({
    @Default('') String start,
    @Default('') String end,
    @Default(<RankingItem>[]) List<RankingItem> items,
  }) = _RankingWindowData;

  factory RankingWindowData.fromJson(Map<String, dynamic> json) =>
      _$RankingWindowDataFromJson(json);
}

/// 順位 1 つぶん。**記事の見出しもサムネイルも入っていない**ので、一覧側と
/// 突き合わせて描く。
@freezed
abstract class RankingItem with _$RankingItem {
  const factory RankingItem({required int rank, required String slug}) =
      _RankingItem;

  factory RankingItem.fromJson(Map<String, dynamic> json) =>
      _$RankingItemFromJson(json);
}
