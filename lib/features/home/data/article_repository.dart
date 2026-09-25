import 'dart:convert';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tonsoku/core/cdn/cdn_paths.dart';
import 'package:tonsoku/core/cdn/cdn_repository.dart';
import 'package:tonsoku/core/i18n/app_locale.dart';
import 'package:tonsoku/core/i18n/locale_controller.dart';
import 'package:tonsoku/shared/models/article.dart';
import 'package:tonsoku/shared/models/article_meta.dart';
import 'package:tonsoku/shared/models/category.dart';
import 'package:tonsoku/shared/models/limited_week.dart';
import 'package:tonsoku/shared/models/tag.dart';

/// 記事一覧・記事本体・分類・店舗限定の週の取得。
///
/// 一覧系は翻訳 0 件でも空配列で 200 が返る契約なので、**404 を握り潰さない**。
/// ここで 404 が出たら配信の異常であって「記事が無い」ではない
/// （gyumesy-frontend-app の `ArticleRepository` と同じ）。
class ArticleRepository {
  ArticleRepository({required this._cdn, required AppLocale locale})
    : _paths = CdnPaths(locale);

  final CdnRepository _cdn;
  final CdnPaths _paths;

  static final _decodeFeed = decodeJsonList(ArticleMeta.fromJson);

  /// `articles/index.json` は**オブジェクトに包まれている**（`{generated_at,
  /// count, articles}`。feed.json は配列）。`count` は見ない —— 食い違った時に
  /// 信じるのは実体のほう（web の `models/article.ts`）。
  static List<ArticleMeta> _decodeIndex(String body) =>
      ((jsonDecode(body) as Map<String, dynamic>)['articles'] as List<dynamic>)
          .map((e) => ArticleMeta.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);

  /// **カテゴリとタグは 1 件でも読めなければ例外にする**（`decodeJsonListStrict`）。
  /// ラベルの正なので、1 件を黙って落とすとそのカテゴリがどこからも辿れなくなる
  static final _decodeCategories = decodeJsonListStrict(Category.fromJson);
  static final _decodeTags = decodeJsonListStrict(Tag.fromJson);
  static final _decodeLimitedWeeks = decodeJsonObject(LimitedWeeks.fromJson);
  static final _decodeArticle = decodeJsonObject(Article.fromJson);

  /// 最新 200 件（配列）。キャッシュを先に流してから取得し直す。
  ///
  /// **配信は `created_at` の降順で並んでいる。並べ直さないこと**（web と同じ。
  /// フロントで別の順に組み替えると「新着」の定義が 2 箇所に増える）。
  Stream<List<ArticleMeta>> watchFeed() => _cdn.watch(_paths.feed, _decodeFeed);

  /// **全記事**（`articles/index.json`）。記事一覧（「過去の記事を見る」の先）が使う。
  ///
  /// web の記事一覧も全件を 1 枚に出している。feed（最新 200 件）で済ませると、
  /// 記事が 200 本を超えた日から古い記事へ辿る道が消える。
  Stream<List<ArticleMeta>> watchArticleIndex() =>
      _cdn.watch(_paths.articleIndex, _decodeIndex);

  Stream<List<Category>> watchCategories() =>
      _cdn.watch(_paths.categories, _decodeCategories);

  Stream<List<Tag>> watchTags() => _cdn.watch(_paths.tags, _decodeTags);

  /// ホームの店舗限定の週カード。
  Stream<LimitedWeeks> watchLimitedWeeks() =>
      _cdn.watch(_paths.limitedWeeks, _decodeLimitedWeeks);

  /// 記事 1 本。**メタもここから取れる**ので、一覧に無い記事でも開ける。
  Stream<Article> watchArticle(String slug) =>
      _cdn.watch(_paths.article(slug), _decodeArticle);

  /// 引っ張って更新・アクティブ復帰で使う、キャッシュを読まない取り直し。
  /// 取り直して、**本文が変わった時だけ true**（`fetchFreshIfChanged` の doc）。
  Future<bool> refreshFeed() =>
      _cdn.fetchFreshIfChanged(_paths.feed, _decodeFeed);

  Future<bool> refreshArticleIndex() =>
      _cdn.fetchFreshIfChanged(_paths.articleIndex, _decodeIndex);

  Future<bool> refreshCategories() =>
      _cdn.fetchFreshIfChanged(_paths.categories, _decodeCategories);

  Future<bool> refreshTags() =>
      _cdn.fetchFreshIfChanged(_paths.tags, _decodeTags);

  Future<bool> refreshLimitedWeeks() =>
      _cdn.fetchFreshIfChanged(_paths.limitedWeeks, _decodeLimitedWeeks);

  /// 記事本体の取り直し。**引っ張って更新に要る**（gyumesy と同じ理由。
  /// これが無いと `invalidate` しても `watch()` のキャッシュ値で即座に解決する）。
  Future<void> refreshArticle(String slug) =>
      _cdn.fetchFresh(_paths.article(slug), _decodeArticle);
}

final articleRepositoryProvider = Provider<ArticleRepository>(
  (ref) => ArticleRepository(
    cdn: ref.watch(cdnRepositoryProvider),
    locale: ref.watch(localeControllerProvider),
  ),
);
