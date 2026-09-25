import 'package:flutter/material.dart';

import 'package:tonsoku/core/theme/app_colors.dart';
import 'package:tonsoku/features/calendar/domain/calendar_grid.dart';
import 'package:tonsoku/shared/models/calendar_event.dart';

/// 月グリッド 1 か月ぶん。寸法は web の `CoCalendar` と同じ（SP の値）。
/// gyumesy-frontend-app の `MonthGrid` を写し、色をとん速の web に合わせ直した。
///
/// ## gyumesy との違い（どれも web の `CoCalendar.astro` に合わせたもの）
///
/// - **期間の線を 0.75 まで濃くする**（gyumesy は 0.45）。線は「いつからいつまでか」
///   を示す**意味を持つ非テキスト**なので 3:1 が要る。web の実測で、0.45 だと
///   面に対して 1.88〜2.33（キャンペーンの黄土が最も薄い）、0.75 なら 3.13〜4.87
/// - **日・土の数字を薄めない**（文字の基準 4.5:1）。日曜は `primaryText`、
///   土曜は `green`（gyumesy は赤・青を 50%・60% に薄めていた）
/// - **今日の丸は塗りの `primary` に `onPrimary`**（地の上に置く赤ではなく塗り）
/// - **選んだ日の地は `primarySoft`**（web の `bg-brand-primary-soft`）
/// - 曜日の見出しと `+N` を薄めない（web は `text-brand-text-sub` のまま）
///
/// **マスの高さを予定数や月で変えない。** 変えると月送りのたびにグリッドが
/// 伸縮して、どの日を見ていたのか分からなくなる。レーンは常に
/// [maxLanes] 本ぶん確保する。
class MonthGrid extends StatelessWidget {
  const MonthGrid({
    required this.weeks,
    required this.monthKey,
    required this.today,
    required this.weekdays,
    required this.eventCountLabel,
    required this.onTapDay,
    required this.onTapEvents,
    this.activeEventIds = const {},
    this.selectedDate,
    super.key,
  });

  /// 日付の数字が占める高さ。
  static const numberHeight = 24.0;

  /// レーン 1 本。**当たり判定を兼ねるので線（2px）より広い。**
  static const laneHeight = 9.0;

  /// 丸ポチの直径。
  static const dot = 5.0;

  /// `+N` の高さ。
  static const moreHeight = 12.0;

  /// マスの下の余白。
  static const pad = 6.0;

  static const overlayTop = numberHeight + 2;
  static const moreTop = overlayTop + laneHeight * maxLanes + 3;

  /// マス 1 つの高さ。
  static const cellHeight = moreTop + moreHeight + pad;

  /// 期間の線の濃さ。web の `opacity: 0.75`（理由はクラスの doc）。
  /// **日リストの縦線も同じ値**（`CalendarDayRow`）。
  static const lineOpacity = 0.75;

  final List<WeekLayout> weeks;
  final String monthKey;
  final String today;
  final List<String> weekdays;

  /// 1 本の線がまとめている件数の読み上げ名（`3件の予定`）。
  final String Function(int count) eventCountLabel;

  final ValueChanged<String> onTapDay;

  /// 線・丸ポチ・`+N` を押した時。**まとめて渡す**（同じ期間の予定は 1 本の線を
  /// 共有しているので、押した先で選ばせる）。
  ///
  /// `date` は**押されたマスの日**。線は何日にもまたがるので、代表の開始日を
  /// 渡すと「8/24 を押したのに 3/17 と出る」ことになる。
  final void Function(String date, List<CalendarEvent> events) onTapEvents;

  /// いま開いている予定の id。**空でない間、当てはまらないマークを薄くする。**
  ///
  /// web と同じ（`calendar-popover.ts` の `gy-cal-dim` / `gy-cal-active`）。
  /// **薄くするのは月グリッドの中だけ** —— 押したビューの中だけを落とすので、
  /// 日リストは触らない。
  ///
  /// **id で突き合わせる。** 週をまたぐ線は週ごとに別の [GridSegment] に割れる
  /// ので、同じ予定を持つ断片は**全部**明るいまま残る（web も同じ）。
  final Set<String> activeEventIds;

