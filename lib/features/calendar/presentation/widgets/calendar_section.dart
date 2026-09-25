import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tonsoku/core/i18n/locale_controller.dart';
import 'package:tonsoku/core/utils/article_date.dart';
import 'package:tonsoku/features/calendar/domain/calendar_window.dart';
import 'package:tonsoku/features/calendar/presentation/widgets/calendar_day_row.dart';
import 'package:tonsoku/features/calendar/presentation/widgets/day_events_sheet.dart';
import 'package:tonsoku/shared/models/calendar_event.dart';
import 'package:tonsoku/shared/models/category.dart';
import 'package:tonsoku/shared/models/tag.dart';
import 'package:tonsoku/shared/widgets/section_heading.dart';
import 'package:tonsoku/shared/widgets/view_calendar_link.dart';

/// 中心日の前後の予定。web の `CoCalendarSection`（gyumesy-frontend-app の
/// `RecentScheduleSection` を写し、とん速の web に合わせ直した）。
///
/// **中心日の前後 2 日を出す。** これからの予定だけにしないのは、直前に何が
/// あったか（昨日終わったキャンペーンなど）も知りたいため。
///
/// **窓に予定が 1 件も無ければ節ごと出さない**（[scheduleWindow] の doc）。
///
/// ## gyumesy との違い
///
/// - **出すかどうかは窓の中身で決める**（gyumesy は `events.isEmpty`。web が
///   それで「見出しだけ出て中身が空」を踏んだ）
/// - **大見出しの形（web の `prominent`）だけを持つ。** 使うのは記事詳細だけで、
///   ホームの「最近の予定」（小見出しの形）はとん速のアプリにまだ無い。入れる時に
///   web の寸法で足すこと（[ViewCalendarLink] の doc と同じ）
/// - **見出しは呼び出し側が必ず渡す**（既定の「最近の予定」を持たない。上と同じ理由）
/// - **線を引かない**（カテゴリ面が無いので `lineMode` を持たない。web の
///   記事ページも `category` を渡さず、線なしで全予定を出している）
/// - **花吹雪を鳴らさない**（`CalendarPage` の doc）
///
/// **押した時の挙動はカレンダー画面と同じ**（web は `CoCalendarSection` でも
/// `bindMarks` と `bindDaySelect` を呼んでいる。「カレンダーページ・TOP・記事内の
/// どのリストでも同じ挙動になるよう共有する」とコメントに明記されている）。
class CalendarSection extends ConsumerStatefulWidget {
  const CalendarSection({
    required this.events,
    required this.center,
    required this.heading,
    required this.onOpenArticle,
    required this.onOpenCalendar,
    this.categories = const [],
    this.tags = const [],
    this.padding = EdgeInsets.zero,
    super.key,
  });

  /// 配信の予定（全期間）。**窓に絞るのはこの節の仕事**（呼び出し側に持たせると、
  /// 窓の広さを知らない側が件数だけで出し分けることになる。web のコメント）。
  final List<CalendarEvent> events;

  /// 表示の中心日（`YYYY-MM-DD`）。**記事詳細は記事の掲載日を渡す**
  /// （今日基準にすると、古い記事を読んでいる人に無関係な今日の予定が出る）。
  final String center;

  final String heading;
  final ValueChanged<String> onOpenArticle;

  /// 「カレンダーをみる」を押した時。**中心日の月（`YYYY-MM`）を渡す**
  /// （web の `calendarHash` の `month=${baseDate.slice(0, 7)}`）。記事詳細から
  /// 押せばその記事の月が開く。
  final ValueChanged<String> onOpenCalendar;
  final List<Category> categories;
  final List<Tag> tags;

  /// 節の外側の余白。**節を出す時だけ取る**（出さない時に余白だけが残ると、
  /// 前の節との間に何も無い空白が開く）。
  final EdgeInsets padding;

  @override
  ConsumerState<CalendarSection> createState() => _CalendarSectionState();
}

