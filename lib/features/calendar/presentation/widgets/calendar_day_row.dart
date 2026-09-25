import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tonsoku/core/i18n/app_messages.dart';
import 'package:tonsoku/core/i18n/locale_controller.dart';
import 'package:tonsoku/core/theme/app_colors.dart';
import 'package:tonsoku/features/calendar/domain/calendar_window.dart';
import 'package:tonsoku/features/calendar/domain/day_lanes.dart';
import 'package:tonsoku/features/calendar/presentation/widgets/month_grid.dart';
import 'package:tonsoku/shared/models/calendar_event.dart';
import 'package:tonsoku/shared/models/category.dart';
import 'package:tonsoku/shared/models/tag.dart';
import 'package:tonsoku/shared/widgets/label_chip.dart';
import 'package:tonsoku/shared/widgets/source_chip.dart';

/// 予定リストの 1 日ぶん。web の `CoCalendarList` の 1 行（gyumesy-frontend-app の
/// `CalendarDayRow` を写し、色とチップをとん速の web に合わせ直した）。
///
/// gyumesy ではホームの「最近の予定」と共用している。**とん速のアプリのホームに
/// その節を入れる時もこれを使う**（別々に書くと、同じ予定が入口によって違う
/// 見た目になる）。
///
/// ## gyumesy との違い（web の `CoCalendarList.astro` に合わせたもの）
///
/// - 今日の丸は塗りの `primary`、選んだ日の地は `primarySoft`、曜日は日曜
///   `primaryText`・土曜 `green`・平日 `textSub`（**薄めない**。文字の基準 4.5:1）
/// - 縦線の濃さは 0.75（[MonthGrid.lineOpacity] の doc）
/// - **タグは `tags.json` にラベルがあるものだけ出す**（白名簿を持たない。
///   `calendar_event.dart` の注記）
/// - **記事の無い予定の題を押すと、その予定だけを出す**（gyumesy はその日全体を
///   出していた）。web はその題を丸ポチと同じマーク（`data-event-id`）にして
///   いるので、押した予定の詳細が出る
class CalendarDayRow extends ConsumerWidget {
  const CalendarDayRow({
    required this.day,
    required this.categories,
    required this.tags,
    required this.onOpenArticle,
    required this.onTapDay,
    required this.onTapEvent,
    required this.onTapLine,
    this.selected = false,
    this.activeEventIds = const {},
    this.lines = const [],
    this.laneCount = 0,
    this.showMonthHeading = false,
    super.key,
  });

  final CalendarDay day;
  final List<Category> categories;
  final List<Tag> tags;
  final ValueChanged<String> onOpenArticle;
  final VoidCallback onTapDay;

  /// 予定の印（丸ポチ）を押した時。**その予定だけを開く。**
  ///
  /// web は日リストの丸ポチにも詳細を紐づけている
  /// （`CoCalendar.astro` の `bindMarks(document, el => gridsWrap.contains(el))`）。
  /// 行全体を押した時（その日の全部）と押し分けられる。
  final ValueChanged<CalendarEvent> onTapEvent;

  /// 縦線を押した時。**その期間を共有する予定をまとめて渡す**
  /// （web の線は `data-event-ids` を複数持つ）。
  final ValueChanged<List<String>> onTapLine;

  /// いま開いているマークの予定 id。**当てはまらない印を薄くする**
  /// （web の `applyHighlight` は**押したビューの中**を薄くするので、
  /// 日リストで押したら日リストが薄くなる）。
  final Set<String> activeEventIds;

  /// この日を通る縦線。**期間予定は行をまたぐので線でつなぐ**
  /// （web の `CoCalendarList`）。線が無いと単日の予定と区別できない。
  final List<DayListLine> lines;

  /// 溝に確保するレーンの本数。**全日で同じ**（日ごとに変えると線が横へ踊る）。
  final int laneCount;

  /// 月をまたぐ所で月の見出しを出すか。**web の `CoCalendarList` は
  /// `i > 0 && row.day === 1` で出す。** 窓が月をまたぐと日付の数字が
  /// 31 → 1 と戻るので、月が変わったことが分からない。
  final bool showMonthHeading;

