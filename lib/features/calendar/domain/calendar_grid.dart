import 'package:tonsoku/shared/models/calendar_event.dart';

/// 月グリッドの幾何計算。**描画を持たない純粋な計算**にしてあるので、レーンの
/// 割り当てだけをテストで固定できる（web の `calendar-grid.ts` と同じ分け方）。
///
/// **gyumesy-frontend-app からそのまま写した。** とん速の web の
/// `calendar-grid.ts` は gyumesy の web と計算が同じ（2026-09-25 に突き合わせた。
/// 違うのは描画側の色と線の濃さだけで、そちらは `MonthGrid` が持つ）。

/// 1 週に確保するレーンの本数。web の `MAX_LANES`。
///
/// **予定数や月でマスの高さを変えない。** 変えると月送りのたびにグリッドが
/// 伸縮して、どの日を見ていたのか分からなくなる。
const maxLanes = 6;

/// 週 1 本ぶんの配置。
class WeekLayout {
  const WeekLayout({
    required this.week,
    required this.segments,
    required this.overflow,
  });

  /// 日曜始まりの 7 日（`YYYY-MM-DD`）。**日付は文字列のまま扱う。**
  /// 配信データが JST の日付で来るので、`DateTime` に起こすと端末の
  /// タイムゾーンで前後にずれる余地が生まれる。
  final List<String> week;
  final List<GridSegment> segments;

  /// 曜日ごとの「載り切らなかった予定」。`+N` と、その一覧に使う。
  final List<List<CalendarEvent>> overflow;
}

/// 線 1 本、または丸ポチ 1 つ。
class GridSegment {
  const GridSegment({
    required this.events,
    required this.category,
    required this.lane,
    required this.colStart,
    required this.colEnd,
    required this.hasPeriod,
    required this.startsHere,
    required this.endsHere,
    required this.ended,
    required this.ongoing,
  });

  /// この線が表す予定。**同じ期間の予定は 1 本を共有する。**
  final List<CalendarEvent> events;
  final String category;
  final int lane;

  /// 週内の列（0..6）。
  final int colStart;
  final int colEnd;

  /// 線（期間）か、開始日の丸ポチだけか。
  final bool hasPeriod;
  final bool startsHere;
  final bool endsHere;

  /// 終了日が確定している（白抜き）か、継続中（三角）か。
  final bool ended;
  final bool ongoing;
}

/// 線を引く終端。**継続中の予定は今日まで伸ばす。**
String spanEnd(CalendarEvent event, String today) {
  final end = event.endDate;
  if (end != null && end != event.startDate) return end;
  return event.ongoing && today.compareTo(event.startDate) > 0
      ? today
      : event.startDate;
}

/// その予定が線（期間）になるか。
///
/// **まだ始まっていない継続中の予定は丸ポチだけにする。** 伸ばす先が無いので、
/// 開始日＝終端の 1 日の線になり、線が途切れているように見える。
bool hasSpan(CalendarEvent event, String today) {
  final end = event.endDate;
  if (end != null && end != event.startDate) return true;
  return event.ongoing && event.startDate.compareTo(today) < 0;
}

/// **選んだカテゴリの予定にだけ線を引く。**
///
/// 全カテゴリを一度に線にすると、常時並走するキャンペーンや一時閉店で画面が
/// 線だらけになり、日付も予定名も読めなくなる。既定（すべて）は線なし。
bool drawsLine(CalendarEvent event, String? lineMode, String today) =>
    lineMode != null && event.category == lineMode && hasSpan(event, today);

/// その月を含む週（日曜始まり・7 日ぶん）の並び。
List<List<String>> monthWeeks(String monthKey) {
  final parts = monthKey.split('-');
  final year = int.parse(parts[0]);
  final month = int.parse(parts[1]);
  final first = DateTime.utc(year, month, 1);
  final last = DateTime.utc(year, month + 1, 0);
  // DateTime.weekday は月曜が 1。日曜始まりに直す
  final start = first.subtract(Duration(days: first.weekday % 7));

  final weeks = <List<String>>[];
  for (
    var day = start;
    !day.isAfter(last);
    day = day.add(const Duration(days: 7))
  ) {
    weeks.add([for (var i = 0; i < 7; i++) _iso(day.add(Duration(days: i)))]);
  }
  return weeks;
}

