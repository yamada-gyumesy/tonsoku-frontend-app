import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

import 'package:tonsoku/core/theme/app_colors.dart';
import 'package:tonsoku/features/article/presentation/widgets/external_link_icon.dart';

/// 本文・表のリンクを開く。**http(s) 以外は開かない**（web の `safeExternalUrl`。
/// 配信の URL はこちらの管理下に無い）。
void openArticleLink(String? href) {
  final uri = href == null ? null : Uri.tryParse(href);
  if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) return;
  launchUrl(uri, mode: LaunchMode.inAppBrowserView);
}

/// 本文の Markdown 部分。**web の `src/assets/styles/markdown.css` を移したもの。**
///
/// 組みは gyumesy-frontend-app の `ArticleMarkdown` を写し、**色と寸法を
/// とん速の `markdown.css` に合わせ直した**（gyumesy のピンク・セカンダリの青・
/// 斜体の引用はとん速に無い）。
///
/// 実データ 36 本（2026-09-25）で使われている記法は `##` 見出し（36 本）・
/// 表（34 本）・リンク（16 本）・リスト（9 本）・`###`（4 本）・強調（4 本）・
/// 引用（1 本）・番号付きリスト（1 本）。画像は `ArticleBodyParser` が切り出す。
class ArticleMarkdown extends StatelessWidget {
  const ArticleMarkdown({required this.markdown, super.key});

  final String markdown;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // 本文は 16px / 行の高さ 2（web の `.co-article-markdown`）。**行間を詰めないこと**
    // ——長文を読ませる画面で、web と同じ間隔にしないと同じ記事が別物の密度に見える
    final body = TextStyle(fontSize: 16, height: 2, color: colors.text);

    // 本文の http リンクの後ろに外部リンクの記号（web の `a[href^="http"]::after`）
    final links = ExternalLinks.mark(markdown);

    return MarkdownBody(
      data: links.markdown,
      selectable: false,
      onTapLink: (text, href, title) => openArticleLink(href),
      inlineSyntaxes: [ExternalLinkIconSyntax()],
      // 見出しは枠線を持つので、スタイルシートでは表現できない
      builders: {
        'h2': _HeadingBuilder.h2(colors),
        'h3': _HeadingBuilder.h3(colors),
        ExternalLinkIconSyntax.tag: ExternalLinkIconBuilder(
          hrefs: links.hrefs,
          color: colors.primaryText,
          onTap: openArticleLink,
        ),
      },
      // **行の中身は触らず、記号だけ差し替える**（gyumesy が `'li'` の builder で
      // 太字もリンクも番号も消したのを踏まない）
      bulletBuilder: (parameters) =>
          _Bullet(parameters: parameters, color: colors.text),
      styleSheet: MarkdownStyleSheet(
        p: body,
        // web の `p { margin: 0 0 1.875rem }`
        pPadding: const EdgeInsets.only(bottom: 30),
        // **本文に h1 は来ない**（タイトルは記事ヘッダーが出している）。来た時に
        // 本文の見出しと役割が違うことが分かるよう、web と同じく中央寄せにする
        h1: TextStyle(
          fontSize: 24,
          height: 1.5,
          letterSpacing: 24 * 0.04,
          fontWeight: FontWeight.bold,
          color: colors.text,
        ),
        h1Align: WrapAlignment.center,
        h1Padding: const EdgeInsets.only(bottom: 24),
        // h2 / h3 は builders が描くので、ここでの指定は効かない
        // **リンクは地の上に置く赤（`primaryText`）**。塗りの `primary` は
        // ダークで基準に届かない（`AppColors.primary`）
        a: TextStyle(
          color: colors.primaryText,
          decoration: TextDecoration.underline,
          decorationColor: colors.primaryText,
        ),
        strong: const TextStyle(fontWeight: FontWeight.w700),
        listBullet: body,
        // web の `padding-left: 1.25rem`
        listIndent: 20,
        listBulletPadding: EdgeInsets.zero,
        // 段落や見出しの間隔はそれぞれの padding が持つので、ここでは足さない
        blockSpacing: 0,
        // 引用。**斜体にしない**（web の `blockquote` は副テキストの色だけ。
        // gyumesy は X の投稿本文を斜体で区別していた）
        blockquote: body.copyWith(color: colors.textSub),
        // web は引用の外にも `margin: 2rem 0` を持つが、この器は外側の余白を
        // 表現できない（gyumesy の注記と同じ事情。直前の段落の 30 が上に空く）
        blockquotePadding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
        blockquoteDecoration: BoxDecoration(
          color: colors.bg,
          border: Border(left: BorderSide(color: colors.primaryText, width: 4)),
          borderRadius: const BorderRadius.horizontal(
            right: Radius.circular(8),
          ),
        ),
        // 表。**本文の直下の表は `ArticleTable` が描く**（ここへは来ない。列の幅を
        // パッケージと `Table` に任せると web と食い違う理由はそちら）。ここの指定は
        // リストや引用の中に表が入った時だけ効く。**`IntrinsicColumnWidth` /
        // `FixedColumnWidth` を渡さないこと** ―― パッケージはその 2 つの時だけ
        // 表を横スクロールの中に置き、1 セルも折り返さなくなる
        tableColumnWidth: const FlexColumnWidth(),
        tableHead: TextStyle(
          fontSize: 14,
          height: 1.5,
          fontWeight: FontWeight.bold,
          color: colors.text,
        ),
        tableBody: TextStyle(fontSize: 14, height: 1.5, color: colors.text),
        tableBorder: TableBorder.all(color: colors.border),
        // **見出し行の地は `hover`**、**偶数行の縞は `bg`**（web の `thead` /
        // `tbody tr:nth-child(even)`）。どちらも面（`surface`）から分離しているので、
        // テーマ別の上書きは要らない（web の注記）
        tableHeadCellsDecoration: BoxDecoration(color: colors.hover),
        tableCellsDecoration: BoxDecoration(color: colors.bg),
        // web は `th, td { text-align: left }`。既定は中央寄せになる
        tableHeadAlign: TextAlign.left,
        tableCellsPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(top: BorderSide(color: colors.border)),
        ),
        // インラインのコード。**`code` は `TextStyle` なので余白も角丸も
        // 表現できない**（地色だけ載る。gyumesy と同じ制約）
        code: TextStyle(fontSize: 14, height: 1.6, backgroundColor: colors.bg),
        codeblockPadding: const EdgeInsets.all(16),
        codeblockDecoration: BoxDecoration(
          color: colors.bg,
          borderRadius: BorderRadius.circular(8),
        ),
        codeblockAlign: WrapAlignment.start,
      ),
    );
  }
}

