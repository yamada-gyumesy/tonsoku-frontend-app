import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tonsoku/core/storage/preferences_provider.dart';
import 'package:tonsoku/core/i18n/app_locale.dart';
import 'package:tonsoku/core/theme/app_theme.dart';
import 'package:tonsoku/features/calendar/data/calendar_repository.dart';
import 'package:tonsoku/features/calendar/domain/day_lanes.dart';
import 'package:tonsoku/features/calendar/presentation/calendar_page.dart';
import 'package:tonsoku/features/calendar/presentation/widgets/calendar_day_row.dart';
import 'package:tonsoku/features/home/data/article_providers.dart';
import 'package:tonsoku/shared/models/article_meta.dart';
import 'package:tonsoku/shared/models/calendar_event.dart';
import 'package:tonsoku/shared/models/category.dart';
import 'package:tonsoku/shared/models/tag.dart';

/// 月グリッドのマーク（線・丸ポチ・`+N`）を押した時の挙動。
///
/// **web に合わせる。** web は `calendar-popover.ts` の `bindMarks` で
/// ポップオーバーを出すだけで、**記事へは飛ばさない**（中の題を押して初めて飛ぶ）。
void main() {
  final today = DateTime.now();
  String iso(int day) =>
      '${today.year.toString().padLeft(4, '0')}-'
      '${today.month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  // **1 件だけ・記事あり。** 直行してしまう条件をそのまま作る
  final solo = CalendarEvent(
    id: 'solo',
    title: '記事のある予定',
    category: 'menu',
    startDate: iso(10),
    articleSlug: 'abc123',
  );
  final other = CalendarEvent(
    id: 'other',
    title: '別の予定',
    category: 'menu',
    startDate: iso(18),
  );
  // **期間を持つ予定。** 日リストの縦線はこれにだけ引かれる
  final spanning = CalendarEvent(
    id: 'spanning',
    title: '期間のある予定',
    category: 'menu',
    startDate: iso(12),
    endDate: iso(16),
  );

  Future<List<String>> pump(WidgetTester tester) async {
    final opened = <String>[];
    SharedPreferences.setMockInitialValues({'app_locale': 'ja'});
    final store = await SharedPreferences.getInstance();

    tester.view.physicalSize = const Size(390 * 3, 1400 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(store),
          calendarProvider.overrideWith(
            (ref) =>
                Stream.value(CalendarPayload(events: [solo, other, spanning])),
          ),
          categoriesProvider.overrideWith(
            (ref) =>
                Stream.value(const [Category(slug: 'menu', label: 'メニュー')]),
          ),
          tagsProvider.overrideWith((ref) => Stream.value(const <Tag>[])),
          // 記事の一覧は届いていない扱い（リンクを外さない。取得を組まない）
          articleIndexProvider.overrideWith(
            (ref) => const Stream<List<ArticleMeta>>.empty(),
          ),
          feedProvider.overrideWith(
            (ref) => const Stream<List<ArticleMeta>>.empty(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(AppLocale.ja),
          home: CalendarPage(onOpenArticle: opened.add),
        ),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    return opened;
  }

  testWidgets('丸ポチを押しても記事へ直行せず、一覧を出す', (tester) async {
    final opened = await pump(tester);

    await tester.tap(find.byKey(const ValueKey('calendar-segment-solo')));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // **記事へは飛ばない**（web は中の題を押して初めて飛ぶ）
    expect(opened, isEmpty);
    // 一覧が出ていて、そこから記事へ行ける
    expect(find.text('記事のある予定'), findsWidgets);
  });

  testWidgets('押したマーク以外は薄くなる', (tester) async {
    await pump(tester);

    double opacityOf(String id) => tester
        .widget<AnimatedOpacity>(
          find
              .descendant(
                of: find.byKey(ValueKey('calendar-segment-$id')),
                matching: find.byType(AnimatedOpacity),
              )
              .first,
        )
        .opacity;

    // 押す前はどちらも通常
    expect(opacityOf('solo'), 1);
    expect(opacityOf('other'), 1);

    await tester.tap(find.byKey(const ValueKey('calendar-segment-solo')));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // **押したものは残り、他は落ちる**（web の `gy-cal-dim` / `gy-cal-active`）
    expect(opacityOf('solo'), 1);
    expect(opacityOf('other'), 0.3);

    // **薄くするのは押したビューの中だけ。** web の `applyHighlight` は
    // `closest('[data-grid], [data-calendar-list]')` で押した側だけを落とす。
    // 月グリッドで押したのに日リストまで薄くなってはいけない
    final listDots = tester
        .widgetList<AnimatedOpacity>(
          find.descendant(
            of: find.byType(CalendarDayRow),
            matching: find.byType(AnimatedOpacity),
          ),
        )
        .map((w) => w.opacity)
        .toSet();
    expect(listDots, everyElement(1.0));
  });

  /// **カテゴリを選ぶと日リストに縦線が出る**（web の
  /// `<CoCalendarSection category={id} />` と同じ）。行は開始日しか作らないので、
  /// 線が無いと期間予定が単日と区別できない。
  testWidgets('カテゴリを選ぶと日リストに期間の線が出る', (tester) async {
    await pump(tester);

    Iterable<double> gutterWidths() => tester
        .widgetList<CalendarDayRow>(find.byType(CalendarDayRow))
        .map((r) => r.laneCount * 1.0);

    // 「すべて」では線なし（web も既定は線なし）
    expect(gutterWidths(), everyElement(0.0));

    Future<void> pressChip(String label) async {
      final target = find.descendant(
        of: find.byType(CalendarToolbar),
        matching: find.text(label),
      );
      expect(target, findsOneWidget, reason: 'チップ「$label」が出ていない');
      await tester.tap(target);
      await tester.pump(const Duration(milliseconds: 300));
    }

    await pressChip('メニュー');

    // **期間予定にレーンが 1 本割り当たる**
    expect(gutterWidths(), everyElement(1.0));

    // 始まりの日・通過中・終わりの日で線の位置が変わる
    DayListLine lineOn(String date) => tester
        .widgetList<CalendarDayRow>(find.byType(CalendarDayRow))
        .firstWhere((r) => r.day.date == date)
        .lines
        .single;

    expect(lineOn(iso(12)).pos, DayLinePos.start);
    expect(lineOn(iso(14)).pos, DayLinePos.middle);
    expect(lineOn(iso(16)).pos, DayLinePos.end);
  });

  /// **月が変わる所に見出しを出す**（web の `i > 0 && row.day === 1`）。
  /// 日付の数字が 31 → 1 と戻るだけでは、月が変わったと分からない。
  testWidgets('月をまたぐ所に月の見出しを出す', (tester) async {
    await pump(tester);

    final rows = tester.widgetList<CalendarDayRow>(find.byType(CalendarDayRow));
    // 月表示なので 1 日は先頭。**先頭には出さない**（web の `i > 0`）
    expect(rows.first.day.day, 1);
    expect(rows.first.showMonthHeading, isFalse);
    expect(rows.where((r) => r.showMonthHeading), isEmpty);
  });

  /// **日を押した時は、押した日を月グリッドと日リストの両方で光らせる**
  /// （web の `bindDaySelect.highlightDay` は `[data-date]` と `[data-day-row]`
  /// の両方を塗る）。マークを押した時は光らせない（そちらはマークを強調する）。
  testWidgets('日リストの行を押すと、その日が光る', (tester) async {
    await pump(tester);

    bool selectedOf(String date) => tester
        .widgetList<CalendarDayRow>(find.byType(CalendarDayRow))
        .firstWhere((r) => r.day.date == date)
        .selected;

    expect(selectedOf(iso(10)), isFalse);

    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is CalendarDayRow && w.day.date == iso(10),
      ),
      warnIfMissed: false,
    );
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(selectedOf(iso(10)), isTrue);
    expect(selectedOf(iso(18)), isFalse);
  });

  /// **光らせた日は、見ているものが変わったら落とす。**
  ///
  /// web は月送り・カテゴリ切替のたびに `popover.hide()` を呼び、その `onHide` で
  /// 消している。残ると「別の月を見ているのに前の月で押した日が光ったまま」になる。
  testWidgets('マークを押すと、光っていた日の強調は落ちる', (tester) async {
    await pump(tester);

    bool selectedOf(String date) => tester
        .widgetList<CalendarDayRow>(find.byType(CalendarDayRow))
        .firstWhere((r) => r.day.date == date)
        .selected;

    // まず日を押して光らせる
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is CalendarDayRow && w.day.date == iso(10),
      ),
      warnIfMissed: false,
    );
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(selectedOf(iso(10)), isTrue);

    // シートを閉じてからマークを押す
    Navigator.of(tester.element(find.byType(CalendarPage))).pop();
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.tap(find.byKey(const ValueKey('calendar-segment-other')));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // **日の強調は落ちている**（web の `popover.onRender`）
    expect(selectedOf(iso(10)), isFalse);
  });
}
