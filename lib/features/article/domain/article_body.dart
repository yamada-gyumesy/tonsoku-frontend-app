/// 記事本文を構成するかたまり。
///
/// 本文は Markdown で、**画像はその出所の注記と組にして [FigureBlock] に切り出す**
/// （web の `utils/markdown.ts` がトークンを組み替えて `<figure>` にしているのと
/// 同じ切り分け）。Markdown レンダラに画像を任せると、画像と注記が**無関係な
/// 2 つの段落**になり、注記を画像に寄せる余白も付けられない。
sealed class ArticleBlock {
  const ArticleBlock();
}

/// そのまま Markdown として描画する部分。見出し・段落・表・引用・リスト。
class MarkdownBlock extends ArticleBlock {
  const MarkdownBlock(this.markdown);

  final String markdown;
}

/// 表（GFM のパイプ表）。**段落から切り出して描く**（`ArticleTable`）。
///
/// Markdown レンダラに任せると、表は**横スクロールの中に置かれて 1 セルも
/// 折り返さない**（web は幅に収まるよう本文のセルを折り返し、見出しだけで幅を
/// 超える時にだけ横に送る）。幅を決めるには表の外側で画面幅を知る必要があるので、
/// 表だけを別のかたまりにする。
class TableBlock extends ArticleBlock {
  const TableBlock(this.markdown);

  final String markdown;
}

/// 画像と、その出所。
class FigureBlock extends ArticleBlock {
  const FigureBlock({
    required this.url,
    this.alt = '',
    this.captionText = '',
    this.captionLinkText = '',
    this.captionUrl = '',
  });

  final String url;
  final String alt;

  /// 出所の注記のうちリンクでない部分（実データではすべて `引用元: `）。
  final String captionText;

  /// リンクの文字列（`松のや公式X(@matsu_noya)` など）。リンクが無い場合は空。
  final String captionLinkText;

  /// リンク先。**リンクを持たない注記が実在する**（`引用元: 松屋フーズ公式アプリ`）
  /// ので、空を想定すること。
  final String captionUrl;

  bool get hasCaption => captionText.isNotEmpty || captionLinkText.isNotEmpty;

  bool get hasLink => captionUrl.isNotEmpty && captionLinkText.isNotEmpty;
}
