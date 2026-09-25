import 'package:freezed_annotation/freezed_annotation.dart';

part 'article_meta.freezed.dart';
part 'article_meta.g.dart';

/// 記事のメタデータ。`articles/feed.json` の各要素の形。
///
/// 配信側のスキーマは tonsoku-backend-batch の `schema/article-meta.json`。
/// **必須項目だけを非 null にし、残りは既定値を持たせる**——配信側が項目を
/// 足した時にアプリが落ちないようにする（gyumesy-frontend-app と同じ）。
///
/// **とん速の配信は null を出す鍵がある**（`description` / `editor_comment` /
/// `thumbnail` / `thumbnail_sm` / `thumbnail_source`）。json_serializable の
/// `defaultValue` は**鍵が無い時だけでなく null の時にも効く**ので、`@Default('')`
/// で空文字に寄せてある（画面側で null と空文字を二重に見なくて済む）。
@freezed
abstract class ArticleMeta with _$ArticleMeta {
  const factory ArticleMeta({
    required String slug,
    required String title,
    @Default(<String>[]) List<String> categories,
    @Default(<String>[]) List<String> tags,
    @Default(true) bool published,

    /// 初回配信の時刻。**契約は null を許すが、配信に載るのは配信済みの記事だけ**
    /// なので実際には必ず入る（web の `models/article.ts` も同じ理由で必須に
    /// 狭めている）
    @JsonKey(name: 'created_at') required DateTime createdAt,

    /// **記事の編集時刻ではなく DB 行の更新時刻。** `created_at` より前の値に
    /// なりうる（web の `models/article.ts` に経緯）。「更新された」の表示に使わないこと
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @Default('') String description,
    @JsonKey(name: 'editor_comment') @Default('') String editorComment,

    /// ひとことに添えるのや子の表情（`normal` / `smile` / `angry` / `confused`）。
    /// **`editor_comment` が null の記事はこれも null**（配信側が揃えている）。
    /// 知らない値の扱いは表示側が持つ（web の `models/expression.ts` と同じく
    /// `normal` に倒す）
    String? expression,
    @Default('') String thumbnail,

    /// 一覧用の幅 320 の webp。**配信が URL をくれる**（gyumesy は `-sm` を
    /// 命名規則から導出していたが、とん速は鍵で持っている）
    @JsonKey(name: 'thumbnail_sm') @Default('') String thumbnailSm,
    @JsonKey(name: 'thumbnail_source') @Default('') String thumbnailSource,
    @JsonKey(name: 'source_url') @Default('') String sourceUrl,

    /// 記事が生まれたきっかけ（`limited-added` / `news-post` など）。
    /// **enum にせず文字列で受ける** —— 値が増えた時に落とさないため
    @JsonKey(name: 'trigger_type') @Default('') String triggerType,
    @JsonKey(name: 'related_articles')
    @Default(<String>[])
    List<String> relatedArticles,
    @JsonKey(name: 'series_key') String? seriesKey,
    @JsonKey(name: 'successor_slug') String? successorSlug,
  }) = _ArticleMeta;

  const ArticleMeta._();

  factory ArticleMeta.fromJson(Map<String, dynamic> json) =>
      _$ArticleMetaFromJson(json);

  /// 一覧用の小さいサムネイル。**無ければ原寸に落とす**（web の `srcset` と同じく、
  /// 小さい版が無い記事でも絵は出す）。原寸は 800px 幅なので、一覧では必ずこちらを使う。
  String get thumbnailSmall => thumbnailSm.isNotEmpty ? thumbnailSm : thumbnail;

  /// **サムネイルの無い記事がある**（店舗の開店など、絵を採れない出来事）。
  /// `ogp_image` は SNS 用の PNG で、アプリでは使わない。
  bool get hasThumbnail => thumbnail.isNotEmpty;
}
