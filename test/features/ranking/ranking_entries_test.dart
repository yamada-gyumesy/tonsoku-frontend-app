import 'package:flutter_test/flutter_test.dart';
import 'package:tonsoku/features/ranking/domain/ranking_entries.dart';
import 'package:tonsoku/shared/models/article_meta.dart';
import 'package:tonsoku/shared/models/ranking.dart';

/// 配信されるのは順位と slug だけなので、記事メタは一覧側と突き合わせる。
void main() {
  ArticleMeta article(String slug) => ArticleMeta(
    slug: slug,
    title: slug,
    createdAt: DateTime.utc(2026, 8, 20),
    updatedAt: DateTime.utc(2026, 8, 20),
  );

  test('一覧に無い slug は捨てる', () {
    // `ranking.json` と `index.json` は別々に上がるので、片方だけ新しい状態が
    // 起こりうる。残してもタイトルもサムネイルも無い空枠が並ぶだけ
    final entries = resolveRankingEntries(
      const [
        RankingItem(rank: 1, slug: 'a'),
        RankingItem(rank: 2, slug: 'missing'),
        RankingItem(rank: 3, slug: 'c'),
      ],
      [article('a'), article('c')],
    );

    expect(entries.map((e) => e.article.slug), ['a', 'c']);
  });

  test('落ちた順位は詰めない（1・2・4 のように飛ぶ）', () {
    // 詰めると実際の順位と食い違い、同じ記事が言語によって違う順位で出る
    final entries = resolveRankingEntries(
      const [
        RankingItem(rank: 1, slug: 'a'),
        RankingItem(rank: 2, slug: 'b'),
        RankingItem(rank: 3, slug: 'missing'),
        RankingItem(rank: 4, slug: 'd'),
      ],
      [article('a'), article('b'), article('d')],
    );

    expect(entries.map((e) => e.rank), [1, 2, 4]);
  });

  test('順位の昇順に並べ直す', () {
    final entries = resolveRankingEntries(
      const [RankingItem(rank: 3, slug: 'c'), RankingItem(rank: 1, slug: 'a')],
      [article('a'), article('c')],
    );

    expect(entries.map((e) => e.rank), [1, 3]);
  });

  test('上位は順位で分ける（件数で切らない）', () {
    // 件数で切ると、一覧に無い slug が落ちた時に 4 位が大きいカードに
    // 繰り上がって、順位と見た目が食い違う
    final entries = resolveRankingEntries(
      const [
        RankingItem(rank: 1, slug: 'a'),
        RankingItem(rank: 2, slug: 'missing'),
        RankingItem(rank: 3, slug: 'c'),
        RankingItem(rank: 4, slug: 'd'),
      ],
      [article('a'), article('c'), article('d')],
    );

    // 3 件残っているが、大きく出すのは 1 位と 3 位だけ
    expect(entries.map((e) => isTopRank(e.rank)), [true, true, false]);
  });

  group('タブを出すかどうか', () {
    test('**突き合わせ後**の件数で判定する', () {
      // 生の件数で見ると、一覧に無い slug ばかりの時に**導線は出るのに
      // 開いたら空**になる
      const payload = RankingPayload(
        windows: {
          'daily': RankingWindowData(
            items: [RankingItem(rank: 1, slug: 'missing')],
          ),
        },
      );

      expect(
        hasAnyRanking(resolveAllWindows(payload, [])),
        isFalse,
        reason: '一覧に無い slug だけなら、開いても空',
      );
      expect(
        hasAnyRanking(resolveAllWindows(payload, [article('missing')])),
        isTrue,
      );
    });

    test('どの窓も空なら出さない', () {
      // 空の画面へ行ける入口を残すと、壊れているように見える
      expect(
        hasAnyRanking(resolveAllWindows(const RankingPayload(), [])),
        isFalse,
      );
    });
  });

  group('最初に見せる窓', () {
    test('中身のある最初の窓に合わせる', () {
      // 先頭固定にすると、デイリーが空でウィークリーに 5 件ある時に
      // **空の画面から始まる**
      const payload = RankingPayload(
        windows: {
          'daily': RankingWindowData(),
          'weekly': RankingWindowData(items: [RankingItem(rank: 1, slug: 'a')]),
        },
      );

      final windows = resolveAllWindows(payload, [article('a')]);
      expect(initialWindow(windows), RankingWindow.weekly);
    });

    test('全部空なら先頭', () {
      final windows = resolveAllWindows(const RankingPayload(), []);
      expect(initialWindow(windows), RankingWindow.daily);
    });

    test('描くのは enum の 3 つだけ（配信に別のキーが来ても増やさない）', () {
      const payload = RankingPayload(
        windows: {
          'daily': RankingWindowData(items: [RankingItem(rank: 1, slug: 'a')]),
          'yearly': RankingWindowData(items: [RankingItem(rank: 1, slug: 'a')]),
        },
      );

      final windows = resolveAllWindows(payload, [article('a')]);
      expect(windows.keys, RankingWindow.values);
    });
  });

  group('選ぶ前は中身に追随する', () {
    // **デイリーは 04:00 に切り替わる。** 前日ぶんのキャッシュ（デイリー 5 件）で
    // 窓を確定した直後に通信の結果（デイリー 0 件）が来ると、空の窓を見せたまま
    // 止まる。「まだ選んでいない / もう選んだ」を分けて持つ必要がある
    test('中身が変われば最初に見せる窓も変わる', () {
      final cached = resolveAllWindows(
        const RankingPayload(
          windows: {
            'daily': RankingWindowData(
              items: [RankingItem(rank: 1, slug: 'a')],
            ),
            'weekly': RankingWindowData(
              items: [RankingItem(rank: 1, slug: 'a')],
            ),
          },
        ),
        [article('a')],
      );
      expect(initialWindow(cached), RankingWindow.daily);

      final fresh = resolveAllWindows(
        const RankingPayload(
          windows: {
            'daily': RankingWindowData(),
            'weekly': RankingWindowData(
              items: [RankingItem(rank: 1, slug: 'a')],
            ),
          },
        ),
        [article('a')],
      );
      expect(initialWindow(fresh), RankingWindow.weekly);
    });
  });
}
