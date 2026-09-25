import 'package:tonsoku/core/i18n/app_locale.dart';

/// 配信データ（R2 = cdn.ton-soku.com）のパスを組み立てる。
///
/// **ロケールごとの名前空間の差をここだけに閉じ込める。** 日本語は現行パスのまま、
/// 追加ロケールは `i18n/{locale}/` 配下という規則で、Web と配信側の契約になっている。
/// 呼び出し側にこの分岐を書かせると、ロケールを増やした時に取りこぼす。
///
/// **gyumesy と違い、記事本体も名前空間に従う**（`i18n/en/articles/{slug}.json`）。
/// gyumesy は本文の md を日本語と同じディレクトリに `index.{locale}.md` で置く
/// 例外を持つが、とん速の配信は記事を JSON 1 枚で出しており、例外が無い。
///
/// Web にはもう 1 つ `articles/{slug}/x.json`（X の返信。日本語のみ）があるが、
/// アプリは X の返信を持たない方針なので取得しない（gyumesy と同じく UGC 判定を
/// 避けるため）。
class CdnPaths {
  const CdnPaths(this.locale);

  final AppLocale locale;

  /// ロケール別の名前空間プレフィックス。日本語は空。
  String get _ns => locale.isDefault ? '' : 'i18n/${locale.code}/';

  // ── 一覧系 ────────────────────────────────────────
  // これらは翻訳 0 件でも空配列で必ず 200 が返る（配信側との契約）。
  // 404 を正常系として扱ってよいのは coupon と legal だけ。

  /// 最新 200 件（配列）。アプリの記事一覧はこれを使う。
  ///
  /// **`articles/index.json` は全件でオブジェクトに包まれている**
  /// （`{generated_at, count, articles}`）。web はこちらを読んでいるが、
  /// アプリは gyumesy と同じく最新 200 件で足りる。
  String get feed => '${_ns}articles/feed.json';

  /// 全記事（`{generated_at, count, articles}`）。
  ///
  /// **ランキングが使う**（配信されるのは順位と slug だけなので、記事メタを
  /// ここから引く）。一覧の画面では使わない。
  String get articleIndex => '${_ns}articles/index.json';

  String get categories => '${_ns}categories.json';
  String get tags => '${_ns}tags.json';
  String get calendar => '${_ns}calendar.json';
  String get ranking => '${_ns}ranking.json';
  String get recommendedMenu => '${_ns}recommended-menu.json';

  /// 店舗限定の週ごとの状態（新しい順に 12 週）。ホームの週カード。
  String get limitedWeeks => '${_ns}limited/weeks.json';

  /// カテゴリ別の記事一覧。feed.json をクライアントで絞ると、カテゴリによっては
  /// 200 件中の数件しか出ないのでこちらを使う（gyumesy の判断）。
  ///
  /// **2026-09-25 時点、とん速は日本語にしか出ていない**（`i18n/en/` `i18n/zh/` は
  /// 4 カテゴリとも 404）。一覧系は「翻訳 0 件でも空配列で 200」の契約なので、
  /// 配信側に確かめてから使うこと（ホームの Issue で扱う）。
  String categoryArticles(String categoryId) =>
      '${_ns}categories/$categoryId/articles.json';

  // ── 404 がありうるもの ────────────────────────────

  /// クーポン・還元。
  String get coupon => '${_ns}coupon.json';

  /// 法務ページ。アプリはこれらを web で表示する方針なので通常は取得しない。
  String legal(String page) => '${_ns}legal/$page.md';

  // ── 記事本体 ───────────────────────────────────────

  /// 記事 1 本（メタ ＋ `content` の Markdown ＋ 動画など）。
  String article(String slug) => '${_ns}articles/$slug.json';
}