class _CalendarSectionState extends ConsumerState<CalendarSection> {
  /// いま開いているマークの予定 id。**押したものだけ残して他を薄くする**
  /// （web の `applyHighlight`）。
  ///
  /// **この面にも要る。** web は `CoCalendarSection` でも `bindMarks` を
  /// 呼んでいるので、**カレンダー画面と処理が完全に同じ**（gyumesy の注記）。
  var _activeEventIds = const <String>{};

  /// 押している日付。**その行を塗る**（web の `highlightDay`）。
  String? _selectedDate;

  /// 日付行を押した時。**その日にかかる予定をまとめて出し、行を塗る。**
  Future<void> _openDay(String date, ScheduleWindow window) {
    setState(() => _selectedDate = date);
    return showDayEventsSheet(
      context,
      date: date,
      today: window.today,
      events: window.events,
      categories: widget.categories,
      tags: widget.tags,
      onOpenArticle: widget.onOpenArticle,
    ).whenComplete(() {
      // **閉じたら必ず戻す**（web は `popover.onHide` で消している）
      if (mounted) setState(() => _selectedDate = null);
    });
  }

  /// マーク（丸ポチ・線）を押した時。**押した予定だけを出す**
  /// （カレンダー画面の `_openEvents` と同じ）。
  ///
  /// **1 件でも記事へ直行しない**（web は押すとポップオーバーを出すだけで、
  /// 記事へは中の題を押して初めて飛ぶ）。
  Future<void> _openMark(
    String date,
    List<CalendarEvent> picked,
    ScheduleWindow window,
  ) async {
    if (picked.isEmpty) return;
    setState(() {
      _activeEventIds = {for (final e in picked) e.id};
      // **日の強調は落とす。** web も `popover.onRender` で消している
      _selectedDate = null;
    });
    try {
      await showDayEventsSheet(
        context,
        date: date,
        today: window.today,
        events: picked,
        categories: widget.categories,
        tags: widget.tags,
        onOpenArticle: widget.onOpenArticle,
      );
    } finally {
      // **閉じたら必ず戻す**（記事へ遷移して戻ってきた時も薄いままにしない）
      if (mounted) setState(() => _activeEventIds = const {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final window = scheduleWindow(
      widget.events,
      center: widget.center,
      today: todayInJst(),
    );
    // **窓の中身で判定する**（[scheduleWindow] の doc）。空の枠だけ残ると、
    // 読み込みに失敗したのか元々無いのか分からない
    if (window.events.isEmpty) return const SizedBox.shrink();

    final t = ref.watch(messagesProvider);
    final days = buildDays(window.events, window.dates, window.today);

    return Padding(
      padding: widget.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // web の `pb-2 mb-4 border-b-2 border-brand-primary-text` の大見出しと、
          // その右の導線（ランキング・通知設定の見出しと同じ置き方）
          SectionHeading(
            label: widget.heading,
            trailing: ViewCalendarLink(
              label: t.calendarViewCalendar,
              onTap: () => widget.onOpenCalendar(widget.center.substring(0, 7)),
            ),
          ),
          const SizedBox(height: 16),
          for (final day in days)
            CalendarDayRow(
              day: day,
              // **月が変わる所に見出しを出す**（web の `i > 0 && row.day === 1`）。
              // 日付の数字が 31 → 1 と戻るだけでは月が変わったと分からない
              showMonthHeading: day != days.first && day.day == 1,
              // **線は引かない**（クラスの doc）。`lines` / `laneCount` は既定の空
              selected: day.date == _selectedDate,
              activeEventIds: _activeEventIds,
              categories: widget.categories,
              tags: widget.tags,
              onOpenArticle: widget.onOpenArticle,
              // **日付行を押すと、その日にかかっている予定をまとめて出す。**
              // 行に並ぶのは開始日がその日の予定だけなので、昨日始まって今日も
              // 続いているキャンペーンはここでしか見えない
              onTapDay: () => _openDay(day.date, window),
              // **印を押したらその予定だけ**（カレンダー画面と同じ）
              onTapEvent: (e) => _openMark(day.date, [e], window),
              onTapLine: (ids) => _openMark(day.date, [
                for (final e in window.events)
                  if (ids.contains(e.id)) e,
              ], window),
            ),
        ],
      ),
    );
  }
}
