import 'package:tonsoku/features/calendar/domain/calendar_grid.dart';
import 'package:tonsoku/features/calendar/domain/calendar_window.dart';
import 'package:tonsoku/shared/models/calendar_event.dart';

/// 日リストの縦線。**web の `buildDayList` / `lineSpanInRow` と同じ計算**
/// （`tonsoku-frontend-web/src/utils/calendar.ts`。gyumesy-frontend-app から写した）。
///
/// 日リストは行が「開始日」しか作らないので、**期間予定は縦線で日をまたぐ**。
/// 線が無いと、単日の予定と期間の予定が丸ポチだけで区別できない。
///
/// **線を出すのは 1 カテゴリを選んでいる時だけ。** 全部を一度に引くと、常時
/// 並走するキャンペーンや一時閉店で溝が線だらけになって日付が読めない
/// （月グリッドの `drawsLine` と同じ考え方）。

/// 溝に確保するレーンの上限。web の `LIST_MAX_LANES`。
const listMaxLanes = 12;

/// レーン 1 本の幅。web の `--lane-w`（SP=10px / PC=12px）。**狭い側に合わせる。**
const laneWidth = 10.0;

/// 溝の幅の下駄。web の `CONNECTOR_W`。
const connectorWidth = 14.0;

/// 丸ポチの直径。web の `DOT`。
const listDot = 6.0;

/// その日における線の位置。
enum DayLinePos {
  /// この日に始まる。
  start,

  /// 通過中。
  middle,

  /// この日で終わる。**行は作らない**（終わりは白抜きの丸ポチで示す）。
  end,
}

/// 行の中で縦線をどう引くか。web の `SPAN_STYLE`。
enum LineSpan {
  /// 引かない。
  none,

  /// 行の高さいっぱい。
  full,

  /// 丸ポチの下から行末まで（線の始まり）。
  below,

  /// 行頭から丸ポチまで（線の終わり）。
  above,
}

/// 日リストの縦線 1 本（その日のぶん）。
class DayListLine {
  DayListLine({
    required this.lane,
    required this.category,
    required this.eventIds,
    required this.pos,
    required this.ongoing,
    required this.entryIndex,
  });

  final int lane;
  final String category;

  /// **同じ期間の予定は 1 本を共有する。** 同じ期間に何品も出ると、
  /// 予定ごとに線を引くと同じ期間の線が並んで潰れる（gyumesy の注記。松のやでも
  /// 店舗限定は同じ期間で複数品出る）。
  final List<String> eventIds;

  final DayLinePos pos;

  /// 終わりが決まっていない継続中。**終端の丸ポチを打たない**（今日で切れて
  /// いるだけで終わってはいない）。
  final bool ongoing;

  /// 始まる日で、どの行の丸ポチから線を降ろすか。**その日の並び順で一番上**。
  /// ここを最小に取らないと、上の丸ポチに線が繋がらず「丸ポチだけ浮いて線が
  /// 一段下から始まる」＝点と線で途切れて見える。
  int? entryIndex;

  /// 行 [rowIndex] でこの線をどう引くか。web の `lineSpanInRow`。
  ///
  /// **終わる線はその日の先頭行にだけ引く。** web は全行に同じ形で出力して
  /// おいて、`applyListLineMode` が**表示中の先頭行以外を `display: none`**
  /// にしている（`calendar-list-mode.ts`）。そこを移さずに全行へ引くと、
  /// **同じ日に予定が複数ある時、行ごとに 12px の切れ端が並ぶ。**
  LineSpan spanInRow(int rowIndex) {
    if (pos == DayLinePos.start) {
      if (entryIndex == null) return LineSpan.full;
      if (rowIndex < entryIndex!) return LineSpan.none;
      return rowIndex == entryIndex! ? LineSpan.below : LineSpan.full;
    }
    if (pos == DayLinePos.end) {
      return rowIndex == 0 ? LineSpan.above : LineSpan.none;
    }
    return LineSpan.full;
  }
}

/// 日リストのレーン割り当て。
class DayLanes {
  const DayLanes(this._byDate, this.laneCount);

  final Map<String, List<DayListLine>> _byDate;

  /// 使ったレーンの本数。**溝の幅を決める**（使っていないぶんは空けない）。
  final int laneCount;

  static const empty = DayLanes({}, 0);

  List<DayListLine> linesOn(String date) => _byDate[date] ?? const [];
}

