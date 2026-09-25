import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:tonsoku/core/theme/app_colors.dart';

/// 本文の表。web の `markdown.css` の `table`:
///
/// ```css
/// table { width: fit-content; max-width: 100%; margin: 0 auto 1.5rem;
///         display: block; overflow-x: auto }
/// th { white-space: nowrap }
/// ```
///
/// - **中身が狭ければ中身の幅で、中央に置く**（`fit-content` ＋ `margin: auto`）
/// - **広ければ画面の幅に収まるよう本文のセルを折り返す**（見出しは折り返さない）
/// - **見出しや本文の最小幅だけで画面を超える時だけ、表を横に送る**
///   （`overflow-x: auto`）。その時は各列を最小の幅で組む
///
/// ## Markdown レンダラに表を任せない理由
///
/// パッケージは列の幅を `Table` に任せるが、それが 2 か所で web と食い違う:
///
/// - **Klee One で組んだ漢字の連なりを「折り返せない 1 語」と報告する。**
///   `京都府宇治市宇治弐番96-1` の最小幅が全体の幅と同じになり（実測 170 / 170。
///   既定の書体だと 56）、住所の列が縮まず表が画面から切れた。実際の組版では
///   漢字の間で折り返せるので、報告だけが違う
/// - **縮め方が web と違う。** `Table` は足りない幅を列に均等に割り振るが、
///   ブラウザの表は「広げた幅 − 最小幅」に比例して配る
///
/// なので**列の幅はここで決め**（[columnWidths]）、`Table` には決めた幅を渡すだけにする。
/// セルの中身（リンク・太字）は `MarkdownBody` で描く。
///
/// **スクロールバーは出さない**（web も SP では出ない。一度パッケージ任せにして、
/// 余白の内側の変な位置に出ていた）。
class ArticleTable extends StatelessWidget {
  const ArticleTable({required this.markdown, super.key});

  final String markdown;

  /// セルの余白（web の `th, td { padding: 0.625rem 0.75rem }`）。
  static const cellPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 10);
  static const _border = 1.0;

  @override
  Widget build(BuildContext context) {
    final table = ParsedTable.parse(markdown);
    if (table == null) return const SizedBox.shrink();
    final colors = context.colors;
    final base = Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    // web の `table { font-size: 0.875rem; line-height: 1.5 }` と `thead { font-weight: 700 }`
    final body = base.copyWith(fontSize: 14, height: 1.5, color: colors.text);
    final head = body.copyWith(fontWeight: FontWeight.bold);
    final scaler = MediaQuery.textScalerOf(context);

    return Padding(
      // web の `margin: 0 auto 1.5rem`（下だけ 24）
      padding: const EdgeInsets.only(bottom: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final layout = columnWidths(
            table,
            available: constraints.maxWidth,
            measure: (text, {required bool header}) =>
                _measure(text, header ? head : body, scaler, header: header),
          );
          final rendered = _table(context, table, layout.widths, body, head);
          if (!layout.overflows) return Center(child: rendered);
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: rendered,
          );
        },
      ),
    );
  }

  Widget _table(
    BuildContext context,
    ParsedTable table,
    List<double> widths,
    TextStyle body,
    TextStyle head,
  ) {
    final colors = context.colors;
    Widget cell(String text, TextStyle style) => Padding(
      padding: cellPadding,
      child: MarkdownBody(
        data: text,
        styleSheet: MarkdownStyleSheet(
          p: style,
          pPadding: EdgeInsets.zero,
          strong: const TextStyle(fontWeight: FontWeight.w700),
          a: style.copyWith(
            color: colors.primaryText,
            decoration: TextDecoration.underline,
            decorationColor: colors.primaryText,
          ),
        ),
        onTapLink: (text, href, title) {
          final uri = href == null ? null : Uri.tryParse(href);
          if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) {
            return;
          }
          launchUrl(uri, mode: LaunchMode.inAppBrowserView);
        },
      ),
    );

    return Table(
      columnWidths: {
        for (final (i, w) in widths.indexed) i: FixedColumnWidth(w),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      border: TableBorder.all(color: colors.border),
      children: [
        // **見出し行の地は `hover`**（web の `thead`）
        TableRow(
          decoration: BoxDecoration(color: colors.hover),
          children: [for (final h in table.header) cell(h, head)],
        ),
        for (final (i, row) in table.rows.indexed)
          TableRow(
            // **偶数行に縞**（web の `tbody tr:nth-child(even)`。1 始まりで偶数）
            decoration: i.isOdd ? BoxDecoration(color: colors.bg) : null,
            children: [for (final c in row) cell(c, body)],
          ),
      ],
    );
  }

  /// セル 1 つぶんの幅（余白と罫を含む）。
  static ({double min, double max}) _measure(
    String markdown,
    TextStyle style,
    TextScaler scaler, {
    required bool header,
  }) {
    final plain = ParsedTable.plainText(markdown);
    double width(String s) {
      final painter = TextPainter(
        text: TextSpan(text: s, style: style),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final w = painter.width;
      painter.dispose();
      return w;
    }

    const extra = 12.0 * 2 + _border;
    final max = width(plain) + extra;
    // **見出しは折り返さない**（web の `th { white-space: nowrap }`）
    if (header) return (min: max, max: max);
    // **本文の最小幅は、折り返せない一続きのうち一番長いもの**（CSS の
    // `min-content`）。漢字・かなは 1 字ごとに、それ以外は空白で区切る
    final segments = ParsedTable.unbreakableSegments(plain);
    var min = 0.0;
    for (final segment in segments) {
      final w = width(segment);
      if (w > min) min = w;
    }
    return (min: min + extra, max: max);
  }
}

