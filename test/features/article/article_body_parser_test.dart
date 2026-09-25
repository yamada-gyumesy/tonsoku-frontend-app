import 'package:flutter_test/flutter_test.dart';
import 'package:tonsoku/features/article/domain/article_body.dart';
import 'package:tonsoku/features/article/domain/article_body_parser.dart';

void main() {
  test('画像と直後の強調だけの段落を 1 つの figure にまとめる', () {
    // 本番の配信の形（articles/z7uell.json・2026-09-25）
    const content =
        '![松のや公式Xのポスト](https://cdn.ton-soku.com/articles/z7uell/x-post.webp)\n\n'
        '*引用元: [松のや公式X](https://x.com/matsu_noya/status/2103063728505991350)*\n\n'
        '松のやの公式Xアカウントが告知した。\n\n'
        '## 見出し\n\n'
        '本文。';
    final blocks = ArticleBodyParser.parse(content);

    expect(blocks, hasLength(2));
    final figure = blocks[0] as FigureBlock;
    expect(figure.url, 'https://cdn.ton-soku.com/articles/z7uell/x-post.webp');
    expect(figure.alt, '松のや公式Xのポスト');
    expect(figure.captionText, '引用元:');
    expect(figure.captionLinkText, '松のや公式X');
    expect(
      figure.captionUrl,
      'https://x.com/matsu_noya/status/2103063728505991350',
    );
    expect(
      (blocks[1] as MarkdownBlock).markdown,
      '松のやの公式Xアカウントが告知した。\n\n## 見出し\n\n本文。',
    );
  });

  test('リンクを持たない注記も読める（引用元: 松屋フーズ公式アプリ）', () {
    final blocks = ArticleBodyParser.parse(
      '![アプリの画面](https://cdn.ton-soku.com/a.webp)\n\n*引用元: 松屋フーズ公式アプリ*',
    );
    final figure = blocks.single as FigureBlock;
    expect(figure.captionText, '引用元: 松屋フーズ公式アプリ');
    expect(figure.hasLink, isFalse);
    expect(figure.hasCaption, isTrue);
  });

  test('注記の続かない画像も figure にする（注記なし）', () {
    final blocks = ArticleBodyParser.parse(
      '前の段落\n\n![絵](https://cdn.ton-soku.com/a.webp)\n\n後の段落',
    );
    expect(blocks, hasLength(3));
    expect((blocks[1] as FigureBlock).hasCaption, isFalse);
    expect((blocks[2] as MarkdownBlock).markdown, '後の段落');
  });

  test('単独の斜体の段落と太字の段落は組み替えない', () {
    final blocks = ArticleBodyParser.parse(
      '*単独の斜体*\n\n![絵](https://x/a.webp)\n\n**太字だけの段落**',
    );
    expect(blocks, hasLength(3));
    expect((blocks[0] as MarkdownBlock).markdown, '*単独の斜体*');
    expect((blocks[1] as FigureBlock).hasCaption, isFalse);
    expect((blocks[2] as MarkdownBlock).markdown, '**太字だけの段落**');
  });

  test('CRLF の本文も同じに読める', () {
    final blocks = ArticleBodyParser.parse(
      '![絵](https://x/a.webp)\r\n\r\n*引用元: 公式*\r\n\r\n本文',
    );
    expect(blocks, hasLength(2));
    expect((blocks[0] as FigureBlock).captionText, '引用元: 公式');
  });

  test('表は前後の段落から切り出して TableBlock にする', () {
    const table = '| a | b |\n|---|---|\n| 1 | 2 |';
    final blocks = ArticleBodyParser.parse('導入\n\n$table\n\n結び');
    expect(blocks, hasLength(3));
    expect((blocks[0] as MarkdownBlock).markdown, '導入');
    expect((blocks[1] as TableBlock).markdown, table);
    expect((blocks[2] as MarkdownBlock).markdown, '結び');
  });

  test('区切り行の無い | 始まりの段落は表にしない', () {
    final blocks = ArticleBodyParser.parse('| これは表ではない |');
    expect(blocks.single, isA<MarkdownBlock>());
  });
}
