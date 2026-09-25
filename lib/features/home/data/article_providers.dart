import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tonsoku/features/coupon/data/coupon_repository.dart';
import 'package:tonsoku/features/home/data/article_repository.dart';
import 'package:tonsoku/shared/models/article.dart';
import 'package:tonsoku/shared/models/article_meta.dart';
import 'package:tonsoku/shared/models/category.dart';
import 'package:tonsoku/shared/models/limited_week.dart';
import 'package:tonsoku/shared/models/tag.dart';

/// 配信データの購読口。
///
/// **`StreamProvider` で受ける。** `CdnRepository.watch()` はキャッシュと取得後の
/// 値を順に流す（stale-while-revalidate）ので、購読を張り続ける形でないと 2 つ目が
/// 届かない。`.first` や `take(2)` のように途中で解除する消費の仕方をしないこと。
///
/// ロケールを切り替えると `articleRepositoryProvider` が作り直され、ここも
/// 自動で貼り直される（配信パスの名前空間が変わるため）。

final feedProvider = StreamProvider<List<ArticleMeta>>(
  (ref) => ref.watch(articleRepositoryProvider).watchFeed(),
);

/// 全記事（記事一覧の画面だけが使う）。
final articleIndexProvider = StreamProvider<List<ArticleMeta>>(
  (ref) => ref.watch(articleRepositoryProvider).watchArticleIndex(),
);

final categoriesProvider = StreamProvider<List<Category>>(
  (ref) => ref.watch(articleRepositoryProvider).watchCategories(),
);

final tagsProvider = StreamProvider<List<Tag>>(
  (ref) => ref.watch(articleRepositoryProvider).watchTags(),
);

final limitedWeeksProvider = StreamProvider<LimitedWeeks>(
  (ref) => ref.watch(articleRepositoryProvider).watchLimitedWeeks(),
);

/// 記事 1 本。
final articleProvider = StreamProvider.family<Article, String>(
  (ref, slug) => ref.watch(articleRepositoryProvider).watchArticle(slug),
);

/// 中身が無くて画面に出せないメタ。**「取得できなかった」と同じ扱いにする**
/// （gyumesy-frontend-app と同じ）。
///
/// 関連記事や後継記事の帯は**題が無いと押す判断ができない**ので、題の無い
/// メタは出さない。
class UnreadableArticleException implements Exception {
  const UnreadableArticleException(this.slug);

  final String slug;

  @override
  String toString() => 'UnreadableArticleException: $slug';
}

/// 関連記事・後継記事のメタデータ。
///
/// **一覧から引かずに、その記事の本体を取って解決する**（gyumesy と同じ）。
/// 一覧は最新 200 件しか持たないので、古い記事を指す関連記事が黙って消える
/// （gyumesy の実測で参照の 46% が一覧の外にあった）。1 本あたり数 KB。
///
/// **`watch` で取る（1 回取ったら終わりにしない）。** 配信が一時的に崩れた瞬間の
/// 本体をキャッシュに掴むと、配信が直っても永久に壊れた行を出し続ける
/// （gyumesy が実機で踏んでいる）。
///
/// **題の無いメタは例外にして流す。** 呼び出し側（関連記事・後継記事の帯）は
/// どちらも「解決できなければ出さない」作りなので、出さない判断が 1 箇所で揃う。
///
/// **404 もここで例外になる。** 一覧と本体は別オブジェクトとして R2 に上がるので、
/// 取り下げた記事を指したままの瞬間がある（web は一覧と突き合わせて落としている）。
final articleMetaProvider = StreamProvider.family<ArticleMeta, String>(
  (ref, slug) =>
      ref.watch(articleRepositoryProvider).watchArticle(slug).map((article) {
        final meta = article.meta;
        if (meta.title.isEmpty) throw UnreadableArticleException(slug);
        return meta;
      }),
);

/// ホームの配信をまとめて取り直す。引っ張って更新・アクティブ復帰から使う。
///
/// **キャッシュを読まずに取り直してから provider を貼り直す**（gyumesy の
/// `refreshArticleLists` と同じ。`invalidate` して待つだけでは `watch()` が先に流す
/// キャッシュ値で即座に解決し、取得の完了を待たずにスピナーが閉じる）。
///
/// **変わった物だけ貼り直す。** 配信データは大半の復帰で変わっていないので、
/// 絞らないと毎回全経路ぶん空回りさせる（`fetchFreshIfChanged`）。
///
/// **失敗はここで握り潰してスピナーを確実に閉じる。** 表示は各 provider の
/// エラー表示に委ねる（取れなかった物は貼り直さず、前に出ていた値を残す）。
Future<void> refreshHomeLists(ProviderContainer container) async {
  final articles = container.read(articleRepositoryProvider);

  var feedChanged = false;
  var categoriesChanged = false;
  var tagsChanged = false;
  var weeksChanged = false;
  var couponChanged = false;

  Future<void> run(Future<bool> task, void Function(bool) store) async {
    try {
      store(await task);
    } on Object {
      // 取れなかった物は貼り直さない（前に出ていた値をそのまま残す）
    }
  }

  await Future.wait([
    run(articles.refreshFeed(), (v) => feedChanged = v),
    run(articles.refreshCategories(), (v) => categoriesChanged = v),
    run(articles.refreshTags(), (v) => tagsChanged = v),
    run(articles.refreshLimitedWeeks(), (v) => weeksChanged = v),
    run(
      container.read(couponRepositoryProvider).refreshCouponIfChanged(),
      (v) => couponChanged = v,
    ),
  ]);

  if (feedChanged) container.invalidate(feedProvider);
  if (categoriesChanged) container.invalidate(categoriesProvider);
  if (tagsChanged) container.invalidate(tagsProvider);
  if (weeksChanged) container.invalidate(limitedWeeksProvider);
  if (couponChanged) container.invalidate(couponProvider);
}

/// 記事一覧の配信をまとめて取り直す（[refreshHomeLists] と同じ作り）。
Future<void> refreshArchiveLists(ProviderContainer container) async {
  final articles = container.read(articleRepositoryProvider);

  var indexChanged = false;
  var categoriesChanged = false;
  var tagsChanged = false;

  Future<void> run(Future<bool> task, void Function(bool) store) async {
    try {
      store(await task);
    } on Object {
      // 取れなかった物は貼り直さない（前に出ていた値をそのまま残す）
    }
  }

  await Future.wait([
    run(articles.refreshArticleIndex(), (v) => indexChanged = v),
    run(articles.refreshCategories(), (v) => categoriesChanged = v),
    run(articles.refreshTags(), (v) => tagsChanged = v),
  ]);

  if (indexChanged) container.invalidate(articleIndexProvider);
  if (categoriesChanged) container.invalidate(categoriesProvider);
  if (tagsChanged) container.invalidate(tagsProvider);
}