  /// いま開いている日（`YYYY-MM-DD`）。**そのマスを光らせる**
  /// （web の `bindDaySelect.highlightDay`）。日リストの行も同じ日を光らせる。
  final String? selectedDate;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            for (final label in weekdays)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1,
                      color: colors.textSub,
                    ),
                  ),
                ),
              ),
          ],
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: colors.border.withValues(alpha: 0.4)),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final week in weeks)
                _Week(
                  week: week,
                  monthKey: monthKey,
                  today: today,
                  eventCountLabel: eventCountLabel,
                  onTapDay: onTapDay,
                  onTapEvents: onTapEvents,
                  activeEventIds: activeEventIds,
                  selectedDate: selectedDate,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 開いている予定以外を薄くする。**web の `gy-cal-dim` / `gy-cal-active` と同じ。**
///
/// [active] が空なら何も落とさない（既定の見え方）。空でない時、[ids] と 1 つも
/// 重ならないマークだけ薄くなる。
class _Dimmed extends StatelessWidget {
  const _Dimmed({required this.active, required this.ids, required this.child});

  /// web の `opacity: 0.3`。
  static const dimmed = 0.3;

  /// web の `transition: opacity 0.12s`。
  static const duration = Duration(milliseconds: 120);

  final Set<String> active;
  final Iterable<String> ids;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
    opacity: active.isEmpty || ids.any(active.contains) ? 1 : dimmed,
    duration: duration,
    child: child,
  );
}

class _Week extends StatelessWidget {
  const _Week({
    required this.week,
    required this.monthKey,
    required this.today,
    required this.eventCountLabel,
    required this.onTapDay,
    required this.onTapEvents,
    required this.activeEventIds,
    required this.selectedDate,
  });

  final WeekLayout week;
  final String monthKey;
  final String today;
  final String Function(int count) eventCountLabel;
  final ValueChanged<String> onTapDay;
  final void Function(String date, List<CalendarEvent> events) onTapEvents;
  final Set<String> activeEventIds;
  final String? selectedDate;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnWidth = constraints.maxWidth / 7;

