import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tonsoku/core/i18n/app_locale.dart';
import 'package:tonsoku/core/storage/preferences_provider.dart';
import 'package:tonsoku/core/theme/app_theme.dart';
import 'package:tonsoku/features/calendar/data/calendar_repository.dart';
import 'package:tonsoku/features/calendar/presentation/calendar_page.dart';
import 'package:tonsoku/features/home/data/article_providers.dart';
import 'package:tonsoku/shared/models/article_meta.dart';
import 'package:tonsoku/shared/models/calendar_event.dart';
import 'package:tonsoku/shared/models/category.dart';
import 'package:tonsoku/shared/models/tag.dart';
import 'package:tonsoku/shared/widgets/back_header.dart';
import 'package:tonsoku/shared/widgets/source_chip.dart';

/// とん速で足したもの・変えたもの（gyumesy から写したテストは別のファイル）。
void main() {
  final today = DateTime.now();
  String iso(int day) =>
      '${today.year.toString().padLeft(4, '0')}-'
      '${today.month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  final noArticle = CalendarEvent(
    id: 'no-article',
    title: '記事の無い予定',
    category: 'store',
    startDate: iso(10),
    sourceUrl: 'https://example.com/shop',
  );
  final withArticle = CalendarEvent(
    id: 'with-article',
    title: '記事のある予定',
    category: 'store',
    startDate: iso(10),
    articleSlug: 'abc123',
    // **http(s) 以外は導線にしない**（web の `safeExternalUrl`）
    sourceUrl: 'javascript:alert(1)',
  );

  Future<List<String>> pump(WidgetTester tester) async {
    final opened = <String>[];
    SharedPreferences.setMockInitialValues({'app_locale': 'ja'});
    final store = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(store),
          calendarProvider.overrideWith(
            (ref) =>
                Stream.value(CalendarPayload(events: [noArticle, withArticle])),
          ),
          categoriesProvider.overrideWith(
            (ref) => Stream.value(const [Category(slug: 'store', label: '店舗')]),
          ),
          tagsProvider.overrideWith((ref) => Stream.value(const <Tag>[])),
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

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// **ランキングと同じ作り。** 一覧の中の帯はそのまま流し、見出しの帯の裏まで
  /// 来たら同じ帯をヘッダーのすぐ下に重ねる（web の `.sticky-band`）。
  testWidgets('月ナビとカテゴリの帯はヘッダーのすぐ下に貼り付く', (tester) async {
    await pump(tester);
    expect(find.byType(CalendarToolbar), findsOneWidget);

    // 少しずつ上へ送る（1 回で大きく送ると、ヘッダーの退き方を飛び越える）
    for (var i = 0; i < 6; i++) {
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -80));
      await tester.pump();
    }

    // **ヘッダーの下端にぴったり付いた帯がある**（ヘッダーが退いたぶん一緒に
    // 上がる）。一覧の中の帯は画面の上へ流れていく（遠くまで流れると組まれ
    // なくなるので、数ではなく位置で見る）
    final header = tester.getBottomLeft(find.byType(BackHeader)).dy;
    expect(header, lessThan(BackHeader.height));
    final tops = [
      for (final e in find.byType(CalendarToolbar).evaluate())
        tester.getTopLeft(find.byWidget(e.widget)).dy,
    ];
    expect(tops, contains(moreOrLessEquals(header, epsilon: 1)));

    // 先頭まで戻せば、一覧の中の帯だけに戻る（見出しの下に居る）
    // **行き過ぎない**（先頭で引くと引っ張って更新が走り、配信を取りに行く）
    final scrollable = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    scrollable.position.jumpTo(0);
    await settle(tester);
    expect(find.byType(CalendarToolbar), findsOneWidget);
    expect(
      tester.getTopLeft(find.byType(CalendarToolbar)).dy,
      greaterThan(tester.getBottomLeft(find.byType(BackHeader)).dy),
    );
  });

  /// **web の題の `data-event-id`**: 記事の無い予定の題は、その予定の詳細を
  /// 出す（gyumesy はその日全体を出していた）。
  testWidgets('記事の無い予定の題を押すと、その予定だけを出す', (tester) async {
    final opened = await pump(tester);

    await tester.ensureVisible(find.text('記事の無い予定'));
    await tester.pump();
    await tester.tap(find.text('記事の無い予定'));
    await settle(tester);

    // 行とシートの 2 か所に出る。同じ日の別の予定はシートに出ない
    expect(find.text('記事の無い予定'), findsNWidgets(2));
    expect(find.text('記事のある予定'), findsOneWidget);
    expect(opened, isEmpty);
  });

  testWidgets('記事のある予定の題を押すと記事を開く', (tester) async {
    final opened = await pump(tester);

    await tester.ensureVisible(find.text('記事のある予定'));
    await tester.pump();
    await tester.tap(find.text('記事のある予定'));
    await tester.pump();
    expect(opened, ['abc123']);
  });

  /// **http(s) 以外の出典は導線にしない**（配信はこちらの管理下に無い）。
  testWidgets('出典は http(s) の時だけ「公式」を出す', (tester) async {
    await pump(tester);
    expect(find.byType(SourceChip), findsOneWidget);
    expect(SourceChip.safeUrl('javascript:alert(1)'), isNull);
    expect(SourceChip.safeUrl(null), isNull);
    expect(SourceChip.safeUrl('/relative'), isNull);
    expect(
      SourceChip.safeUrl('https://example.com/a'),
      'https://example.com/a',
    );
  });

  testWidgets('ダークでも崩れずに組める', (tester) async {
    SharedPreferences.setMockInitialValues({'app_locale': 'ja'});
    final store = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(store),
          calendarProvider.overrideWith(
            (ref) =>
                Stream.value(CalendarPayload(events: [noArticle, withArticle])),
          ),
          categoriesProvider.overrideWith(
            (ref) => Stream.value(const [Category(slug: 'store', label: '店舗')]),
          ),
          tagsProvider.overrideWith((ref) => Stream.value(const <Tag>[])),
          articleIndexProvider.overrideWith(
            (ref) => const Stream<List<ArticleMeta>>.empty(),
          ),
          feedProvider.overrideWith(
            (ref) => const Stream<List<ArticleMeta>>.empty(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(AppLocale.ja),
          home: CalendarPage(onOpenArticle: (_) {}),
        ),
      ),
    );
    await settle(tester);
    expect(find.byType(CalendarToolbar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