/// [dates] の範囲について、期間予定にレーンを割り当てる。
///
/// **レーンはカテゴリごとに独立**（同時に出るのは 1 カテゴリだけなので互いに
/// 干渉しない）。どのカテゴリを選んでも線が左端から詰まる。
///
/// [category] を渡すとそのカテゴリだけを対象にする。**null なら線を引かない**
/// （web の「すべて」＝線なし）。
DayLanes buildDayLanes(
  List<CalendarEvent> events,
  List<String> dates,
  String today, {
  required String? category,
}) {
  if (category == null || dates.isEmpty) return DayLanes.empty;
  final rangeStart = dates.first;
  final rangeEnd = dates.last;

  // **安定な並べ替えを使う。** `List.sort` は安定ではなく、同じ開始日だけの
  // 配列でも順序が崩れる（`calendar_grid.dart` の `stableSorted` の doc）。
  // ここが崩れると**同じ期間のどれが代表になるかが入力順で変わり**、レーンの
  // 割り当てが無関係な予定を 1 件足しただけで動く。
  final spans = stableSorted(
    events
        .where(
          (e) =>
              e.category == category &&
              hasSpan(e, today) &&
              e.startDate.compareTo(rangeEnd) <= 0 &&
              spanEnd(e, today).compareTo(rangeStart) >= 0,
        )
        .toList(),
    (a, b) => a.startDate.compareTo(b.startDate),
  );

  String periodKey(CalendarEvent e) =>
      '${e.category}|${e.startDate}|${spanEnd(e, today)}';

  // 空いている一番上のレーンへ載せる。使い切ったら最後のレーンに重ねる
  // （落として丸ポチだけにすると、期間予定が単日と見分けられなくなる）。
  final laneIntervals = <List<(String, String)>>[];
  final laneOfPeriod = <String, int>{};
  final laneOf = <String, int>{};
  for (final event in spans) {
    final key = periodKey(event);
    final shared = laneOfPeriod[key];
    if (shared != null) {
      laneOf[event.id] = shared;
      continue;
    }
    final span = (event.startDate, spanEnd(event, today));
    var lane = laneIntervals.indexWhere(
      (intervals) => !intervals.any(
        (i) => span.$1.compareTo(i.$2) <= 0 && span.$2.compareTo(i.$1) >= 0,
      ),
    );
    if (lane == -1) {
      if (laneIntervals.length >= listMaxLanes) {
        lane = listMaxLanes - 1;
      } else {
        lane = laneIntervals.length;
        laneIntervals.add([]);
      }
    }
    laneIntervals[lane].add(span);
    laneOfPeriod[key] = lane;
    laneOf[event.id] = lane;
  }

  final byDate = <String, List<DayListLine>>{};
  for (final date in dates) {
    // その日に行を作る予定（開始日が一致するもの）。
    //
    // **描画側（`buildMonthDays`）と同じ関数で並べる。** `entryIndex` は
    // 「描かれる行の何番目から線を降ろすか」なので、並びが食い違うと
    // **`below` が線を持たない行に付く**（丸ポチだけ浮いて線が一段下から始まる）。
    // gyumesy は両方とも配信の順のままにして揃えていたが、とん速の web は
    // 優先度 → 題で並べ直すので、その並べ方を [dayEntries] 1 か所に置いた
    final entries = dayEntries(events, date);

    final linesByPeriod = <String, DayListLine>{};
    for (final e in spans) {
      final lane = laneOf[e.id];
      if (lane == null) continue;
      if (e.startDate.compareTo(date) > 0) continue;
      if (spanEnd(e, today).compareTo(date) < 0) continue;

      final key = periodKey(e);
      final existing = linesByPeriod[key];
      if (existing != null) {
        existing.eventIds.add(e.id);
        if (existing.pos == DayLinePos.start) {
          final idx = entries.indexWhere((x) => x.id == e.id);
          if (idx != -1 &&
              (existing.entryIndex == null || idx < existing.entryIndex!)) {
            existing.entryIndex = idx;
          }
        }
        continue;
      }
      final end = spanEnd(e, today);
      final pos = e.startDate == date
          ? DayLinePos.start
          : end == date
          ? DayLinePos.end
          : DayLinePos.middle;
      final idx = pos == DayLinePos.start
          ? entries.indexWhere((x) => x.id == e.id)
          : -1;
      linesByPeriod[key] = DayListLine(
        lane: lane,
        category: e.category,
        eventIds: [e.id],
        pos: pos,
        ongoing: e.endDate == null && e.ongoing,
        entryIndex: idx == -1 ? null : idx,
      );
    }
    if (linesByPeriod.isNotEmpty) {
      byDate[date] = linesByPeriod.values.toList(growable: false);
    }
  }

  // **使ったぶんだけ溝を空ける。** 上限まで確保すると、線が 1 本の日でも
  // 予定名が右へ押し出される（web の `compactLanes` と同じ意図）。
  final used = <int>{
    for (final lines in byDate.values)
      for (final l in lines) l.lane,
  };
  return DayLanes(
    byDate,
    used.isEmpty ? 0 : used.reduce((a, b) => a > b ? a : b) + 1,
  );
}
