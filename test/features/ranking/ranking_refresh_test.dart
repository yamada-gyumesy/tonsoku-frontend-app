import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tonsoku/core/storage/preferences_provider.dart';
import 'package:tonsoku/core/i18n/app_locale.dart';
import 'package:tonsoku/core/theme/app_theme.dart';
import 'package:tonsoku/features/home/data/article_repository.dart';
import 'package:tonsoku/features/ranking/data/ranking_repository.dart';
import 'package:tonsoku/features/ranking/presentation/ranking_page.dart';
import 'package:tonsoku/shared/models/article_meta.dart';
import 'package:tonsoku/shared/models/ranking.dart';

/// ランキングの引っ張って更新。
///
/// **順位だけ取り直すと、新しく入った記事が順位ごと消える。** 画面が見ている
/// のは順位と一覧（`index.json`）の突き合わせで、**一覧に無い slug は捨てる**
/// 作り。`ranking.json` と `index.json` は別々に上がるので、片方だけ新しい状態が
/// 起こりうる —— 引っ張って更新でその状態を自分から作らないこと。
void main() {
  ArticleMeta article(String slug) => ArticleMeta(
    slug: slug,
    title: slug,
    createdAt: DateTime.utc(2026, 8, 20),
    updatedAt: DateTime.utc(2026, 8, 20),
  );

  RankingPayload payload(List<String> slugs) => RankingPayload(
    computedAt: '2026-08-23T22:30:00Z',
    windows: {
      'daily': RankingWindowData(
        items: [
          for (var i = 0; i < slugs.length; i++)
            RankingItem(rank: i + 1, slug: slugs[i]),
        ],
      ),
    },
  );

  testWidgets('引っ張ると順位も一覧も新しくなる', (tester) async {
    SharedPreferences.setMockInitialValues({'app_locale': 'ja'});
    final store = await SharedPreferences.getInstance();

    final ranking = _FakeRankingRepository(payload(['s0', 's1', 's2']));
    final articles = _FakeArticleRepository([
      article('s0'),
      article('s1'),
      article('s2'),
    ]);

    tester.view.physicalSize = const Size(390 * 3, 1200 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(store),
          rankingRepositoryProvider.overrideWithValue(ranking),
          articleRepositoryProvider.overrideWithValue(articles),
        ],
        child: MaterialApp(
          theme: AppTheme.light(AppLocale.ja),
          home: Scaffold(body: RankingPage(onOpenArticle: (_) {})),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('s2'), findsOneWidget);

    // 配信側が新しくなった。**s2 が落ちて s3 が入る**
    ranking.next = payload(['s0', 's1', 's3']);
    articles.next = [
      article('s0'),
      article('s1'),
      article('s2'),
      article('s3'),
    ];

    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, 400),
      1000,
    );
    await tester.pumpAndSettle();

    expect(ranking.refreshCalls, greaterThan(0), reason: '順位を取りに行っていない');
    expect(
      articles.refreshCalls,
      greaterThan(0),
      reason: '一覧を取りに行っていない（新しい記事が順位ごと消える）',
    );
    expect(
      find.text('s3'),
      findsOneWidget,
      reason: '一覧を据え置くと、新しく入った記事が順位ごと消える',
    );
    expect(find.text('s2'), findsNothing);
  });
}

/// **本物と同じく `watch()` は 1 回 yield して完了する。** そこが
/// 「貼り直さないと変わらない」の原因なので、写さないとテストが意味を持たない。
class _FakeRankingRepository implements RankingRepository {
  _FakeRankingRepository(this.next);

  RankingPayload next;
  int refreshCalls = 0;

  @override
  Stream<RankingPayload> watch() async* {
    yield next;
  }

  @override
  Future<void> refreshRanking() async => refreshCalls++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeArticleRepository implements ArticleRepository {
  _FakeArticleRepository(this.next);

  List<ArticleMeta> next;
  int refreshCalls = 0;

  @override
  Stream<List<ArticleMeta>> watchArticleIndex() async* {
    yield next;
  }

  @override
  Future<bool> refreshArticleIndex() async {
    refreshCalls++;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
