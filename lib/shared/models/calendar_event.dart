import 'package:freezed_annotation/freezed_annotation.dart';

part 'calendar_event.freezed.dart';
part 'calendar_event.g.dart';

/// カレンダーの予定。`calendar.json` の `events` の 1 件（gyumesy-frontend-app の
/// `CalendarEvent` を写した）。
///
/// 日付は **`2026-09-23` の形の文字列で持ち、`DateTime` にしない。**
/// 予定は「その日」の出来事で時刻を持たず、`DateTime` にするとタイムゾーンの
/// 分だけ前日・翌日にずれる余地が生まれる（配信側も JST の日付で持っている）。
///
/// ## 配信側の契約（web の `models/calendar.ts`。2026-09-04 に配信側へ確認済み）
///
/// - `end_date` がある … その日まで線
/// - `end_date` が null ＋ `ongoing: true` … **今日まで線**（松のやは終売を告知
///   しないので、メニューから消えるまで閉じない）
/// - `end_date` が null ＋ `ongoing: false` … **点**（定番。終わる予定が無い）
///
/// **`end_date` の null を「終わった」と読まないこと。** 区別は `ongoing` が持つ。
///
/// ## gyumesy との違い
///
/// - **`source_url` / `source_label` は null を取る**（とん速の配信は null を出す。
///   web の型も `string | null`）。gyumesy は空文字を既定にしていた
/// - **`preview`（発売前の予告か）を読む。** いまは常に `false` で画面は見ていないが、
///   配信が出している鍵を型に置いておく（web と同じ扱い）
/// - **創業記念日の判定（`isAnniversary`）を持たない。** とん速の配信は
///   `anniversary-` の予定を出さない（`tonsoku-backend-batch` に該当の取り込みが
///   無い）。花吹雪ごと持ってきていない理由は `CalendarPage` の doc
@freezed
abstract class CalendarEvent with _$CalendarEvent {
  const factory CalendarEvent({
    required String id,
    required String title,
    required String category,
    @JsonKey(name: 'start_date') required String startDate,

    /// 終了日。単日の予定や終わりが決まっていないものは null。
    @JsonKey(name: 'end_date') String? endDate,

    /// 終わりが決まっていない継続中の予定。
    @Default(false) bool ongoing,

    /// 発売前の予告か（web の `preview`）。**いまは常に false。**
    @Default(false) bool preview,
    @Default(<String>[]) List<String> tags,

    /// 対応する記事。**無い予定がある**（本番の 23 件中 8 件）ので null を想定する。
    @JsonKey(name: 'article_slug') String? articleSlug,

    /// 公式ソースの URL。無ければ null。
    @JsonKey(name: 'source_url') String? sourceUrl,

    /// 公式ソースの表示ラベル。**画面には出さない**（全ロケールで日本語のまま
    /// 届くので、`SourceChip` は固定語の「公式」を出す。gyumesy と同じ）。
    @JsonKey(name: 'source_label') String? sourceLabel,
  }) = _CalendarEvent;

  const CalendarEvent._();

  factory CalendarEvent.fromJson(Map<String, dynamic> json) =>
      _$CalendarEventFromJson(json);

  /// 期間の表示（`9/9` / `9/9〜9/23`）。単日なら開始日だけ。web の
  /// `formatEventPeriod`（**ロケールで形を変えない**のも web と同じ）。
  String get period {
    String short(String date) {
      final parts = date.split('-');
      if (parts.length < 3) return date;
      return '${int.parse(parts[1])}/${int.parse(parts[2])}';
    }

    final end = endDate;
    if (end == null || end == startDate) return short(startDate);
    return '${short(startDate)}〜${short(end)}';
  }

  /// 期間を持つ予定か。単日の予定に期間表示を出すと冗長になる。
  bool get hasPeriod => endDate != null && endDate != startDate;

  bool coversDate(String date) {
    if (date.compareTo(startDate) < 0) return false;
    final end = endDate;
    // 終わりが決まっていない予定は、開始日以降ずっと続いている扱い
    if (end == null) return ongoing || date == startDate;
    return date.compareTo(end) <= 0;
  }
}

/// `calendar.json` 全体。
@freezed
abstract class CalendarPayload with _$CalendarPayload {
  const factory CalendarPayload({
    @JsonKey(name: 'generated_at') @Default('') String generatedAt,
    @Default(<CalendarEvent>[]) List<CalendarEvent> events,
  }) = _CalendarPayload;

  factory CalendarPayload.fromJson(Map<String, dynamic> json) =>
      _$CalendarPayloadFromJson(json);
}

// **gyumesy の `calendarVisibleTags`（白名簿）は持ってこない。** その語彙は
// 松屋のもので、とん速の配信と噛み合わない（web の `utils/calendar.ts`: 15 件の
// うち実在するのは 3 件）。**配信側が `visible_tags` で既に絞っている**ので、
// **`tags.json` に載っている＝見せてよい**、が契約（web と同じ）。
// 載っていない slug は出さない（予定の行は狭く、意味の分からない英字が並ぶと
// 「何の予定か」を読む邪魔になる。記事のタグとは逆の扱いで、これは意図的）。

/// 同じ日に並んだ予定の並び順。メニューを先に、キャンペーンを後ろに
/// （web の `CALENDAR_CATEGORY_PRIORITY`）。
const calendarCategoryPriority = <String, int>{
  'menu': 0,
  'official': 1,
  'store': 2,
  'campaign': 3,
};