/// 列の幅を決めた結果。
class TableLayout {
  const TableLayout({required this.widths, required this.overflows});

  final List<double> widths;

  /// 最小の幅でも画面に収まらない（横に送る）。
  final bool overflows;
}

/// 列の幅を決める。**ブラウザの自動表レイアウトと同じ配り方**:
///
/// - 全列を広げた幅（`max-content`）で収まる → その幅（`fit-content`）
/// - 収まらないが最小幅（`min-content`）なら収まる → 最小幅に、余りを
///   「広げた幅 − 最小幅」に比例して配る
/// - 最小幅でも収まらない → 最小幅のまま横に送る
TableLayout columnWidths(
  ParsedTable table, {
  required double available,
  required ({double min, double max}) Function(
    String text, {
    required bool header,
  })
  measure,
}) {
  final columns = table.header.length;
  final mins = List.filled(columns, 0.0);
  final maxes = List.filled(columns, 0.0);
  void take(int x, ({double min, double max}) m) {
    if (m.min > mins[x]) mins[x] = m.min;
    if (m.max > maxes[x]) maxes[x] = m.max;
  }

  for (var x = 0; x < columns; x++) {
    take(x, measure(table.header[x], header: true));
    for (final row in table.rows) {
      take(x, measure(row[x], header: false));
    }
  }
  // 左端の罫のぶん
  final room = available - 1;
  final sumMax = maxes.fold(0.0, (a, b) => a + b);
  if (sumMax <= room) return TableLayout(widths: maxes, overflows: false);
  final sumMin = mins.fold(0.0, (a, b) => a + b);
  if (sumMin > room) return TableLayout(widths: mins, overflows: true);
  final spare = room - sumMin;
  final spread = sumMax - sumMin;
  return TableLayout(
    widths: [
      for (var x = 0; x < columns; x++)
        mins[x] + (spread == 0 ? 0 : spare * (maxes[x] - mins[x]) / spread),
    ],
    overflows: false,
  );
}

/// GFM のパイプ表を見出しと行に分けたもの。
class ParsedTable {
  const ParsedTable({required this.header, required this.rows});

  final List<String> header;

  /// 本文の行。**列の数は見出しに揃えてある**（足りなければ空、多ければ捨てる。
  /// GFM と同じ）。
  final List<List<String>> rows;

  static List<String> _cells(String line) {
    var inner = line.trim();
    if (inner.startsWith('|')) inner = inner.substring(1);
    if (inner.endsWith('|') && !inner.endsWith(r'\|')) {
      inner = inner.substring(0, inner.length - 1);
    }
    // `\|` はセルの中の縦棒（区切りではない）
    return inner
        .split(RegExp(r'(?<!\\)\|'))
        .map((c) => c.trim().replaceAll(r'\|', '|'))
        .toList();
  }

  /// 表として読めなければ null。
  static ParsedTable? parse(String markdown) {
    final lines = markdown
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.length < 2) return null;
    final header = _cells(lines[0]);
    if (header.isEmpty) return null;
    final rows = [
      for (final line in lines.skip(2))
        [
          for (var x = 0; x < header.length; x++)
            _cells(line).elementAtOrNull(x) ?? '',
        ],
    ];
    return ParsedTable(header: header, rows: rows);
  }

  /// 幅を測るための素の文字（リンクは文字だけ、強調の記号は落とす）。
  static String plainText(String markdown) => markdown
      .replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^)]*\)'), (m) => m.group(1)!)
      .replaceAll(RegExp(r'[*`_]'), '');

  static final _cjk = RegExp(
    r'[\p{Script=Han}\p{Script=Hiragana}\p{Script=Katakana}　-〿＀-￯]',
    unicode: true,
  );

  /// 折り返せない一続き。**漢字・かな・全角の記号は 1 字ずつ**、それ以外は空白で区切る
  /// （ブラウザの `line-break: normal` のおおよそ。行頭禁則は無視する ―― 幅を
  /// 決めるだけなので、1 字ぶんの差は余白に吸われる）。
  static List<String> unbreakableSegments(String text) {
    final segments = <String>[];
    final buffer = StringBuffer();
    void flush() {
      if (buffer.isNotEmpty) segments.add(buffer.toString());
      buffer.clear();
    }

    for (final rune in text.runes) {
      final ch = String.fromCharCode(rune);
      if (ch.trim().isEmpty) {
        flush();
      } else if (_cjk.hasMatch(ch)) {
        flush();
        segments.add(ch);
      } else {
        buffer.write(ch);
      }
    }
    flush();
    return segments;
  }
}
