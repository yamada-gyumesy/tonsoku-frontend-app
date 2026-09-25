import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonsoku/core/i18n/app_locale.dart';
import 'package:tonsoku/core/theme/app_theme.dart';
import 'package:tonsoku/features/calendar/domain/calendar_grid.dart';
import 'package:tonsoku/features/calendar/presentation/widgets/month_grid.dart';
import 'package:tonsoku/shared/models/calendar_event.dart';

/// 月グリッドの描画。**日付と線の対応が崩れると、予定を 1 日ずれて読ませる。**
void main() {
  const today = '2026-08-24';

  CalendarEvent event({
    required String id,
    required String start,
    String? end,
    bool ongoing = false,
  }) => CalendarEvent(
    id: id,
    title: id,
    category: 'menu',
    startDate: start,
    endDate: end,
    ongoing: ongoing,
  );

  Future<
    ({
      List<String> days,
      List<({String date, List<CalendarEvent> events})> events,
    })
  >
  pump(
    WidgetTester tester, {
    required List<CalendarEvent> events,
    String? lineMode,
  }) async {
    final days = <String>[];
    final tapped = <({String date, List<CalendarEvent> events})>[];

    tester.view.physicalSize = const Size(390 * 3, 900 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(AppLocale.ja),
        home: Scaffold(
          body: SingleChildScrollView(
            child: MonthGrid(
              weeks: buildMonthGrid(events, '2026-08', lineMode, today),
              monthKey: '2026-08',
              today: today,
              weekdays: const ['日', '月', '火', '水', '木', '金', '土'],
              eventCountLabel: (n) => '$n件の予定',
              onTapDay: days.add,
              onTapEvents: (date, events) =>
                  tapped.add((date: date, events: events)),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return (days: days, events: tapped);
  }

  testWidgets('月の全日と、前後の月のはみ出しぶんを出す', (tester) async {
    await pump(tester, events: []);

    // 2026-08-01 は土曜なので、最初の週は 7/26 から。7/26 と 8/26 で 2 つ出る
    expect(find.text('26'), findsNWidgets(2));
    expect(find.text('24'), findsOneWidget);
    // 最後の週は 9/5 まで
    expect(find.text('5'), findsNWidgets(2));
  });

  testWidgets('日を押すとその日付が返る', (tester) async {
    final result = await pump(tester, events: []);

    await tester.tap(find.text('24'));
    await tester.pump();

    expect(result.days, [today]);
  });

  testWidgets('線を押すと、その線がまとめている予定が全部返る', (tester) async {
    // 同じ期間の予定は 1 本の線を共有しているので、押した先で選ばせる
    final result = await pump(
      tester,
      lineMode: 'menu',
      events: [
        event(id: 'a', start: '2026-08-10', end: '2026-08-14'),
        event(id: 'b', start: '2026-08-10', end: '2026-08-14'),
      ],
    );

    // 線は 8/10（月）から 8/14（金）
    await tester.tap(find.byKey(const ValueKey('calendar-segment-a')));
    await tester.pump();

    expect(result.events, hasLength(1));
    expect(result.events.single.events.map((e) => e.id), ['a', 'b']);
    // **押されたマスの日**が返る（線の代表の開始日ではない）
    expect(result.events.single.date, '2026-08-12');
  });

  testWidgets('載り切らないぶんは +N で出す', (tester) async {
    final result = await pump(
      tester,
      events: [
        for (var i = 0; i < maxLanes + 3; i++)
          event(id: 'e$i', start: '2026-08-12'),
      ],
    );

    expect(find.text('+3'), findsOneWidget);

    await tester.tap(find.text('+3'));
    await tester.pump();

    expect(result.events.single.events, hasLength(3));
    expect(result.events.single.date, '2026-08-12');
  });

  testWidgets('マスの高さは予定数で変わらない', (tester) async {
    // 変わると月送りのたびにグリッドが伸縮して、どの日を見ていたか分からなくなる
    await pump(tester, events: []);
    final empty = tester.getSize(find.byType(MonthGrid)).height;

    await pump(
      tester,
      events: [
        for (var i = 0; i < maxLanes + 5; i++)
          event(id: 'e$i', start: '2026-08-12'),
      ],
    );
    final crowded = tester.getSize(find.byType(MonthGrid)).height;

    expect(crowded, empty);
  });
}
