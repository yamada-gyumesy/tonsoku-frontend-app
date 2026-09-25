import 'package:tonsoku/features/calendar/domain/calendar_grid.dart';
import 'package:tonsoku/shared/models/calendar_event.dart';

/// カレンダーの日リスト・月の範囲の計算（gyumesy-frontend-app の
/// `calendar_window.dart` を写し、とん速の web の `utils/calendar.ts` に合わせ直した）。
///
/// **「今日」は呼び出し側が渡す**（`todayInJst()`）。ここで時計を読むと、
/// 同じ画面の中で月グリッドと日リストが別々の「今日」を見る余地が生まれる。
///
/// ## gyumesy との違い
///
/// - **中心日の前後の窓は web の `CoCalendarSection` から写した**（[scheduleWindow]）。
///   gyumesy の `buildRecentDays` は窓の中身で出し分けておらず、web が踏んだ
///   「見出しだけ出て中身が空」をそのまま持っている。使うのは今のところ記事詳細
///   だけ（ホームの「最近の予定」はとん速のアプリにまだ無い。入れる時はこれを使う）
/// - **月の範囲に下限と上限がある**（[calendarMonthRange]）
/// - **同じ日の予定は優先度 → 題で並べる**（[dayEntries]。gyumesy は配信の順のまま）

/// 月ナビで遡れる下限（`YYYY-MM`）。web の `CALENDAR_MONTH_FLOOR`。
///
/// **とん速の収集開始は 2026-09。** それ以前の日付を持つ予定は、初回一括取り込みで
/// 開始日が実際より古く入りうる（gyumesy が同じ形で踏んだ）。データは残すが
/// 遡らせない。**web の値を変えたらここも直す**（配信が過去分を埋めたら下げる）。
const calendarMonthFloor = '2026-09';

/// 今月から何ヶ月先まで月ナビで進めるか。web の `CALENDAR_MONTHS_AHEAD`。
///
/// **web が上限を持つ主な理由（全月を SSR するのでページが膨らむ）はアプリには
/// 無い**が、値は揃える。**松のやが「終売未定」を遠い日付で表しただけで、
/// 空の月へいくらでも進めるようになる**（gyumesy が「際限なく送れるようにしない。
/// 戻り方が分からなくなる」と書いているのと同じ害）。web とアプリで行ける月が
/// 違うと、同じ予定が片方でだけ見える。
///
/// 松のやの期間限定は数週間〜2ヶ月なので、3ヶ月先まで行ければ足りる
/// （それより先の予定は**その月へ行けないだけで、予定そのものは消えない**）。
const calendarMonthsAhead = 3;

/// 予定リストに出す 1 日ぶん。
class CalendarDay {
  const CalendarDay({
    required this.date,
    required this.day,
    required this.month,
    required this.weekday,
    required this.isToday,
    required this.events,
  });

  /// `2026-09-23` の形。
  final String date;
  final int day;
  final int month;

  /// 0 = 日曜、6 = 土曜。
  final int weekday;
  final bool isToday;
  final List<CalendarEvent> events;
}

String formatDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

String _monthOf(String date) => date.substring(0, 7);

/// `YYYY-MM` に月を足す（web の `addMonths`）。
String addMonths(String monthKey, int months) {
  final parts = monthKey.split('-');
  final shifted = DateTime.utc(
    int.parse(parts[0]),
    int.parse(parts[1]) + months,
  );
  return '${shifted.year.toString().padLeft(4, '0')}-'
      '${shifted.month.toString().padLeft(2, '0')}';
}

/// 月ナビで行ける範囲。web の `buildCalendarPayload` の `monthMin` / `monthMax`。
///
/// - 予定の開始月・終了月と今月を畳み込む
/// - **下限は [calendarMonthFloor]、上限は今月から [calendarMonthsAhead] ヶ月先**
/// - **下限が上限を超えたら、下限の月だけにする**（web: 逆転したままだと月が
///   1 つも出ない。**空の面を出すより、床の月を出すほうがよい**）
///
/// **今月が範囲の外に出ることはある**（下限が未来にある等）。その時に最初に出す
/// 月は [initialCalendarMonth] が端へ寄せる。**ここで今月を足し直さないこと**
/// （web がそれで下限と上限を両方打ち消していた）。
({String min, String max}) calendarMonthRange(
  List<CalendarEvent> events,
  String today,
) {
  final thisMonth = _monthOf(today);
  var rawMin = thisMonth;
  var rawMax = thisMonth;
  for (final e in events) {
    // **終わりの月まで数える**（開始日だけだと、長期予定の後半の月へ進めない）。
    // 継続中の線は今日までなので、今月の畳み込みで足りる
    for (final month in [
      _monthOf(e.startDate),
      if (e.endDate case final end?) _monthOf(end),
    ]) {
      if (month.compareTo(rawMin) < 0) rawMin = month;
      if (month.compareTo(rawMax) > 0) rawMax = month;
    }
  }
  final min = rawMin.compareTo(calendarMonthFloor) < 0
      ? calendarMonthFloor
      : rawMin;
  final ceiling = addMonths(thisMonth, calendarMonthsAhead);
  final capped = rawMax.compareTo(ceiling) > 0 ? ceiling : rawMax;
  return (min: min, max: capped.compareTo(min) < 0 ? min : capped);
}

