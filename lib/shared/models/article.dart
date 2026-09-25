import 'package:tonsoku/shared/models/article_meta.dart';

/// 記事 1 本（`articles/{slug}.json`）。一覧のメタに本文と動画などが付いた形。
///
/// **gyumesy は md（フロントマター ＋ 本文）で配っていたが、とん速は JSON 1 枚。**
/// メタの鍵は一覧（`articles/feed.json`）と同じなので [ArticleMeta] でそのまま読み、
/// 本体にしか無い鍵だけをここで読む。
///
/// **一覧に無い記事でも本体だけで画面を組み立てられる**（関連記事・後継記事・
/// 通知から直接開いた記事）。gyumesy の実測で、関連記事の参照の 46% が
/// 一覧（最新 200 件）の外にあった。
class Article {
  const Article({
    required this.meta,
    required this.content,
    this.videos = const [],
    this.tiktok,
    this.translationStage,
  });

  factory Article.fromJson(Map<String, dynamic> json) => Article(
    meta: ArticleMeta.fromJson(json),
    content: json['content'] is String ? json['content'] as String : '',
    videos: _videos(json['videos']),
    tiktok: ArticleTikTok.tryParse(json['tiktok']),
    translationStage: json['translation_stage'] as String?,
  );

  final ArticleMeta meta;

  /// 本文（Markdown）。表・画像・外部リンクを含む。**HTML は入らない**
  /// （web は `html: false` で描いている。本文に公式サイトと X から採った文字列が
  /// 入るため）。
  final String content;

  /// X のポストに付いていた動画。**無ければ空配列**。
  final List<ArticleVideo> videos;

  /// 記事の元になった TikTok の投稿。**TikTok 起点でない記事は null**。
  final ArticleTikTok? tiktok;

  /// 翻訳の段。**ロケール別の面にだけ現れる**（日本語の配信には鍵ごと無い）。
  /// `provisional` は訳語辞書から作った仮訳で、読み手に「参考訳です」と断るために
  /// 配られている（web の `models/article.ts`）。
  final String? translationStage;

  bool get isProvisionalTranslation => translationStage == 'provisional';

  /// **1 本ずつ見て、揃わないものだけを落とす。** 配信側でも `poster` と寸法は
  /// 必須（揃わない動画は配らない、と web と合意済み）だが、1 本崩れたために
  /// 記事ごと開けなくなるより、その 1 本が出ないほうが軽い。
  static List<ArticleVideo> _videos(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .map(ArticleVideo.tryParse)
        .whereType<ArticleVideo>()
        .toList(growable: false);
  }
}

/// 記事に添える動画（X のポストの添付）。**配信元は自前の R2**。
class ArticleVideo {
  const ArticleVideo({
    required this.url,
    required this.poster,
    required this.width,
    required this.height,
  });

  /// 再生前に出す静止画。**必須**（無いと真っ黒の箱になる）
  final String poster;
  final String url;

  /// 実寸。**必須**（無いと読み込み前に箱が潰れ、下の要素が押し下がる）
  final int width;
  final int height;

  double get aspectRatio => width / height;

  static ArticleVideo? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final url = raw['url'];
    final poster = raw['poster'];
    final width = raw['width'];
    final height = raw['height'];
    if (url is! String || url.isEmpty) return null;
    if (poster is! String || poster.isEmpty) return null;
    if (width is! num || width <= 0 || height is! num || height <= 0) {
      return null;
    }
    return ArticleVideo(
      url: url,
      poster: poster,
      width: width.toInt(),
      height: height.toInt(),
    );
  }
}

/// 記事の元になった TikTok の投稿。
///
/// **`kind` は「読み手が何を出すか」**（配信側がこちらの出し分けを名前にして
/// 渡している）。web の `models/article.ts` の `ArticleTikTok` が正:
///
/// | | 何が入っているか | 足すもの |
/// |---|---|---|
/// | `photo` | 本文に絵が並んでいる | 無し |
/// | `video` | `embed_url` と `poster` が必ず non-null | ポスターから開く導線 |
/// | `link` | 入口（`post_url`）だけ | 無し |
///
/// **`photo` と `link` で何も足さないのは、引用元を記事ヘッダーが既に出しているから。**
/// **知らない `kind` は何も出さない**（配信と合意済み。既定の安全側が同じ）。
class ArticleTikTok {
  const ArticleTikTok({required this.kind, required this.postUrl, this.poster});

  final String kind;

  /// 投稿そのものの URL。**どの `kind` でも non-null**
  final String postUrl;

  /// 押される前に出す静止画。`video` は必ず持つ
  final String? poster;

  /// 動画として導線を出すか。**`poster` まで揃った時だけ**（揃わない回は
  /// `link` と同じく何も足さない）。
  bool get isPlayableVideo =>
      kind == 'video' && (poster?.isNotEmpty ?? false) && postUrl.isNotEmpty;

  static ArticleTikTok? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final kind = raw['kind'];
    final postUrl = raw['post_url'];
    if (kind is! String || postUrl is! String) return null;
    final poster = raw['poster'];
    return ArticleTikTok(
      kind: kind,
      postUrl: postUrl,
      poster: poster is String ? poster : null,
    );
  }
}
