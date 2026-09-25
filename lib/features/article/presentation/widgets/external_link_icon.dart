import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;

/// 本文のリンクの後ろに付ける外部リンクの記号。web の
/// `.co-article-markdown a[href^="http"]::after`（`markdown.css`）。
///
/// **外部リンクであることを示すのはフロントの仕事**（配信の本文には矢印も
/// 絵文字も入っていない。web の切り分け）。**図のキャプションには付けない**
/// （注記の中で矢印が出ると、そこだけ本文より強く見える。web と同じ。
/// キャプションは `ArticleFigure` が描くのでここを通らない）。
///
/// ## 組み方
///
/// この Markdown の器はインラインの後ろに部品を足す口を持たない。`'a'` の
/// builder で描き直すと、リンクの押下と子の強調を自前で持ち直すことになる。
/// そこで**リンクの文字の末尾に印（私用領域の字）を差し込み**（[mark]）、
/// 印だけを [ExternalLinkIconSyntax] で拾って [ExternalLinkIconBuilder] が
/// 記号に差し替える。リンクそのものは器の既定のまま描かれる。
///
/// 印は `\uE000<番号>\uE001`。番号は [ExternalLinks.hrefs] の添字で、記号を
/// 押した時の行き先を引く（記号も web ではリンクの一部で、押せる）。
class ExternalLinks {
  const ExternalLinks._(this.markdown, this.hrefs);

  /// 印を差し込んだ Markdown。
  final String markdown;

  /// 印の番号 → 行き先。
  final List<String> hrefs;

  static const open = '\uE000';
  static const close = '\uE001';

  /// http(s) のリンク（画像のリンクは除く）。
  static final _link = RegExp(r'(?<!!)\[([^\]]+)\]\((https?://[^)\s]+)\)');

  /// リンクの文字の末尾に印を差し込む。
  ///
  /// **記号の前では折り返さない**（記号の空きが NO-BREAK SPACE）。web は本文では
  /// 記号の前で折り返しうるが、記号だけが行頭に残るのは読みにくいだけなので揃えない。
  static ExternalLinks mark(String markdown) {
    final hrefs = <String>[];
    final marked = markdown.replaceAllMapped(_link, (m) {
      final index = hrefs.length;
      hrefs.add(m.group(2)!);
      return '[${m.group(1)}$open$index$close](${m.group(2)})';
    });
    return ExternalLinks._(marked, hrefs);
  }

  /// 幅を測るための文字で、印を 1 字（[open]）に縮める。**その字のところに
  /// 記号の字（[ExternalLinkIconBuilder.span]）を置いて測る**のは測る側
  /// （`ArticleTable`）。私用領域の字のまま測ると豆腐の幅になる。
  static String collapse(String text) =>
      text.replaceAll(RegExp('$open\\d+$close'), open);
}

/// 印を拾って `extlink` の要素にする。
class ExternalLinkIconSyntax extends md.InlineSyntax {
  ExternalLinkIconSyntax()
    : super('${ExternalLinks.open}(\\d+)${ExternalLinks.close}');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(
      md.Element.empty('extlink')..attributes['i'] = match.group(1)!,
    );
    return true;
  }

  /// builders の鍵。
  static const tag = 'extlink';
}

/// `extlink` を記号に差し替える。
///
/// ## 記号は「字」で描く（`WidgetSpan` にしない）
///
/// **`WidgetSpan` は前に WORD JOINER を置いても、その手前で折り返される**
/// （組版が置き換え部品の前後を常に折り返しの機会にする。実測: `xx abcd\u2060` ＋
/// 部品を 1 行に収まらない幅で組むと、部品だけが次の行へ落ちた）。表のセルで
/// 記号だけが次の行に残るのは web が `td a { white-space: nowrap }` で防いでいる
/// 形そのもので、ここでは防げない。**アイコンの書体（MaterialIcons）の字**なら
/// 普通の文字として組まれ、直前の字から離れない。
///
/// 絵は Material の `open_in_new`（web の本文は feather の `external-link` を
/// mask で描いているが、web のクーポン一覧のチップはこの絵。意味は同じ）。
class ExternalLinkIconBuilder extends MarkdownElementBuilder {
  ExternalLinkIconBuilder({
    required this.hrefs,
    required this.color,
    required this.onTap,
  });

  final List<String> hrefs;
  final Color color;
  final ValueChanged<String> onTap;

  /// 記号の字。**`Icons.open_in_new` を参照して置く**（アイコンの書体は使われて
  /// いる字だけ残して削られるので、コードポイントを直に書くとリリースで消える）。
  static final _glyph = String.fromCharCode(Icons.open_in_new.codePoint);

  /// 記号の前の空き（web の `margin-left: 0.2em`）を NO-BREAK SPACE で取る。
  /// 字の幅は書体で違う（Klee One で 0.35em）ので、小さく組んで 0.2em 前後にする。
  /// **NO-BREAK SPACE なので記号の前では折り返さない**
  static const _gapScale = 0.6;

  /// 記号の字（空きを含む）。表の幅を測る側（`ArticleTable`）も同じものを測る。
  static InlineSpan span(
    TextStyle base, {
    required Color color,
    GestureRecognizer? recognizer,
  }) {
    final fontSize = base.fontSize ?? 16;
    return TextSpan(
      recognizer: recognizer,
      children: [
        TextSpan(
          text: '\u00A0',
          // **空きに下線を引かない**（web の記号は下線の外。引くとリンクの
          // 下線が記号の手前まで伸びて見える）
          style: base.copyWith(
            fontSize: fontSize * _gapScale,
            decoration: TextDecoration.none,
          ),
        ),
        TextSpan(
          text: _glyph,
          style: base.copyWith(
            // web の `width: 0.75em`
            fontSize: fontSize * 0.75,
            fontFamily: Icons.open_in_new.fontFamily,
            package: Icons.open_in_new.fontPackage,
            // **リンクと同じ色**（web は `currentColor`）。下線は引かない
            color: color,
            decoration: TextDecoration.none,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final href = hrefs.elementAtOrNull(
      int.tryParse(element.attributes['i'] ?? '') ?? -1,
    );
    // **記号も押せる**（web ではリンクの一部）。読み上げはリンクの文字が担う
    // **`Text.rich` で返す**（器が前後の文字と 1 つの段落にまとめる）
    return Text.rich(
      span(
        parentStyle ?? const TextStyle(),
        color: color,
        recognizer: href == null
            ? null
            : (TapGestureRecognizer()..onTap = () => onTap(href)),
      ),
    );
  }
}
