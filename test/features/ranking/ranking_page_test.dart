import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonsoku/core/storage/preferences_provider.dart';
import 'package:tonsoku/core/i18n/app_locale.dart';
import 'package:tonsoku/core/theme/app_theme.dart';
import 'package:tonsoku/features/home/data/article_providers.dart';
import 'package:tonsoku/features/ranking/data/ranking_repository.dart';
import 'package:tonsoku/features/ranking/presentation/ranking_page.dart';
import 'package:tonsoku/shared/models/article_meta.dart';
import 'package:tonsoku/shared/models/ranking.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 配信は **SWR（キャッシュ → 通信）** なので、`windows` は開いている間に
/// 何度も変わる。**利用者が選ぶまでは中身のある窓に追随し、選んだあとは
/// 上書きしない。**
void main() {
  ArticleMeta article(String slug) => ArticleMeta(
    slug: slug,
    title: slug,
    createdAt: DateTime.utc(2026, 8, 20),
    updatedAt: DateTime.utc(2026, 8, 20),
  );

  RankingPayload payload(Map<String, int> counts) => RankingPayload(
    computedAt: '2026-08-23T22:30:00Z',
    windows: {
      for (final entry in counts.entries)
        entry.key: RankingWindowData(
          items: [
            for (var i = 0; i < entry.value; i++)
              RankingItem(rank: i + 1, slug: 's$i'),
          ],
        ),
    },
  );

  testWidgets('選ぶまでは中身のある窓に追随し、選んだら止まる', (tester) async {
    SharedPreferences.setMockInitialValues({'app_locale': 'ja'});
    final store = await SharedPreferences.getInstance();
    final ranking = StreamController<RankingPayload>();
    addTearDown(ranking.close);

    tester.view.physicalSize = const Size(390 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(store),
          rankingProvider.overrideWith((ref) => ranking.stream),
          articleIndexProvider.overrideWith(
            (ref) => Stream.value([for (var i = 0; i < 5; i++) article('s$i')]),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(AppLocale.ja),
          home: RankingPage(onOpenArticle: (_) {}),
        ),
      ),
    );

    Future<void> push(Map<String, int> counts) async {
      ranking.add(payload(counts));
      await tester.pump();
      await tester.pump();
      await tester.pump();
    }

    // 表示中の窓は、期間タブの選択で見る（窓は 1 本の一覧に切り替えて描く）
    int selected() => RankingWindow.values.indexOf(
      tester.widget<RankingTabs>(find.byType(RankingTabs)).selected,
    );

    // ① キャッシュ（デイリーに中身がある）
    await push({'daily': 5, 'weekly': 5});
    expect(selected(), 0);

    // ② 通信（デイリーが空になった）→ 追随する
    await push({'daily': 0, 'weekly': 5});
    expect(selected(), 1, reason: '空の窓に留まっている');

    // ③ さらに変わっても追随する。**自動で跳んだぶんを「選んだ」に
    // 数えていると、ここで止まる**
    await push({'daily': 0, 'weekly': 0, 'monthly': 5});
    expect(selected(), 2, reason: '自動で跳んだぶんを「選んだ」に数えている');

    // 利用者が選んだら、そのあとは上書きしない
    await tester.tap(find.text('デイリー'));
    await tester.pumpAndSettle();
    expect(selected(), 0);

    await push({'daily': 0, 'weekly': 5});
    expect(selected(), 0, reason: '選んだ窓を上書きした');
  });

  /// **左右に払うと隣の窓へ送る**（web の `data-ranking-swipe`）。端では止める。
  testWidgets('左右に払って窓を送る', (tester) async {
    SharedPreferences.setMockInitialValues({'app_locale': 'ja'});
    final store = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(390 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(store),
          rankingProvider.overrideWith(
            (ref) =>
                Stream.value(payload({'daily': 5, 'weekly': 5, 'monthly': 5})),
          ),
          articleIndexProvider.overrideWith(
            (ref) => Stream.value([for (var i = 0; i < 5; i++) article('s$i')]),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(AppLocale.ja),
          home: RankingPage(onOpenArticle: (_) {}),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    RankingWindow selected() =>
        tester.widget<RankingTabs>(find.byType(RankingTabs)).selected;
    Future<void> fling(double dx) async {
      await tester.fling(find.byType(CustomScrollView), Offset(dx, 0), 1000);
      await tester.pumpAndSettle();
    }

    expect(selected(), RankingWindow.daily);
    // 右から左へ払うと次の窓
    await fling(-300);
    expect(selected(), RankingWindow.weekly);
    await fling(-300);
    expect(selected(), RankingWindow.monthly);
    // 端では止める（回り込まない）
    await fling(-300);
    expect(selected(), RankingWindow.monthly);
    // 左から右へ払うと前の窓
    await fling(300);
    expect(selected(), RankingWindow.weekly);
  });

  /// **貼り付いた状態で短い期間に切り替えても、帯が 2 段に重ならない**
  /// （一覧が短くなって位置が詰められた時に貼り付きを測り直す。PR #22 の
  /// レビューで再現）。
  testWidgets('貼り付いた状態で件数の少ない期間に切り替えても帯は 1 本', (tester) async {
    SharedPreferences.setMockInitialValues({'app_locale': 'ja'});
    final store = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(390 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(store),
          rankingProvider.overrideWith(
            (ref) => Stream.value(payload({'daily': 20, 'weekly': 1})),
          ),
          articleIndexProvider.overrideWith(
            (ref) =>
                Stream.value([for (var i = 0; i < 20; i++) article('s$i')]),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(AppLocale.ja),
          home: RankingPage(onOpenArticle: (_) {}),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    // 下へ送って帯を貼り付かせる（一覧の中の帯＋ヘッダーの下に重ねた帯）
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1500));
    await tester.pumpAndSettle();
    expect(
      find.byKey(RankingPage.stuckTabsKey),
      findsOneWidget,
      reason: '前提: 貼り付いている',
    );

    await tester.tap(find.text('ウィークリー').last);
    await tester.pumpAndSettle();
    // 一覧が短くなって先頭まで詰められた。貼り付いた帯は消え、一覧の中の帯だけ
    expect(
      find.byKey(RankingPage.stuckTabsKey),
      findsNothing,
      reason: '帯が 2 段に重なった',
    );
    expect(find.byType(RankingTabs), findsOneWidget);
  });
}