String _iso(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// 2 つの日付（`YYYY-MM-DD`）の日数の差。
///
/// **UTC で読むこと。** `DateTime.parse('2026-10-04')` は**端末のローカル時刻の
/// 0 時**になるので、夏時間の切り替えをまたぐと差が 23 時間になり、`inDays` が
/// **1 日少なく**数える（シドニーの時刻設定の端末で、10/4〜10/9 の線が 1 日手前で
/// 終わり、10/10 の印が金曜の列に出た。PR #22 のレビューで再現）。英語・中国語の
/// 利用者は海外の端末で開きうる。web も UTC で差を取っている
int _dayIndex(String from, String to) =>
    utcDate(to).difference(utcDate(from)).inDays;

/// `YYYY-MM-DD` を UTC の 0 時として読む（[_dayIndex] の doc。日を足す計算も
/// これを通す —— `calendar_window.dart` の `addDays`）。
DateTime utcDate(String iso) {
  final [y, m, d] = iso.substring(0, 10).split('-').map(int.parse).toList();
  return DateTime.utc(y, m, d);
}

/// 安定な並び替え。**同点は元の並び順を保つ。**
///
/// **`List.sort` は安定ではない。** 同点だけの配列でも順序が崩れる（実測で
/// 10 件から）。ここで崩れると、同じ日の丸ポチの上下が入れ替わるだけでなく、
/// **`+N` に落ちる予定が変わって「見えていたものが隠れる」**。しかも不安定な
/// 並びは入力順に敏感なので、**無関係な予定を 1 件足しただけで別の予定の
/// レーンが動く**。
///
/// web の `Array.prototype.sort` は ES2019 以降**安定が仕様**なので、同じ結果に
/// するにはこちら側で安定にする必要がある（元の添字を最後の比較に足す）。
List<T> stableSorted<T>(List<T> items, int Function(T a, T b) compare) {
  final decorated = [for (final (index, item) in items.indexed) (index, item)];
  decorated.sort((a, b) {
    final result = compare(a.$2, b.$2);
    return result != 0 ? result : a.$1 - b.$1;
  });
  return [for (final entry in decorated) entry.$2];
}

/// その週の予定をレーンへ割り当てる。
WeekLayout layoutWeek(
  List<String> week,
  List<CalendarEvent> allEvents,
  String? lineMode,
  String today,
) {
  final weekStart = week.first;
  final weekEnd = week.last;
  int priority(String category) => calendarCategoryPriority[category] ?? 9;
  String endOf(CalendarEvent e) => spanEnd(e, today);

  // すべて（null）＝全予定を線なしで、カテゴリ選択＝その予定と線だけ
  final events = lineMode == null
      ? allEvents
      : allEvents.where((e) => e.category == lineMode).toList();

  // **線を引く予定は期間の重なる週すべてに、引かない予定は開始日のある週にだけ。**
  final inWeek = events.where((e) {
    if (drawsLine(e, lineMode, today)) {
      return e.startDate.compareTo(weekEnd) <= 0 &&
          endOf(e).compareTo(weekStart) >= 0;
    }
    return e.startDate.compareTo(weekStart) >= 0 &&
        e.startDate.compareTo(weekEnd) <= 0;
  }).toList();

  // **同じ期間の予定は 1 本の線を共有する**（代表 1 件だけレーンに載せる）。
  // 同日同カテゴリの予定が並ぶと線が何本も重なって読めなくなる
  final sharedLine = <String, List<CalendarEvent>>{};
  final active = <CalendarEvent>[];
  for (final e in inWeek) {
    if (!drawsLine(e, lineMode, today)) {
      active.add(e);
      continue;
    }
    final key = '${e.category}|${e.startDate}|${endOf(e)}';
    final group = sharedLine[key];
    if (group != null) {
      group.add(e);
      continue;
    }
    sharedLine[key] = [e];
    active.add(e);
  }

  bool hasMove(CalendarEvent e) =>
      (e.startDate.compareTo(weekStart) >= 0 &&
          e.startDate.compareTo(weekEnd) <= 0) ||
      (drawsLine(e, lineMode, today) &&
          endOf(e).compareTo(weekStart) >= 0 &&
          endOf(e).compareTo(weekEnd) <= 0);

  final sorted = stableSorted(active, (a, b) {
    // その週に動きのあるもの（始まる・終わる）を先に残す
    final move = (hasMove(b) ? 1 : 0) - (hasMove(a) ? 1 : 0);
    if (move != 0) return move;
    final pri = priority(a.category) - priority(b.category);
    if (pri != 0) return pri;
    final lengthA = _dayIndex(a.startDate, endOf(a));
    final lengthB = _dayIndex(b.startDate, endOf(b));
    if (lengthA != lengthB) return lengthA - lengthB;
    return a.startDate.compareTo(b.startDate);
  });

  ({int start, int end}) colsOf(CalendarEvent event) {
    final start = _dayIndex(weekStart, event.startDate).clamp(0, 6);
    final end = drawsLine(event, lineMode, today)
        ? _dayIndex(weekStart, endOf(event)).clamp(0, 6)
        : start;
    return (start: start, end: end);
  }

  /// 開いている最上段のレーンに順に載せる。載らなければ落とす。
  List<({CalendarEvent event, int lane, int colStart, int colEnd})> assignLanes(
    List<CalendarEvent> list,
  ) {
    final laneUsed = <List<bool>>[];
    final placed =
        <({CalendarEvent event, int lane, int colStart, int colEnd})>[];
    for (final event in list) {
      final cols = colsOf(event);
      var lane = 0;
      while (lane < maxLanes) {
        while (laneUsed.length <= lane) {
          laneUsed.add(List<bool>.filled(7, false));
        }
        final used = laneUsed[lane];
        if (!used.sublist(cols.start, cols.end + 1).contains(true)) break;
        lane++;
      }
      if (lane >= maxLanes) continue;
      for (var c = cols.start; c <= cols.end; c++) {
        laneUsed[lane][c] = true;
      }
      placed.add((
        event: event,
        lane: lane,
        colStart: cols.start,
        colEnd: cols.end,
      ));
    }
    return placed;
  }

  // **2 回積む。** 1 回目は優先度順で「残す線」を決め、2 回目は開始日昇順で
  // 積み直す。順番が違うと、同じ線が週をまたぐたびに別のレーンへ動いて見える
  final survivors = assignLanes(sorted).map((p) => p.event).toList();
  final placed = assignLanes(
    stableSorted(survivors, (a, b) => a.startDate.compareTo(b.startDate)),
  );

  final segments = [
    for (final p in placed)
      GridSegment(
        events: drawsLine(p.event, lineMode, today)
            ? (sharedLine['${p.event.category}|${p.event.startDate}|'
                      '${endOf(p.event)}'] ??
                  [p.event])
            : [p.event],
        category: p.event.category,
        lane: p.lane,
        colStart: p.colStart,
        colEnd: p.colEnd,
        hasPeriod: drawsLine(p.event, lineMode, today),
        startsHere:
            p.event.startDate.compareTo(weekStart) >= 0 &&
            p.event.startDate.compareTo(weekEnd) <= 0,
        endsHere:
            endOf(p.event).compareTo(weekStart) >= 0 &&
            endOf(p.event).compareTo(weekEnd) <= 0,
        ended: p.event.endDate != null,
        ongoing: p.event.ongoing,
      ),
  ];

  // **`+N` は「その日に動きがあるのに載せられなかった件数」。** 通過中の線は
  // 数えない（その日に何か起きたわけではないので）
  final survived = survivors.toSet();
  final overflow = List.generate(7, (_) => <CalendarEvent>[]);
  for (final event in sorted) {
    if (survived.contains(event)) continue;
    final edges = drawsLine(event, lineMode, today)
        ? {event.startDate, endOf(event)}
        : {event.startDate};
    for (final edge in edges) {
      if (edge.compareTo(weekStart) < 0 || edge.compareTo(weekEnd) > 0) {
        continue;
      }
      overflow[_dayIndex(weekStart, edge)].add(event);
    }
  }

  return WeekLayout(week: week, segments: segments, overflow: overflow);
}

/// 月ぶんの全週レイアウト。
List<WeekLayout> buildMonthGrid(
  List<CalendarEvent> events,
  String monthKey,
  String? lineMode,
  String today,
) => [
  for (final week in monthWeeks(monthKey))
    layoutWeek(week, events, lineMode, today),
];
