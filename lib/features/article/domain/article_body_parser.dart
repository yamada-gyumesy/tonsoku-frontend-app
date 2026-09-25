import 'package:tonsoku/features/article/domain/article_body.dart';

/// 記事本文（Markdown）を [ArticleBlock] の並びに起こす。
///
/// **狙うのは「画像だけの段落」＋「直後の強調だけの段落」の並び。** 配信は画像の直後に
/// `*引用元: [名前](URL)*` の 1 段落で出所を書く（web の `utils/markdown.ts` の
/// 組み替えと同じ条件。配信がこの形でしか斜体を使っていない）。
///
/// - **強調だけの段落が続かない画像も [FigureBlock] にする**（注記なし）。web は
///   組み替えずに `<img>` のまま出すが、見た目（中央・角丸・最大幅）は同じなので、
///   描く部品を 1 つにまとめた
/// - **単独の斜体の段落は組み替えない** —— あれは注記ではない
///
/// **形が変わっても例外を投げず、読める範囲で返す。** 記事が 1 本崩れた形で
/// 配信された時に、画面が開けなくなるより崩れて出るほうがましなため
/// （gyumesy-frontend-app の `ArticleBodyParser` と同じ方針）。
abstract final class ArticleBodyParser {
  /// 段落の区切り（空行）。**配信の本文は CRLF のことがある**（gyumesy の本番は
  /// 全件 CRLF だった）ので、先に LF へ寄せてから割る。
  static final _paragraphBreak = RegExp(r'\n[ \t]*\n+');

  static final _imageOnly = RegExp(r'^!\[([^\]]*)\]\(\s*(\S+?)\s*\)$');

  /// 強調（斜体）だけの段落。`**太字**` は含めない。
  static final _emphasisOnly = RegExp(
    r'^\*(?!\*)(.+?)(?<!\*)\*$',
    dotAll: true,
  );

  static final _link = RegExp(r'\[([^\]]+)\]\(\s*(\S+?)\s*\)');

  /// 表の区切り行（`|---|:---:|`）。
  static final _tableDelimiter = RegExp(
    r'^\|?\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?\s*)*\|?\s*$',
  );

  /// 表だけの段落か。**配信の表は必ず `|` で始まる行だけで組まれている**
  /// （36 本・34 本で確認）。2 行目が区切り行であることまで見る
  static bool _isTable(String paragraph) {
    final lines = paragraph.split('\n');
    return lines.length >= 2 &&
        lines.every((l) => l.trimLeft().startsWith('|')) &&
        _tableDelimiter.hasMatch(lines[1].trim());
  }

  static List<ArticleBlock> parse(String content) {
    final paragraphs = content
        .replaceAll('\r\n', '\n')
        .split(_paragraphBreak)
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList(growable: false);

    final blocks = <ArticleBlock>[];
    final pending = <String>[];

    void flush() {
      if (pending.isEmpty) return;
      blocks.add(MarkdownBlock(pending.join('\n\n')));
      pending.clear();
    }

    for (var i = 0; i < paragraphs.length; i++) {
      if (_isTable(paragraphs[i])) {
        flush();
        blocks.add(TableBlock(paragraphs[i]));
        continue;
      }
      final image = _imageOnly.firstMatch(paragraphs[i]);
      if (image == null) {
        pending.add(paragraphs[i]);
        continue;
      }

      flush();
      final next = i + 1 < paragraphs.length ? paragraphs[i + 1] : null;
      final caption = next == null ? null : _emphasisOnly.firstMatch(next);
      if (caption != null) i++;
      blocks.add(
        _figure(
          url: image.group(2)!,
          alt: image.group(1)!,
          caption: caption?.group(1)?.trim() ?? '',
        ),
      );
    }
    flush();

    return blocks;
  }

  static FigureBlock _figure({
    required String url,
    required String alt,
    required String caption,
  }) {
    final link = _link.firstMatch(caption);
    return FigureBlock(
      url: url,
      alt: alt,
      // リンク部分を取り除いた残り（実データではすべて `引用元:`）。
      // リンクを持たない注記もあるので、その場合は全文が残る
      captionText: caption
          .replaceAll(_link, '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim(),
      captionLinkText: link?.group(1)?.trim() ?? '',
      captionUrl: link?.group(2) ?? '',
    );
  }
}
