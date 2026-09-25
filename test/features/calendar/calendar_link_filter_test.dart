import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tonsoku/core/i18n/app_locale.dart';
import 'package:tonsoku/core/router/app_router.dart';
import 'package:tonsoku/core/storage/preferences_provider.dart';
import 'package:tonsoku/core/theme/app_theme.dart';
import 'package:tonsoku/features/calendar/data/calendar_repository.dart';
import 'package:tonsoku/features/calendar/presentation/calendar_page.dart';
import 'package:tonsoku/features/coupon/presentation/coupon_page.dart';
import 'package:tonsoku/features/home/data/article_providers.dart';
import 'package:tonsoku/features/home/presentation/article_list_page.dart';
import 'package:tonsoku/shared/models/article_meta.dart';
import 'package:tonsoku/shared/models/calendar_event.dart';
import 'package:tonsoku/shared/models/category.dart';
import 'package:tonsoku/shared/models/tag.dart';

/// 導線が運んでくるカテゴリの絞り込みを、カレンダー画面が受け取ること
/// （gyumesy-frontend-app の同名のテストを写し、とん速の渡し方に合わせ直した）。
///
/// **クーポンの「カレンダーをみる」は `campaign` で絞った状態へ飛ばす**（web は
/// `/calendar/#category=campaign`）。アプリは `?category=` のクエリで渡し、
/// ルート（`calendarRoute`）が `CalendarPage.initialCategory` へ写す。
///
/// **gyumesy との違い:** あちらはカレンダーがタブで、同じ画面に何度も導線が
/// 届く（2 回目の導線・タブの再タップ・URL の書き戻し）ことを確かめていた。
/// とん速は開くたびに画面を積むので、その 3 つは起きない。
void main() {
  final today = DateTime.now();
  String iso(int day) =>
      '${today.year.toString().padLeft(4, '0')}-'
      '${today.month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  final events = [
    CalendarEvent(
      id: 'menu-1',
      title: '新メニューの予定',
      category: 'menu',
      startDate: iso(10),
    ),
    CalendarEvent(
      id: 'campaign-1',
      title: 'キャンペーンの予定',
      category: 'campaign',
      startDate: iso(11),
    ),
  ];

  const categories = [
    Category(slug: 'menu', label: 'メニュー'),
    Category(slug: 'campaign', label: 'キャンペーン'),
  ];

  Future<void> pump(WidgetTester tester, String location) async {
    SharedPreferences.setMockInitialValues({'app_locale': 'ja'});
    final store = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(390 * 3, 1400 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // **アプリと同じルート**（`calendarRoute`）をクーポンの下に置く
    final router = GoRouter(
      initialLocation: AppRoutes.coupon,
      routes: [
        GoRoute(
          path: AppRoutes.coupon,
          builder: (context, state) => const Text('クーポン'),
          routes: [calendarRoute(AppRoutes.coupon)],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(store),
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
    await tester.pump();
    router.push(location);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// そのチップが選ばれているか。
  bool chipSelected(WidgetTester tester, String label) => tester
      .widget<FilterChipButton>(
        find
            .ancestor(
              of: find.text(label),
              matching: find.byType(FilterChipButton),
            )
            .first,
      )
      .selected;

  test('絞り込みはクエリで渡す', () {
    expect(
      AppRoutes.calendar(
        AppRoutes.coupon,
        category: CouponPage.couponCalendarCategory,
      ),
      '/coupon/calendar?category=campaign',
    );
    // メニューからは絞らずに開く
    expect(AppRoutes.calendar(''), '/calendar');
  });

  testWidgets('クーポンの導線はキャンペーンで絞った状態で開く', (tester) async {
    await pump(
      tester,
      AppRoutes.calendar(
        AppRoutes.coupon,
        category: CouponPage.couponCalendarCategory,
      ),
    );

    expect(find.byType(CalendarPage), findsOneWidget);
    expect(chipSelected(tester, 'キャンペーン'), isTrue);
    expect(chipSelected(tester, 'すべて'), isFalse);
    // 日リストもキャンペーンだけ
    expect(find.text('キャンペーンの予定'), findsOneWidget);
    expect(find.text('新メニューの予定'), findsNothing);
  });

  testWidgets('カテゴリの指定が無ければ「すべて」で開く', (tester) async {
    await pump(tester, AppRoutes.calendar(AppRoutes.coupon));

    expect(chipSelected(tester, 'すべて'), isTrue);
    expect(find.text('キャンペーンの予定'), findsOneWidget);
    expect(find.text('新メニューの予定'), findsOneWidget);
  });

  /// **外から URL で来る経路（通知・Universal Links）は何でも書ける。** 配信に
  /// 無いカテゴリで絞ると、何も出ない画面になる（web も検証して `null` に落とす）。
  testWidgets('配信に無いカテゴリは「すべて」に落とす', (tester) async {
    await pump(
      tester,
      AppRoutes.calendar(AppRoutes.coupon, category: 'no-such-category'),
    );

    expect(chipSelected(tester, 'すべて'), isTrue);
    expect(find.text('新メニューの予定'), findsOneWidget);
  });
}
