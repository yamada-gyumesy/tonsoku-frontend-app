import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tonsoku/core/i18n/app_locale.dart';
import 'package:tonsoku/core/router/app_router.dart';
import 'package:tonsoku/core/storage/preferences_provider.dart';
import 'package:tonsoku/core/theme/app_theme.dart';
import 'package:tonsoku/features/article/presentation/article_page.dart';
import 'package:tonsoku/features/calendar/data/calendar_repository.dart';
import 'package:tonsoku/features/calendar/presentation/calendar_page.dart';
import 'package:tonsoku/features/calendar/presentation/widgets/calendar_day_row.dart';
import 'package:tonsoku/features/calendar/presentation/widgets/calendar_section.dart';
import 'package:tonsoku/features/home/data/article_providers.dart';
import 'package:tonsoku/shared/models/article.dart';
import 'package:tonsoku/shared/models/article_meta.dart';
import 'package:tonsoku/shared/models/calendar_event.dart';
import 'package:tonsoku/shared/models/category.dart';
import 'package:tonsoku/shared/models/tag.dart';

/// 記事詳細の「この記事の前後の予定」（web の `CoCalendarSection`）。
///
/// - 記事の掲載日の前後 2 日を出す
/// - 窓に予定が無ければ節ごと出さない
/// - 「カレンダーをみる」は記事と同じタブに、記事の月のカレンダーを積む
void main() {
  // **月は今日から数える。** カレンダーの月の範囲は「今月から 3 ヶ月先まで」
  // なので、固定の日付だと日が経つと範囲の外に出る
  final now = DateTime.now().toUtc().add(const Duration(hours: 9));
  final next = DateTime.utc(now.year, now.month + 1);
  String two(int v) => v.toString().padLeft(2, '0');
  final nextMonth = '${next.year}-${two(next.month)}';
  String nextDay(int day) => '$nextMonth-${two(day)}';

  // 記事は翌月 10 日の JST 正午に出た扱い。窓は 8〜12 日
  final createdAt = DateTime.utc(next.year, next.month, 10, 3);

  final inWindow = CalendarEvent(
    id: 'in-window',
    title: '窓の中の予定',
    category: 'menu',
    startDate: nextDay(9),
  );
  final outside = CalendarEvent(
    id: 'outside',
    title: '窓の外の予定',
    category: 'menu',
    startDate: nextDay(20),
  );
  // **窓を通る期間の予定。** 行は窓の外（開始日）にしか無いが、日タップで出る
  final passing = CalendarEvent(
    id: 'passing',
    title: '窓を通る予定',
    category: 'campaign',
    startDate: nextDay(1),
    endDate: nextDay(15),
  );

  const categories = [
    Category(slug: 'menu', label: 'メニュー'),
    Category(slug: 'campaign', label: 'キャンペーン'),
  ];

  Future<void> pumpApp(
    WidgetTester tester, {
    required List<CalendarEvent> events,
    required GoRouter router,
  }) async {
    SharedPreferences.setMockInitialValues({'app_locale': 'ja'});
    final store = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(390 * 3, 1400 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final article = Article(
      meta: ArticleMeta(slug: 'abc123', title: '記事の題', createdAt: createdAt),
      content: '本文',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(store),
          articleProvider.overrideWith((ref, slug) => Stream.value(article)),
          calendarProvider.overrideWith(
            (ref) => Stream.value(CalendarPayload(events: events)),
          ),
          categoriesProvider.overrideWith((ref) => Stream.value(categories)),
          tagsProvider.overrideWith((ref) => Stream.value(const <Tag>[])),
          // 記事の一覧は届いていない扱い（リンクを外さない）
          articleIndexProvider.overrideWith(
            (ref) => const Stream<List<ArticleMeta>>.empty(),
          ),
          feedProvider.overrideWith(
            (ref) => const Stream<List<ArticleMeta>>.empty(),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(AppLocale.ja),
          routerConfig: router,
        ),
      ),
    );
    await settle(tester);
  }

  /// クーポンのタブの中に記事とカレンダーを積む（アプリと同じルート）。
  GoRouter couponRouter() {
    final router = GoRouter(
      initialLocation: AppRoutes.coupon,
      routes: [
        GoRoute(
          path: AppRoutes.coupon,
          builder: (context, state) => const Text('クーポン'),
          routes: [
            articleRoute(AppRoutes.coupon),
            calendarRoute(AppRoutes.coupon),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    return router;
  }

  Future<void> openArticle(WidgetTester tester, GoRouter router) async {
    router.push('${AppRoutes.coupon}/articles/abc123');
    await settle(tester);
    // 節は本文の最後にあるので、そこまで送る（ListView は画面外を組まない）
    await tester.scrollUntilVisible(
      find.text('スケジュール'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await settle(tester);
  }

  testWidgets('記事の掲載日の前後 2 日を出す', (tester) async {
    final router = couponRouter();
    await pumpApp(tester, events: [inWindow, outside, passing], router: router);
    await openArticle(tester, router);

    expect(find.text('スケジュール'), findsOneWidget);
    final rows = tester
        .widgetList<CalendarDayRow>(find.byType(CalendarDayRow))
        .toList();
    expect(
      [for (final r in rows) r.day.date],
      [
        for (final d in [8, 9, 10, 11, 12]) nextDay(d),
      ],
    );
    expect(find.text('窓の中の予定'), findsOneWidget);
    expect(find.text('窓の外の予定'), findsNothing);
  });

  testWidgets('日付を押すと、その日にかかる予定をシートで出す', (tester) async {
    final router = couponRouter();
    await pumpApp(tester, events: [inWindow, passing], router: router);
    await openArticle(tester, router);

    // 窓を通る予定は行には出ない（開始日が窓の外）
    expect(find.text('窓を通る予定'), findsNothing);
    final row = find.byWidgetPredicate(
      (w) => w is CalendarDayRow && w.day.date == nextDay(11),
    );
    await tester.ensureVisible(row);
    await tester.tap(row);
    await settle(tester);

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('窓を通る予定'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('窓に予定が無ければ節ごと出さない', (tester) async {
    final router = couponRouter();
    // **予定そのものはある**（窓の外に）。件数で判定すると見出しだけが出る
    await pumpApp(tester, events: [outside], router: router);
    router.push('${AppRoutes.coupon}/articles/abc123');
    await settle(tester);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
    await settle(tester);

    expect(find.byType(ArticlePage), findsOneWidget);
    expect(find.text('スケジュール'), findsNothing);
    expect(find.byType(CalendarDayRow), findsNothing);
  });

  testWidgets('「カレンダーをみる」は同じタブに記事の月のカレンダーを積む', (tester) async {
    final router = couponRouter();
    await pumpApp(tester, events: [inWindow, passing], router: router);
    await openArticle(tester, router);

    await tester.tap(find.text('カレンダーをみる'));
    await settle(tester);

    expect(
      GoRouterState.of(
        tester.element(find.byType(CalendarPage)),
      ).uri.toString(),
      '/coupon/calendar?month=$nextMonth',
    );
    expect(find.byType(CalendarPage), findsOneWidget);
    // 今月ではなく記事の月が開く
    expect(find.text('${next.year}年${next.month}月'), findsOneWidget);
  });

  group('カレンダーの月の指定', () {
    test('月はクエリで渡す', () {
      expect(
        AppRoutes.calendar(AppRoutes.map, month: '2026-10'),
        '/map/calendar?month=2026-10',
      );
      expect(
        AppRoutes.calendar(AppRoutes.coupon, category: 'campaign'),
        '/coupon/calendar?category=campaign',
      );
    });

    /// **外から URL で来る経路は何でも書ける。** web も範囲に無い月は無視して
    /// 既定の月で開く（端へ寄せない）
    for (final bad in ['1999-01', '2026-9', 'abc']) {
      testWidgets('範囲に無い・形の崩れた月（$bad）は今月で開く', (tester) async {
        final router = couponRouter();
        await pumpApp(tester, events: [inWindow], router: router);
        router.push(AppRoutes.calendar(AppRoutes.coupon, month: bad));
        await settle(tester);

        expect(find.text('${now.year}年${now.month}月'), findsOneWidget);
      });
    }
  });

  testWidgets('節だけを組んでも、窓の外の予定しか無ければ何も出さない', (tester) async {
    SharedPreferences.setMockInitialValues({'app_locale': 'ja'});
    final store = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(store)],
        child: MaterialApp(
          theme: AppTheme.light(AppLocale.ja),
          home: Scaffold(
            body: CalendarSection(
              events: [outside],
              center: nextDay(10),
              heading: 'スケジュール',
              onOpenArticle: (_) {},
              onOpenCalendar: (_) {},
              padding: const EdgeInsets.only(top: 72),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('スケジュール'), findsNothing);
    // **余白ごと出さない**（出さない時に空白だけが残らない）
    expect(tester.getSize(find.byType(CalendarSection)).height, 0);
  });
}

/// 配信の Stream とルートの遷移を流し切る（`pumpAndSettle` は読み込みの輪が
/// 回り続けると終わらないので、決まった回数だけ進める）。
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
