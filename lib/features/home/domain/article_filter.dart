import 'package:tonsoku/shared/models/article_meta.dart';
import 'package:tonsoku/shared/models/category.dart';
import 'package:tonsoku/shared/models/tag.dart';

/// 記事一覧の絞り込み。web の `CoArticleFilter` の判定を写したもの。
///
/// - 上の段: 「すべて」＋カテゴリ。**1 つだけ選ぶ**
/// - 下の段: カテゴリを選んだ時だけ、**そのカテゴリの記事に実際に付いているタグ**を
///   出す。複数選べて、**押したタグのどれかを持つ記事だけが残る**。未選択は絞り込みなし
///
/// **並びは配信の順**（カテゴリは `categories.json`、タグは `tags.json`）。こちらで
/// 並べ直すと、配信が意図した優先順が消える（web と同じ判断）。
abstract final class ArticleFilter {
  /// 記事が指しているカテゴリ。**配信の `categories` の先頭 1 件**（web の
  /// `primaryCategorySlug`。この規則をここ以外に書かないこと）。
  static String? primaryCategory(ArticleMeta article) =>
      article.categories.firstOrNull;

  /// 上の段に出すカテゴリ。**記事が 1 本も無いカテゴリは出さない**（押しても
  /// 空になるだけ）。
  static List<Category> presentCategories(
    List<ArticleMeta> articles,
    List<Category> categories,
  ) {
    final used = {for (final a in articles) primaryCategory(a)};
    return categories.where((c) => used.contains(c.slug)).toList();
  }

  /// 下の段に出すタグ。**そのカテゴリの記事に実際に付いていて、`tags.json` に
  /// 載っているものだけ**（ラベルが引けないタグは押す判断ができない）。
  static List<Tag> childTags(
    List<ArticleMeta> articles,
    List<Tag> tags,
    String category,
  ) {
    final used = {
      for (final a in articles)
        if (primaryCategory(a) == category) ...a.tags,
    };
    return tags.where((t) => used.contains(t.slug)).toList();
  }

  /// 絞り込んだ記事。[category] が null なら全件、[selectedTags] が空なら
  /// タグで絞らない。
  static List<ArticleMeta> apply(
    List<ArticleMeta> articles, {
    required String? category,
    required Set<String> selectedTags,
  }) => articles
      .where(
        (a) =>
            (category == null || primaryCategory(a) == category) &&
            (selectedTags.isEmpty || a.tags.any(selectedTags.contains)),
      )
      .toList(growable: false);
}