  /// いま開いている日か。**押した日を月グリッドと日リストの両方で光らせる**
  /// （web の `bindDaySelect.highlightDay` は `[data-date]` と `[data-day-row]`
  /// の両方を塗る）。片方だけだと、グリッドで押した日がリストのどこなのか
  /// 分からない。
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final t = ref.watch(messagesProvider);

    if (showMonthHeading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            // web の `pt-4 pb-1.5`
            padding: const EdgeInsets.only(top: 16, bottom: 6),
            child: Text(
              t.calendarMonthOnly(day.month),
              style: TextStyle(fontSize: 13, height: 1, color: colors.textSub),
            ),
          ),
          _row(context, colors, t),
        ],
      );
    }
    return _row(context, colors, t);
  }

  Widget _row(BuildContext context, AppColors colors, AppMessages t) {
    return GestureDetector(
      onTap: onTapDay,
      // 予定が無い日も押せるようにする（透明な余白でも当たるように）
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          // web の `bg-brand-primary-soft`
          color: selected ? colors.primarySoft : null,
          border: Border(
            bottom: BorderSide(color: colors.border.withValues(alpha: 0.4)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: t.calendarWeekdayColumnWidth,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 今日は赤の塗りの丸で示す（月グリッドの日セルと同じ扱い）
                    Container(
                      width: 21,
                      height: 21,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: day.isToday ? colors.primary : null,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1,
                          fontWeight: day.isToday ? FontWeight.bold : null,
                          color: day.isToday ? colors.onPrimary : colors.text,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        t.calendarWeekdays[day.weekday],
                        style: TextStyle(
                          fontSize: 12,
                          height: 1,
                          // 日曜は赤、土曜は緑。曜日の区別は色でしか出せない。
                          // **薄めない**（web と同じ。文字の基準 4.5:1）
                          color: switch (day.weekday) {
                            0 => colors.primaryText,
                            6 => colors.green,
                            _ => colors.textSub,
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: day.events.isEmpty
                  // 予定が無い日も行として出す。飛ばすと日付が歯抜けになり、
                  // 「今日の前後」を見ているつもりが数日先まで飛ぶ。
                  // **通過中の線はここでも引く**（行が無いだけで期間は続いている）
                  ? SizedBox(
                      height: 33,
                      child: _Gutter(
                        lines: lines,
                        laneCount: laneCount,
                        rowIndex: 0,
                        height: 33,
                        activeEventIds: activeEventIds,
                        onTapLine: onTapLine,
                        lineLabel: t.calendarEventCount,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final (index, event) in day.events.indexed)
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _Gutter(
                                  lines: lines,
                                  laneCount: laneCount,
                                  rowIndex: index,
                                  activeEventIds: activeEventIds,
                                  onTapLine: onTapLine,
                                  lineLabel: t.calendarEventCount,
                                ),
                                Expanded(
                                  child: _EventRow(
                                    event: event,
                                    categories: categories,
                                    tags: tags,
                                    onOpenArticle: onOpenArticle,
                                    onTapDay: onTapDay,
                                    onTapEvent: onTapEvent,
                                    activeEventIds: activeEventIds,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({
    required this.event,
    required this.categories,
    required this.tags,
    required this.onOpenArticle,
    required this.onTapDay,
    required this.onTapEvent,
    required this.activeEventIds,
  });

  final CalendarEvent event;
  final List<Category> categories;
  final List<Tag> tags;
  final ValueChanged<String> onOpenArticle;

  /// 行の余白を押した時（その日の全部）。
  final VoidCallback onTapDay;

  /// 印を押した時。**その予定だけを開く。** 記事を持たない予定の題もこれ。
  final ValueChanged<CalendarEvent> onTapEvent;

  /// いま開いているマークの予定 id。
  final Set<String> activeEventIds;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final categoryColor = CategoryPalette.lineOf(event.category, colors);
    final slug = event.articleSlug;
    final sourceUrl = SourceChip.safeUrl(event.sourceUrl);
    final tagLabels = {for (final t in tags) t.slug: t.label};

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8, left: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 予定の印。カテゴリ色の丸。**押すとその予定だけを開く**
              // （web も日リストの丸ポチに詳細を紐づけている）
              Semantics(
                button: true,
                label: event.title,
                child: GestureDetector(
                  onTap: () => onTapEvent(event),
                  // **字の大きさぶんだけにしない。** 6px の丸を正確に突かないと
                  // 反応せず、外すと下の行が開く
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 5,
                      right: 6,
                      bottom: 5,
                      left: 2,
                    ),
                    child: AnimatedOpacity(
                      // web の `gy-cal-dim` / `gy-cal-active`
                      opacity:
                          activeEventIds.isEmpty ||
                              activeEventIds.contains(event.id)
                          ? 1
                          : 0.3,
                      duration: const Duration(milliseconds: 120),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: categoryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  // **記事を持たない予定も押せる**（本番の 23 件中 8 件）。押せない
                  // 行が混ざると「反応しない」と受け取られる。行き先が無いので
                  // **その予定の詳細を出す**（web の題の `data-event-id`。
                  // gyumesy はその日全体を出していた）
                  onTap: slug == null
                      ? () => onTapEvent(event)
                      : () => onOpenArticle(slug),
                  child: Text(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.3,
                      fontWeight: FontWeight.bold,
                      color: colors.text,
                      // **常時下線を引く。** 行内テキストなので、下線が無いと
                      // 押せることが伝わらない
                      decoration: TextDecoration.underline,
                      decorationColor: colors.text,
                    ),
                  ),
                ),
              ),
              // 期間は予定名と同じ行に置く（離すと何日までか読めない）
              if (event.hasPeriod) ...[
                const SizedBox(width: 6),
                Text(
                  event.period,
                  style: TextStyle(
                    fontSize: 12,
                    // web は `text-brand-text-sub`（薄めない。文字の基準 4.5:1）
                    color: colors.textSub,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          // タグは幅に収まらなければ切る（折り返して行を増やさない）。
          // **横に送れるようにはしない**（web は `overflow-x-auto`）。日リストは
          // 横に払うと月を送るので、ここが横スクロールを取ると、タグの上から
          // 払った時だけ月が送れなくなる（gyumesy と同じ作り）
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: Row(
              children: [
                // **カテゴリのチップだけ色を持つ**（記事カードと同じ組み）。
                // web の日リストは地を中立色にして文字だけ `ink` で塗っているが、
                // それは slug がビルド時まで分からずクラス名にできないための
                // 作りで、web 自身のコメントも「記事カードと同じ組み」と言っている。
                // アプリは記事カードと同じ [LabelChip.category] を使う
                LabelChip.category(
                  label:
                      categories
                          .where((c) => c.slug == event.category)
                          .map((c) => c.label)
                          .firstOrNull ??
                      event.category,
                  slug: event.category,
                ),
                for (final tag in event.tags)
                  if (tagLabels[tag] case final label?) ...[
                    const SizedBox(width: 6),
                    LabelChip.tag(label: label),
                  ],
                if (sourceUrl != null) ...[
                  const SizedBox(width: 6),
                  SourceChip(url: sourceUrl),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 予定名の左に置く溝。**期間予定の縦線をここに引く。**
///
/// 行は「開始日」しか作らないので、線が無いと期間予定が単日と区別できない
/// （web の `CoCalendarList` と同じ作り）。
class _Gutter extends StatelessWidget {
  const _Gutter({
    required this.lines,
    required this.laneCount,
    required this.rowIndex,
    required this.activeEventIds,
    required this.onTapLine,
    required this.lineLabel,
    this.height,
  });

  final List<DayListLine> lines;
  final int laneCount;

  /// いま開いているマークの予定 id。**線も薄くなる側に入る**
  /// （web の `applyHighlight` は `[data-event-id], [data-event-ids]` を
  /// 一括で拾うので、丸ポチだけでなく線も落ちる）。
  final Set<String> activeEventIds;

  /// 線を押した時。**web の線は `data-event-ids` を持つ `<button>`**
  /// （`CoCalendarList.astro`）で、押すとその期間の予定が出る。
  final ValueChanged<List<String>> onTapLine;

  /// 線の読み上げ名（`3件の予定`）。**図形なので付けないと「ボタン」としか
  /// 読まれない**（web も `aria-label` を付けている）。
  final String Function(int count) lineLabel;

  /// その日の何行目か。**線の引き方が行で変わる**（始まりは丸ポチの下から、
  /// 終わりは丸ポチまで）。
  final int rowIndex;

  /// 予定の無い日の高さ。行が無いので `IntrinsicHeight` が効かない。
  final double? height;

  @override
  Widget build(BuildContext context) {
    // **線を出さない時は幅ごと畳む。** 空けたままだと予定名が右へ押し出される
    if (laneCount == 0) return const SizedBox.shrink();
    final colors = context.colors;

    return SizedBox(
      width: laneCount * laneWidth + connectorWidth,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final line in lines)
            if (line.spanInRow(rowIndex) != LineSpan.none) _line(line, colors),
          for (final line in lines)
            if (line.pos == DayLinePos.end && rowIndex == 0)
              _endMark(line, colors),
          // **当たり判定はレーン幅ぶん取る。** 線は 2px しかないので、
          // 見た目のままだと指で狙えない（web も `--lane-w` ぶん確保している）
          for (final line in lines)
            if (line.spanInRow(rowIndex) != LineSpan.none)
              Positioned(
                left: line.lane * laneWidth,
                top: 0,
                bottom: 0,
                width: laneWidth,
                child: Semantics(
                  button: true,
                  // **読み上げに名前を渡す。** 線は図形なので、付けないと
                  // 「ボタン」としか読まれない（web も `aria-label` を付けている）
                  label: lineLabel(line.eventIds.length),
                  child: GestureDetector(
                    onTap: () => onTapLine(line.eventIds),
                    behavior: HitTestBehavior.opaque,
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  /// 開いている予定以外は薄くする（web の `gy-cal-dim` は
  /// `[data-event-id], [data-event-ids]` を一括で拾うので、**線も落ちる側**）。
  double _opacityOf(DayListLine line) =>
      activeEventIds.isEmpty || line.eventIds.any(activeEventIds.contains)
      ? 1
      : 0.3;

  Widget _line(DayListLine line, AppColors colors) {
    final span = line.spanInRow(rowIndex);
    final color = CategoryPalette.lineOf(line.category, colors);
    return Positioned(
      left: line.lane * laneWidth + laneWidth / 2 - 1,
      // web の `SPAN_STYLE`
      top: span == LineSpan.below ? 12 : -1,
      bottom: span == LineSpan.above ? null : -1,
      height: span == LineSpan.above ? 12 : null,
      width: 2,
      child: AnimatedOpacity(
        opacity: _opacityOf(line),
        duration: const Duration(milliseconds: 120),
        // web の `opacity-75`（[MonthGrid.lineOpacity] と同じ値・同じ理由）
        child: ColoredBox(
          color: color.withValues(alpha: MonthGrid.lineOpacity),
        ),
      ),
    );
  }

  /// 期間の終わりの印。**2 通りある**（web の `CoCalendarList`）。
  ///
  /// - 終わりが決まっている → **白抜きの丸**（終わった）
  /// - 継続中 → **下向きの三角**（今日で切れているだけで、まだ続く）
  ///
  /// **三角を落とすと「終わった」のか「まだ続く」のか読めない。** 隣の行に
  /// 終了日を持つ予定があれば白抜きの丸が出ているので、印が無いほうが
  /// 「まだ続く」だとは読めず、描画が途切れたように見える。
  Widget _endMark(DayListLine line, AppColors colors) {
    final color = CategoryPalette.lineOf(line.category, colors);
    return Positioned(
      left: line.lane * laneWidth + laneWidth / 2 - listDot / 2,
      top: 12 - listDot / 2,
      child: AnimatedOpacity(
        opacity: _opacityOf(line),
        duration: const Duration(milliseconds: 120),
        child: line.ongoing
            ? CustomPaint(
                size: const Size(listDot, listDot),
                painter: _OngoingTip(color),
              )
            : Container(
                width: listDot,
                height: listDot,
                decoration: BoxDecoration(
                  color: colors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: color),
                ),
              ),
      ),
    );
  }
}

/// 継続中の線の終端。**下向きの三角**（web の
/// `clip-path: polygon(0 0, 100% 0, 50% 100%)`）。
///
/// **白抜きの丸と描き分ける。** 丸は「終わった」、三角は「今日で切れて
/// いるだけで、まだ続く」。
class _OngoingTip extends CustomPainter {
  const _OngoingTip(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_OngoingTip oldDelegate) => oldDelegate.color != color;
}