        return SizedBox(
          height: MonthGrid.cellHeight,
          child: Stack(
            children: [
              Row(
                children: [
                  for (final (index, date) in week.week.indexed)
                    Expanded(
                      child: _DayCell(
                        date: date,
                        column: index,
                        monthKey: monthKey,
                        today: today,
                        overflow: week.overflow[index],
                        onTap: () => onTapDay(date),
                        onTapOverflow: (events) => onTapEvents(date, events),
                        activeEventIds: activeEventIds,
                        selected: date == selectedDate,
                      ),
                    ),
                ],
              ),
              // **予定はマスの上に重ねる。** マスの中に入れると週をまたぐ線が
              // 引けない
              for (final segment in week.segments)
                _Segment(
                  segment: segment,
                  columnWidth: columnWidth,
                  week: week.week,
                  eventCountLabel: eventCountLabel,
                  onTap: onTapEvents,
                  activeEventIds: activeEventIds,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.column,
    required this.monthKey,
    required this.today,
    required this.overflow,
    required this.onTap,
    required this.onTapOverflow,
    required this.activeEventIds,
    required this.selected,
  });

  final String date;
  final int column;
  final String monthKey;
  final String today;
  final List<CalendarEvent> overflow;
  final VoidCallback onTap;
  final ValueChanged<List<CalendarEvent>> onTapOverflow;
  final Set<String> activeEventIds;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final inMonth = date.startsWith(monthKey);
    final isToday = date == today;

    // 日曜は赤、土曜は緑。曜日の区別は色でしか出せない。**薄めない**
    // （文字の基準 4.5:1。月の外の日付だけは対象外として薄いまま。web と同じ）
    final numberColor = switch (column) {
      _ when isToday => colors.onPrimary,
      _ when !inMonth => colors.textSub.withValues(alpha: 0.3),
      0 => colors.primaryText,
      6 => colors.green,
      _ => colors.text,
    };

    return GestureDetector(
      onTap: onTap,
      // 予定の無い日も押せるようにする
      behavior: HitTestBehavior.opaque,
      child: DecoratedBox(
        decoration: BoxDecoration(
          // web の `bg-brand-primary-soft`
          color: selected ? colors.primarySoft : null,
          border: Border(
            bottom: BorderSide(color: colors.border.withValues(alpha: 0.4)),
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                width: 21,
                height: 21,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  // **塗り**なので `primary`（上に載るのは `onPrimary`）
                  color: isToday ? colors.primary : null,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${int.parse(date.substring(8))}',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1,
                    fontWeight: isToday ? FontWeight.bold : null,
                    color: numberColor,
                    // 桁で幅が変わると数字が踊る
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
            // **載り切らなかったぶんの件数。** 通過中の線は数えない
            // （その日に何か起きたわけではないので）
            if (overflow.isNotEmpty)
              Positioned(
                top: MonthGrid.moreTop - 2,
                right: -2,
                child: _Dimmed(
                  active: activeEventIds,
                  ids: [for (final e in overflow) e.id],
                  child: GestureDetector(
                    // **文字の大きさぶんだけにしない。** 既定の `deferToChild` と
                    // 余白なしだと、`+2` の細い字を正確に突かないと反応せず、
                    // 外すと下の日付マスが開く
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTapOverflow(overflow),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      child: Text(
                        '+${overflow.length}',
                        style: TextStyle(
                          fontSize: 11,
                          height: 1,
                          color: colors.textSub,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 線 1 本、または丸ポチ 1 つ。
class _Segment extends StatelessWidget {
  const _Segment({
    required this.segment,
    required this.columnWidth,
    required this.week,
    required this.eventCountLabel,
    required this.onTap,
    required this.activeEventIds,
  });

  final GridSegment segment;
  final double columnWidth;

  /// この週の 7 日。**押された位置から日を割り出す**ために持つ。
  final List<String> week;

  final String Function(int count) eventCountLabel;

  final void Function(String date, List<CalendarEvent> events) onTap;
  final Set<String> activeEventIds;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // カテゴリの線の色（チップの `ink` と同じ。知らない slug は副テキストの色）
    final color = CategoryPalette.lineOf(segment.category, colors);
    final top = MonthGrid.overlayTop + MonthGrid.laneHeight * segment.lane;

    // **線はマスの中心から中心へ引く**（日付との対応を崩さない）。週をまたぐ側は
    // 端まで伸ばす
    final left = segment.hasPeriod
        ? (segment.startsHere ? (segment.colStart + 0.5) * columnWidth : 0.0)
        : segment.colStart * columnWidth;
    final right = segment.hasPeriod
        ? (segment.endsHere ? (6 - segment.colEnd + 0.5) * columnWidth : 0.0)
        : (6 - segment.colStart) * columnWidth;

    return Positioned(
      top: top,
      left: left,
      right: right,
      height: MonthGrid.laneHeight,
      child: Semantics(
        button: true,
        // **読み上げに名前を渡す。** 線も丸ポチも図形なので、付けないと
        // 「ボタン」としか読まれない（web も `aria-label` を付けている）
        label: segment.events.length == 1
            ? segment.events.single.title
            : eventCountLabel(segment.events.length),
        child: GestureDetector(
          // 線と丸は座標でしか指せない（重ねてあるので日付からは辿れない）。
          // テストから狙えるよう、代表の予定で名前を付けておく
          key: ValueKey('calendar-segment-${segment.events.first.id}'),
          // **押された日を割り出して渡す。** 線は何日にもまたがるので、代表の
          // 開始日を渡すと「8/24 を押したのに 3/17 と出る」ことになる
          onTapUp: (details) {
            final column = (left + details.localPosition.dx) ~/ columnWidth;
            onTap(
              week[column.clamp(segment.colStart, segment.colEnd)],
              segment.events,
            );
          },
          behavior: HitTestBehavior.opaque,
          child: _Dimmed(
            active: activeEventIds,
            ids: [for (final e in segment.events) e.id],
            child: segment.hasPeriod
                ? _period(color, colors)
                : Center(child: _dot(color)),
          ),
        ),
      ),
    );
  }

  Widget _period(Color color, AppColors colors) => Stack(
    // **端の丸を切らない。** 線の端に半分はみ出して置いてあるので、既定の
    // `Clip.hardEdge` だと半円になる
    clipBehavior: Clip.none,
    alignment: Alignment.center,
    children: [
      // **線は少しだけ薄くする**（web の `opacity: 0.75`）。**薄めているのは、
      // 線が重なった時に下の線を潰さないため**（不透明にすると同じ期間の予定が
      // 1 本に見える）。gyumesy の 0.45 は面に対して 3:1 に届かない（上の doc）
      Positioned(
        left: 0,
        right: 0,
        child: ColoredBox(
          color: color.withValues(alpha: MonthGrid.lineOpacity),
          child: const SizedBox(height: 2),
        ),
      ),
      if (segment.startsHere)
        Positioned(left: -MonthGrid.dot / 2, child: _dot(color)),
      // **終わり方で形を変える。** 終了日が決まっていれば白抜きの丸、
      // 続いていれば三角（まだ先があることを示す）
      if (segment.endsHere && segment.ended)
        Positioned(
          right: -MonthGrid.dot / 2,
          child: Container(
            width: MonthGrid.dot,
            height: MonthGrid.dot,
            decoration: BoxDecoration(
              color: colors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: color),
            ),
          ),
        ),
      if (segment.endsHere && !segment.ended && segment.ongoing)
        Positioned(
          right: -2,
          child: CustomPaint(
            size: const Size(4, 5),
            painter: _ArrowPainter(color: color),
          ),
        ),
    ],
  );

  Widget _dot(Color color) => Container(
    width: MonthGrid.dot,
    height: MonthGrid.dot,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

/// 継続中の終端に出す三角。
class _ArrowPainter extends CustomPainter {
  const _ArrowPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_ArrowPainter oldDelegate) => oldDelegate.color != color;
}
