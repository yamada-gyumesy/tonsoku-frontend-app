import 'package:tonsoku/shared/models/article_meta.dart';
import 'package:tonsoku/shared/models/ranking.dart';

/// 順位と、その順位の記事メタ。
typedef RankingEntry = ({int rank, ArticleMeta article});

/// 配信の順位リストに記事メタを結び付ける。
///
/// **一覧に無い slug は捨てる。** 配信側も index 未掲載を assert で弾いているが、
/// `ranking.json` と `index.json` は別々に上がるので、片方だけ新しい状態が
/// 起こりうる。残してもタイトルもサムネイルも無い空枠が並ぶだけ。
///
/// **落ちた順位は詰めない**（1・2・4 のように飛ぶ）。詰めると実際の順位と
/// 食い違い、同じ記事が言語によって違う順位で出る。
List<RankingEntry> resolveRankingEntries(
  List<RankingItem> items,
  List<ArticleMeta> articles,
) {
  final bySlug = {for (final a in articles) a.slug: a};
  return [
    for (final item in items)
      if (bySlug[item.slug] case final article?)
        (rank: item.rank, article: article),
  ]..sort((a, b) => a.rank - b.rank);
}

/// 大きいカードで見せるか。
///
/// **順位で分ける。件数で切らないこと。** 件数で切ると、一覧に無い slug が
/// 落ちた時に 4 位が大きいカードに繰り上がって、順位と見た目が食い違う。
bool isTopRank(int rank) => rank <= rankingTopRank;

/// 窓ごとの、突き合わせ済みの順位。**描くのはこの 3 つだけ。**
Map<RankingWindow, List<RankingEntry>> resolveAllWindows(
  RankingPayload payload,
  List<ArticleMeta> articles,
) => {
  for (final window in RankingWindow.values)
    window: resolveRankingEntries(
      payload.window(window)?.items ?? const [],
      articles,
    ),
};

/// 最初に見せる窓。**中身のある最初の窓**（web の `initial`）。
///
/// 先頭固定にすると、デイリーが空でウィークリーに 5 件ある時に**空の画面から
/// 始まる**。
RankingWindow initialWindow(Map<RankingWindow, List<RankingEntry>> windows) =>
    RankingWindow.values.firstWhere(
      (w) => (windows[w] ?? const []).isNotEmpty,
      orElse: () => RankingWindow.values.first,
    );

/// タブごと出すか。
///
/// **突き合わせ後の件数で判定する。** 生の件数で見ると、一覧に無い slug ばかり
/// の時に**導線は出るのに開いたら空**になる。
///
/// 空の画面へ行ける入口を残すと、壊れているように見える（web の `hasRanking`）。
bool hasAnyRanking(Map<RankingWindow, List<RankingEntry>> windows) =>
    windows.values.any((entries) => entries.isNotEmpty);
