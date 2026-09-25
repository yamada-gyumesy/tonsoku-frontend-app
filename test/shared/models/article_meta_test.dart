import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tonsoku/core/cdn/cdn_repository.dart';
import 'package:tonsoku/shared/models/article_meta.dart';

void main() {
  // 実際の feed.json の 1 要素（cdn.ton-soku.com/articles/feed.json、2026-09-25）
  const sample = '''
{
  "slug": "kyo53t",
  "title": "松のや、背脂生姜タレのポークフライドステーキ定食3品を9月30日発売",
  "description": "松のやは2026年9月30日（水）15時から3品を発売する。",
  "thumbnail": "https://cdn.ton-soku.com/articles/kyo53t/thumbnail.webp",
  "thumbnail_sm": "https://cdn.ton-soku.com/articles/kyo53t/thumbnail-sm.webp",
  "ogp_image": "https://cdn.ton-soku.com/articles/kyo53t/ogp.png",
  "thumbnail_source": null,
  "categories": ["menu"],
  "tags": ["new-menu"],
  "trigger_type": "news-post",
  "created_at": "2026-09-25T03:10:11.123456+00:00",
  "updated_at": "2026-09-25T03:12:00.000000+00:00",
  "editor_comment": "むっ。100円上がったか。",
  "expression": "confused",
  "source_url": "https://www.matsuyafoods.co.jp/matsunoya/",
  "related_articles": ["gbx2ie", "4yfic0"],
  "series_key": null,
  "successor_slug": null,
  "published": true
}
''';

  ArticleMeta parse(String json) =>
      ArticleMeta.fromJson(jsonDecode(json) as Map<String, dynamic>);

  test('配信データをそのままパースできる', () {
    final article = parse(sample);

    expect(article.slug, 'kyo53t');
    expect(article.categories, ['menu']);
    expect(article.tags, ['new-menu']);
    expect(article.triggerType, 'news-post');
    expect(article.expression, 'confused');
    expect(article.relatedArticles, ['gbx2ie', '4yfic0']);
    expect(article.seriesKey, isNull);
    expect(article.successorSlug, isNull);
    // マイクロ秒付きの UTC（とん速の配信の形）
    expect(
      article.createdAt.toUtc(),
      DateTime.utc(2026, 9, 25, 3, 10, 11, 123, 456),
    );
  });

  test('null の鍵は空文字に寄せる（とん速の配信は null を出す）', () {
    // 店舗の開店など、絵も要約も無い記事の形
    final article = parse('''
{
  "slug": "5723kr",
  "title": "t",
  "description": null,
  "thumbnail": null,
  "thumbnail_sm": null,
  "thumbnail_source": null,
  "editor_comment": null,
  "expression": null,
  "source_url": null,
  "created_at": "2026-09-25T05:34:07.831354+00:00",
  "updated_at": null
}
''');

    expect(article.description, '');
    expect(article.thumbnail, '');
    expect(article.thumbnailSmall, '');
    expect(article.editorComment, '');
    expect(article.expression, isNull);
    expect(article.sourceUrl, '');
    expect(article.updatedAt, isNull);
    expect(article.hasThumbnail, isFalse);
  });

  test('必須項目だけでもパースできる', () {
    // 配信側が任意項目を落としてもアプリが落ちないこと
    final article = parse('''
{
  "slug": "a",
  "title": "t",
  "created_at": "2026-01-01T00:00:00+09:00"
}
''');

    expect(article.categories, isEmpty);
    expect(article.editorComment, '');
    expect(article.hasThumbnail, isFalse);
  });

  test('一覧用サムネイルは配信の thumbnail_sm を使う', () {
    expect(
      parse(sample).thumbnailSmall,
      'https://cdn.ton-soku.com/articles/kyo53t/thumbnail-sm.webp',
    );
  });

  test('小さい版が無ければ原寸に落とす（絵は出す）', () {
    final article = parse('''
{
  "slug": "a",
  "title": "t",
  "thumbnail": "https://cdn.ton-soku.com/articles/a/thumbnail.webp",
  "thumbnail_sm": null,
  "created_at": "2026-01-01T00:00:00+09:00"
}
''');

    expect(
      article.thumbnailSmall,
      'https://cdn.ton-soku.com/articles/a/thumbnail.webp',
    );
  });

  test('created_at が null の記事が 1 件混じっても、一覧は残りを返す', () {
    // 契約上 `created_at` は null を許す（配信に載るのは配信済みだけなので
    // 実際には入る）。来た時にその 1 件だけが落ちること
    final list = decodeJsonList(ArticleMeta.fromJson)(
      '[$sample, {"slug": "b", "title": "t", "created_at": null}]',
    );
    expect(list.map((a) => a.slug), ['kyo53t']);
  });
}