/// 箇条書きの記号。web は `list-style: none` + `::before` で「・」を出している
/// （既定の中黒より字面が大きく、日本語の本文に合う）。番号付きは `1.` のまま。
///
/// **「・」は日本語の画面だけ。** 英語・中国語は `•`。「・」は片仮名の中点
/// （U+30FB）で、英語・中国語の画面に日本語を出さないのはユーザーの決定
/// （Issue #35。web はまだ全言語で「・」）。
///
/// **番号は常に 1 から振る。** `bulletBuilder` は `<ol start="N">` を渡してこない
/// ので、途中の番号から始まるリストは 1 から振り直す。本番の記事は 1 始まりしか
/// 無いので現状は問題にならないが、配信側が途中番号を使い始めたらここを直す。
class _Bullet extends StatelessWidget {
  const _Bullet({required this.parameters, required this.color});

  final MarkdownBulletParameters parameters;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final label = switch (parameters.style) {
      BulletStyle.orderedList => '${parameters.index + 1}.',
      BulletStyle.unorderedList =>
        Localizations.localeOf(context).languageCode == 'ja' ? '・' : '•',
    };

    return Text(label, style: TextStyle(fontSize: 16, height: 2, color: color));
  }
}

/// 見出し。**枠線が意味を持つ**（web の `markdown.css`）。
/// - `h2`: 下に地の上の赤（`primaryText`）の 2px。構造を示す境界なので 3:1 を
///   満たす色を使う（塗りの `primary` はダークで届かない）
/// - `h3`: 左に茶の 3px。h2 の中の小見出しで、格を一段落とす
class _HeadingBuilder extends MarkdownElementBuilder {
  _HeadingBuilder({
    required this.colors,
    required this.fontSize,
    required this.marginTop,
    required this.marginBottom,
    required this.underline,
  });

  /// **上の余白は web の値から直前の段落の余白（30）を引いてある。** web は
  /// 縦の余白が相殺される（段落の下 30 と h2 の上 45 → 45）が、Flutter は
  /// 足し算になるので、そのまま写すと見出しの前だけ 75 空く。
  factory _HeadingBuilder.h2(AppColors colors) => _HeadingBuilder(
    colors: colors,
    fontSize: 18,
    marginTop: 45 - 30,
    marginBottom: 16,
    underline: true,
  );

  factory _HeadingBuilder.h3(AppColors colors) => _HeadingBuilder(
    colors: colors,
    fontSize: 16,
    // web の 30 から段落の 30 を引いたもの（理由は h2）
    marginTop: 30 - 30,
    marginBottom: 12,
    underline: false,
  );

  final AppColors colors;
  final double fontSize;
  final double marginTop;
  final double marginBottom;
  final bool underline;

  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final text = Text(
      element.textContent,
      style: TextStyle(
        fontSize: fontSize,
        height: 1.5,
        // web は font-feature-settings: "palt" とあわせて字間を 0.04em 空けている
        letterSpacing: fontSize * 0.04,
        fontWeight: FontWeight.bold,
        color: colors.text,
      ),
    );

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: marginTop, bottom: marginBottom),
      padding: underline
          ? const EdgeInsets.only(bottom: 8)
          : const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        border: underline
            ? Border(bottom: BorderSide(color: colors.primaryText, width: 2))
            : Border(left: BorderSide(color: colors.brown, width: 3)),
      ),
      child: text,
    );
  }
}
