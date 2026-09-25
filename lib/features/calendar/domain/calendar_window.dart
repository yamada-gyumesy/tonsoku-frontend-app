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
/// - **ホームの「最近の予定」（`buildRecentDays`）を持ってきていない。** とん速の
///   アプリのホームにはまだその節が無い（入れる時に web の `CoCalendarSection` と
///   一緒に写すこと）。使わない計算を置くと、直す時に片方だけ古くなる
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

  return [
    for (var day = 1; day <= last; day++)
      () {
        final date = DateTime.utc(year, month, day);
        final key = formatDate(date);
        return CalendarDay(
          date: key,
          day: day,
          month: month,
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
}
