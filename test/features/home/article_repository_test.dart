import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tonsoku/features/home/data/article_repository.dart';

/// `articles/index.json`（オブジェクトに包まれた全記事）の読み込み。
void main() {
  Map<String, dynamic> meta(String slug, {Object? createdAt = 'x'}) => {
    'slug': slug,
    'title': slug,
    'category': 'menu',
    'created_at': createdAt == 'x' ? '2026-09-01T00:00:00+09:00' : createdAt,
  };

  String index(List<Map<String, dynamic>> articles) => jsonEncode({
    'generated_at': '2026-09-25T00:00:00+09:00',
    'count': articles.length,
    'articles': articles,
  });

  /// **1 件の崩れで一覧ごと失敗させない**（feed.json と同じ規則）。配信の
  /// スキーマは `created_at` に null を許している。
  test('読めない記事はその 1 件だけ落とす', () {
    final articles = ArticleRepository.decodeIndex(
      index([meta('a'), meta('broken', createdAt: null), meta('c')]),
    );
    expect(articles.map((a) => a.slug), ['a', 'c']);
  });

  test('1 件も読めなければ例外（キャッシュの値を出し続けさせる）', () {
    expect(
      () => ArticleRepository.decodeIndex(
        index([meta('broken', createdAt: null)]),
      ),
      throwsFormatException,
    );
  });

  test('空の一覧は空のまま', () {
    expect(ArticleRepository.decodeIndex(index([])), isEmpty);
  });
}
