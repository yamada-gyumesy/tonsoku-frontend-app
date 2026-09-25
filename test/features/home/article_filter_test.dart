import 'package:flutter_test/flutter_test.dart';
import 'package:tonsoku/features/home/domain/article_filter.dart';
import 'package:tonsoku/shared/models/article_meta.dart';
import 'package:tonsoku/shared/models/category.dart';
import 'package:tonsoku/shared/models/tag.dart';

ArticleMeta article(String slug, String? category, List<String> tags) =>
    ArticleMeta(
      slug: slug,
      title: slug,
      createdAt: DateTime.utc(2026, 9, 1),
      categories: [?category],
      tags: tags,
    );

void main() {
  final articles = [
    article('a', 'menu', ['new-menu', 'limited']),
    article('b', 'store', ['new-store']),
    article('c', 'menu', ['price-up']),
    article('d', null, []),
  ];
  const categories = [
    Category(slug: 'menu', label: 'メニュー'),
    Category(slug: 'official', label: '公式'),
    Category(slug: 'store', label: '店舗'),
  ];
  const tags = [
    Tag(slug: 'limited', label: '店舗限定'),
    Tag(slug: 'new-menu', label: '新メニュー'),
    Tag(slug: 'new-store', label: '新店'),
  ];

  test('記事の無いカテゴリは出さない。並びは配信の順', () {
    expect(
      ArticleFilter.presentCategories(articles, categories).map((c) => c.slug),
      ['menu', 'store'],
    );
  });

  test('タグはそのカテゴリの記事に付いていて、tags.json に載っているものだけ', () {
    // price-up は tags.json に無いので出さない。並びは tags.json の順
    expect(ArticleFilter.childTags(articles, tags, 'menu').map((t) => t.slug), [
      'limited',
      'new-menu',
    ]);
  });

  test('カテゴリとタグで絞る（タグはどれかを持てば残る）', () {
    expect(
      ArticleFilter.apply(
        articles,
        category: null,
        selectedTags: const {},
      ).map((a) => a.slug),
      ['a', 'b', 'c', 'd'],
    );
    expect(
      ArticleFilter.apply(
        articles,
        category: 'menu',
        selectedTags: const {},
      ).map((a) => a.slug),
      ['a', 'c'],
    );
    expect(
      ArticleFilter.apply(
        articles,
        category: 'menu',
        selectedTags: const {'price-up', 'limited'},
      ).map((a) => a.slug),
      ['a', 'c'],
    );
    expect(
      ArticleFilter.apply(
        articles,
        category: 'menu',
        selectedTags: const {'limited'},
      ).map((a) => a.slug),
      ['a'],
    );
  });
}
