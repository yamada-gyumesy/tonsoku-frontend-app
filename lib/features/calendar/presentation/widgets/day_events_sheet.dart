import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tonsoku/core/i18n/locale_controller.dart';
import 'package:tonsoku/core/theme/app_colors.dart';
import 'package:tonsoku/core/utils/article_date.dart';
import 'package:tonsoku/features/calendar/domain/calendar_window.dart';
import 'package:tonsoku/shared/models/calendar_event.dart';
import 'package:tonsoku/shared/models/category.dart';
import 'package:tonsoku/shared/models/tag.dart';
import 'package:tonsoku/shared/widgets/label_chip.dart';
import 'package:tonsoku/shared/widgets/source_chip.dart';

/// 日付をタップした時に、その日にかかっている予定をまとめて出す
/// （gyumesy-frontend-app の `showDayEventsSheet` を写した）。
///
/// **開始日が同じものだけではなく、期間の途中の予定も出す。** 「今日は何が
/// 売っているか」を見るのが目的なので、開始日だけだと昨日始まったキャンペーンが
/// 出てこない（一覧の行には開始日の予定しか並ばないので、ここで補う）。
///
/// web は指した位置にポップオーバーを出すが、**アプリはボトムシートにする**
/// （gyumesy と同じ）。片手で持った時に指が届き、下へ払って閉じられる。指した
/// 位置に浮かせると、画面下端の予定を開いた時にシートが画面外へはみ出す。
///
/// ## gyumesy との違い
///
/// - **花吹雪を鳴らさない**（`CalendarPage` の doc）
/// - タグは `tags.json` にラベルがあるものだけ（白名簿を持たない）
/// - 見出しの日付は `formatDateOnly` ＋ 曜日（gyumesy の `formatCalendarDate` は
///   とん速に無い。曜日は画面と同じ `calendarWeekdays` から引く）
Future<void> showDayEventsSheet(
  BuildContext context, {
  required String date,
  required String today,
  required List<CalendarEvent> events,
  required List<Category> categories,
  required List<Tag> tags,
  required ValueChanged<String> onOpenArticle,
}) {
  final dayEvents = eventsOnDay(events, date, today);
  // **1 件も無い日はシートを出さない。** 空のシートが出ると、押し損ねたのか
  // 予定が無いのか分からない（web も 0 件なら開かない）
  if (dayEvents.isEmpty) return Future.value();

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: context.colors.surface,
    builder: (context) => _DayEventsSheet(
      date: date,
      events: dayEvents,
      categories: categories,
      tags: tags,
      onOpenArticle: onOpenArticle,
    ),
  );
}

class _DayEventsSheet extends ConsumerWidget {
  const _DayEventsSheet({
    required this.date,
    required this.events,
    required this.categories,
    required this.tags,
    required this.onOpenArticle,
  });

  final String date;
  final List<CalendarEvent> events;
  final List<Category> categories;
  final List<Tag> tags;
  final ValueChanged<String> onOpenArticle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final t = ref.watch(messagesProvider);
    final locale = ref.watch(localeControllerProvider);
    final parts = date.split('-').map(int.parse).toList();
    // **UTC の 0 時で作る。** `formatDateOnly` は JST に寄せて出すので、
    // 0 時 UTC は同じ日の 9 時になり、日付は動かない
    final day = DateTime.utc(parts[0], parts[1], parts[2]);

    return SafeArea(
      child: ConstrainedBox(
        // 画面いっぱいには広げない。後ろの一覧が見えていたほうが、どの日を
        // 開いているのか分かる
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              // シートの見出しはタップした日。**個々の予定の日付ではない**ので、
              // 予定側にもそれぞれの期間を出す（`_EventBlock`）
              child: Text(
                '${formatDateOnly(day, locale)}'
                '(${t.calendarWeekdays[day.weekday % 7]})',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: colors.text,
                ),
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: events.length,
                separatorBuilder: (_, _) =>
                    Divider(height: 24, color: colors.border),
                itemBuilder: (context, i) => _EventBlock(
                  event: events[i],
                  categories: categories,
                  tags: tags,
                  onOpenArticle: onOpenArticle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventBlock extends StatelessWidget {
  const _EventBlock({
    required this.event,
    required this.categories,
    required this.tags,
    required this.onOpenArticle,
  });

  final CalendarEvent event;
  final List<Category> categories;
  final List<Tag> tags;
  final ValueChanged<String> onOpenArticle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final slug = event.articleSlug;
    final sourceUrl = SourceChip.safeUrl(event.sourceUrl);
    final tagLabels = {for (final t in tags) t.slug: t.label};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // **予定ごとに必ず日付を出す。** 終了日を持たない予定で省くと、見出しの
        // 日付がその予定の開始日だと誤って伝わる（gyumesy の実測: 前に発売した
        // メニューが今日から始まったように見える）。web も予定ごとに出す
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            event.period,
            style: TextStyle(
              fontSize: 11,
              color: colors.textSub,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        GestureDetector(
          onTap: slug == null
              ? null
              : () {
                  Navigator.of(context).pop();
                  onOpenArticle(slug);
                },
          child: Text(
            event.title,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.bold,
              color: colors.text,
              // **シートでは記事のある予定だけ下線を引く。** 一覧の行と違って
              // 押した先（その日の詳細）が既に開いているので、記事の無い予定に
              // 下線を引くと押せると誤解させる
              decoration: slug == null ? null : TextDecoration.underline,
              decorationColor: colors.text,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // web のポップオーバーはカテゴリの色を 12% 敷いた地。アプリは
            // 焼いた `tint`（8%）を持つ [LabelChip.category] で揃える
            // （文字と対で実測してある組。`LabelChip` の doc）
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
              if (tagLabels[tag] case final label?) LabelChip.tag(label: label),
            if (sourceUrl != null) SourceChip(url: sourceUrl),
          ],
        ),
      ],
    );
  }
}
