import 'package:tonsoku/shared/models/article_meta.dart';

/// 後継記事（「最新の記事があります」の帯）の slug を決める。
///
/// ## gyumesy との違い
///
/// **とん速の記事本体（`articles/{slug}.json`）は `successor_slug` を持つ。**
/// gyumesy は md のフロントマターに入らなかったので一覧（feed → カテゴリ別一覧）を
/// 引くしかなかったが、ここは本体の値を持っている。
///
/// ## それでも一覧を先に見る
///
/// **一覧と本体は別オブジェクトとして R2 に上がるので、片方だけ新しい瞬間がある**
/// （web の `articles/[slug].astro` の注記）。web は判定も解決も一覧だけで行う。
///
/// アプリは一覧を最新 200 件しか持たないので、**一覧に居れば一覧の値（null でも）、
/// 居なければ本体の値**にする。一覧に居る記事について一覧が正なのは gyumesy と
/// 同じ判断で、「一覧に居るが null」を「分からない」と扱うと、後継の無い直近記事
/// すべてで本体の値に落ちて、一覧と本体のずれがそのまま出る。
class SuccessorLookup {
  const SuccessorLookup._();

  /// [article] の後継。無ければ null。[feed] がまだ届いていなければ本体の値を使う。
  static String? resolve({
    required ArticleMeta article,
    required List<ArticleMeta>? feed,
  }) {
    final fromFeed = _find(feed, article.slug);
    final slug = fromFeed != null
        ? fromFeed.successorSlug
        : article.successorSlug;
    // **自分自身は落とす**（配信が入れてくることは無いはずだが、出ると妙に見える。
    // web も同じ）
    if (slug == article.slug) return null;
    return _normalize(slug);
  }

  static ArticleMeta? _find(List<ArticleMeta>? list, String slug) {
    if (list == null) return null;
    for (final a in list) {
      if (a.slug == slug) return a;
    }
    return null;
  }

  /// 「後継なし」を空文字で表されても slug として扱わない（gyumesy の配信は
  /// null と空文字が混在していた）。
  static String? _normalize(String? value) =>
      (value == null || value.isEmpty) ? null : value;
}
