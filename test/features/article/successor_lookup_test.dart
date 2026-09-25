import 'package:flutter_test/flutter_test.dart';
import 'package:tonsoku/features/article/domain/successor_lookup.dart';
import 'package:tonsoku/shared/models/article_meta.dart';

ArticleMeta meta(String slug, {String? successor}) => ArticleMeta(
  slug: slug,
  title: slug,
  createdAt: DateTime.utc(2026, 9, 1),
  successorSlug: successor,
);

void main() {
  test('一覧に居れば一覧の値を使う（本体が古くても一覧が正）', () {
    expect(
      SuccessorLookup.resolve(
        article: meta('a'),
        feed: [meta('a', successor: 'b')],
      ),
      'b',
    );
  });

  test('一覧に居て null なら、本体に値があっても出さない', () {
    expect(
      SuccessorLookup.resolve(
        article: meta('a', successor: 'b'),
        feed: [meta('a')],
      ),
      isNull,
    );
  });

  test('一覧に居なければ本体の値を使う（最新 200 件の外の記事）', () {
    expect(
      SuccessorLookup.resolve(
        article: meta('a', successor: 'b'),
        feed: [],
      ),
      'b',
    );
    expect(
      SuccessorLookup.resolve(article: meta('a', successor: 'b'), feed: null),
      'b',
    );
  });

  test('自分自身と空文字は後継として扱わない', () {
    expect(
      SuccessorLookup.resolve(article: meta('a', successor: 'a'), feed: null),
      isNull,
    );
    expect(
      SuccessorLookup.resolve(article: meta('a', successor: ''), feed: null),
      isNull,
    );
  });
}