/// 最初に出す月。**範囲の外なら端に寄せる**（web の `initialMonthKey`）。
///
/// gyumesy は「範囲の外なら今月」だったが、とん速には下限があるので今月も
/// 範囲の外になりうる。今月に落とすと、月グリッドだけが範囲外の月を出す。
String initialCalendarMonth(({String min, String max}) range, String today) {
  final month = _monthOf(today);
  if (month.compareTo(range.min) < 0) return range.min;
  if (month.compareTo(range.max) > 0) return range.max;
  return month;
}

/// 行ける月の中に、1 件でも行になる予定があるか。
///
/// **メニューのカレンダーの行はこれで出し分ける**（空の画面へ行ける入口を残さない。
/// web の `hasEvents`）。**`events` が空でないかでは見ない** —— 範囲の外の予定
/// （下限より前・上限より先）しか無い時に、行はあるのに開いたら空になる。
/// web も「判定は月セクションの中身で見る」と書いている。
bool hasCalendarEventsInRange(List<CalendarEvent> events, String today) {
  final range = calendarMonthRange(events, today);
  return events.any((e) {
    final month = _monthOf(e.startDate);
    return month.compareTo(range.min) >= 0 && month.compareTo(range.max) <= 0;
  });
}

int _priority(CalendarEvent e) => calendarCategoryPriority[e.category] ?? 9;

/// その日に**始まる**予定。日リストの 1 日ぶんの行。
///
/// **並びは優先度 → 題**（web の `buildDayList` の `sortByPriority`）。gyumesy は
/// 配信の順のまま出していたが、とん速の web は並べ直している。
///
/// **日リストの行と縦線の計算（`buildDayLanes`）は必ずこれを通す。** 線の
/// `entryIndex` は「その日の何行目から線を降ろすか」なので、並びが食い違うと
/// **線を持たない行から線が降りる**（gyumesy の注記）。
///
/// 題の比較は符号位置の順（web は `localeCompare`）。日本語の題どうしで
/// 並びが web と前後することはあるが、**アプリの中では行と線が同じ並びを見る**
/// ことのほうが要る。
List<CalendarEvent> dayEntries(List<CalendarEvent> events, String date) {
  final matched = [
    for (final e in events)
      if (e.startDate == date) e,
  ];
  return stableSorted(matched, (a, b) {
    final pri = _priority(a) - _priority(b);
    if (pri != 0) return pri;
    return a.title.compareTo(b.title);
  });
}

/// その日に**かかっている**予定を集める。
///
/// **開始日が同じものだけではない。** 期間予定はその途中の日にも出す
/// （「今日は何が売っているか」を見るのが日タップの目的なので、開始日だけだと
/// 昨日始まったキャンペーンが出てこない）。
///
/// **途中の日に入るのは線になる予定だけ**（web の `eventsOnDay`:
/// `hasSpan && spanEnd >= date`）。gyumesy は `end_date ?? (ongoing ? today : start)`
/// で見ていたので、**まだ始まっていない継続中**の扱いが web とずれていた。
///
/// 並びはカテゴリの優先度 → 開始日 → タイトル。web の `eventsOnDay` と同じ。
List<CalendarEvent> eventsOnDay(
  List<CalendarEvent> events,
  String date,
  String today,
) {
  final matched = events.where((e) {
    if (e.startDate.compareTo(date) > 0) return false;
    if (e.startDate == date) return true;
    return hasSpan(e, today) && spanEnd(e, today).compareTo(date) >= 0;
  }).toList();

  return stableSorted(matched, (a, b) {
    final pri = _priority(a) - _priority(b);
    if (pri != 0) return pri;
    final start = a.startDate.compareTo(b.startDate);
    if (start != 0) return start;
    return a.title.compareTo(b.title);
  });
}

/// その月の全日。**カレンダー画面の日リスト用。**
///
/// 予定の有無にかかわらず 1 か月ぶんすべて並べる。日付が歯抜けになると、
/// 月のどこを見ているのか分からなくなる。
List<CalendarDay> buildMonthDays(
  List<CalendarEvent> events,
  String monthKey,
  String today,
) {
  final parts = monthKey.split('-');
  final year = int.parse(parts[0]);
  final month = int.parse(parts[1]);
  final last = DateTime.utc(year, month + 1, 0).day;

  return buildDays(events, [
    for (var day = 1; day <= last; day++)
      formatDate(DateTime.utc(year, month, day)),
  ], today);
}

/// [dates]（`YYYY-MM-DD`）の各日を日リストの行にする（web の `buildDayList` の
/// 行の組み立て）。**月の日リストと記事の前後の予定が同じ行を作る。**
List<CalendarDay> buildDays(
  List<CalendarEvent> events,
  List<String> dates,
  String today,
) => [
  for (final key in dates)
    () {
      final date = utcDate(key);
      return CalendarDay(
        date: key,
        day: date.day,
        month: date.month,
        // Dart は月曜=1 / 日曜=7。web（`weekdays` の並び）は日曜=0 なので合わせる
        weekday: date.weekday % 7,
        isToday: key == today,
        // **その日に始まる予定だけ並べる。** 期間の途中の日まで毎日並べると
        // 同じ予定が何度も出て、その日に何が起きたのか読めなくなる
        // （途中の日も見たい時は日付を押すとシートに出る）
        events: dayEntries(events, key),
      );
    }(),
];

/// `YYYY-MM-DD` に日を足す（web の `addDays`。web も `Date.UTC` で足している）。
///
/// **端末のローカル時刻で足さないこと**（`DateTime.parse` ＋ `Duration(days: 1)`）。
/// 夏時間の終わりをまたぐと 1 日が 25 時間になり、同じ日付が 2 回出る
/// （`calendar_grid.dart` の `_dayIndex` の doc。シドニーの端末で踏んだ形）。
String addDays(String date, int days) {
  final base = utcDate(date);
  return formatDate(DateTime.utc(base.year, base.month, base.day + days));
}

/// 中心日より前に出す日数（web の `CoCalendarSection` の `VISIBLE_BEFORE`）。
///
/// **直前に何があったかも見せたいので過去側にも出す**（web のコメント）。
const scheduleWindowBefore = 2;

/// 中心日より後に出す日数（web の `VISIBLE_AFTER`）。
const scheduleWindowAfter = 2;

/// 中心日の前後の窓（web の `CoCalendarSection` の計算を写した）。
///
/// - [dates] … 窓の日付（昇順・連続）
/// - [today] … 窓の描画に使う「今日」（[clampTodayToWindow]）
/// - [events] … 窓の描画と日タップに要る予定だけ（[narrowEventsToWindow]）
typedef ScheduleWindow = ({
  List<String> dates,
  String today,
  List<CalendarEvent> events,
});

/// [center] を中心に前後 [scheduleWindowBefore] / [scheduleWindowAfter] 日の窓を作る。
///
/// **記事詳細は記事の掲載日を中心にする**（web: 古い記事を読んでいる時に
/// 「今日の予定」が出ても話が繋がらない）。
///
/// **窓に予定が 1 件も無ければ節ごと出さないこと**（`events.isEmpty` で見る）。
/// web のコメント: 絞り込み前の予定で見ると、**予定はあるが窓の中には無い**時に
/// 見出しだけが出て中身が空になる（配信が動けば普通に起きる。実際にその形だった）。
ScheduleWindow scheduleWindow(
  List<CalendarEvent> events, {
  required String center,
  required String today,
}) {
  final dates = [
    for (var i = -scheduleWindowBefore; i <= scheduleWindowAfter; i++)
      addDays(center, i),
  ];
  // 継続中の予定の線の終端は窓の翌日で頭打ちにする。窓の外へ伸びた線はどのみち窓で
  // クリップされるので見え方は変わらない（web のコメント）
  final windowToday = clampTodayToWindow(today, dates);
  return (
    dates: dates,
    today: windowToday,
    events: narrowEventsToWindow(events, dates, windowToday),
  );
}

/// 窓の描画に使う「今日」（web の `clampTodayToWindow`）。
///
/// 継続中の予定の線は今日まで伸びるので、実際の今日をそのまま使うと日付が
/// 変わるだけで過去記事の描画まで変わる。窓の外へ伸びた線はどのみち窓で
/// クリップされるため、窓の翌日で頭打ちにしても見え方は一切変わらない。
/// 窓が今日を含むなら実際の今日を使うので、線が未来へ伸びて見えることはない。
///
/// **アプリは静的生成ではないので web ほどの理由は無い**が、日タップのシートに
/// 出す予定（`eventsOnDay`）も同じ「今日」を見るので、web と同じ値にそろえる。
String clampTodayToWindow(String today, List<String> dates) {
  if (dates.isEmpty) return today;
  final afterWindow = addDays(dates.last, 1);
  return today.compareTo(afterWindow) < 0 ? today : afterWindow;
}

/// 窓の描画に要る予定だけに絞る（web の `narrowPayloadToWindow`）。
///
/// 残す条件は日リスト（[dayEntries] と `buildDayLanes`）が使う条件と完全に
/// 同じにする（web: ここで絞りすぎるとレーンの割り当てが変わって線の位置が
/// ずれる）。
///
/// [today] は線の終端に使う日付。呼び出し側で窓に合わせてクランプ済みのものを渡す。
List<CalendarEvent> narrowEventsToWindow(
  List<CalendarEvent> events,
  List<String> dates,
  String today,
) {
  if (dates.isEmpty) return const [];
  final rangeStart = dates.first;
  final rangeEnd = dates.last;
  final inWindow = dates.toSet();
  return [
    for (final e in events)
      // その日に始まる予定（＝行になる予定）
      if (inWindow.contains(e.startDate) ||
          // 窓を通過する期間の予定（＝線になる予定）
          (hasSpan(e, today) &&
              e.startDate.compareTo(rangeEnd) <= 0 &&
              spanEnd(e, today).compareTo(rangeStart) >= 0))
        e,
  ];
}
