import 'package:flutter_test/flutter_test.dart';
import 'package:tonsoku/features/article/presentation/widgets/article_table.dart';

void main() {
  group('ParsedTable', () {
    test('見出しと行に分け、列の数を見出しに揃える', () {
      final table = ParsedTable.parse(
        '| 掲示名 | 所在地 |\n|---|---|\n| [松のや 西新宿店](https://x) | 東京都 |\n| 余り | 列 | 多い |\n| 少ない |',
      )!;
      expect(table.header, ['掲示名', '所在地']);
      expect(table.rows, [
        ['[松のや 西新宿店](https://x)', '東京都'],
        ['余り', '列'],
        ['少ない', ''],
      ]);
    });

    test('素の文字はリンクの文字だけを残し、強調の記号を落とす', () {
      expect(ParsedTable.plainText('**[松のや](https://x)** の`店`'), '松のや の店');
    });

    /// **閉じ括弧を独立させると `）` だけが次の行に落ちる**（本番の記事 `6gdw35`）。
    test('閉じ括弧・句読点は直前に、開き括弧は直後につなげる（禁則）', () {
      expect(ParsedTable.unbreakableSegments('-280円（約22%）'), [
        '-280',
        '円',
        '（約',
        '22%）',
      ]);
      expect(ParsedTable.unbreakableSegments('「松のや」、ロースかつ。'), [
        '「松',
        'の',
        'や」、',
        // 長音も行頭に来ない
        'ロー',
        'ス',
        'か',
        'つ。',
      ]);
      expect(ParsedTable.unbreakableSegments('ちょっと'), ['ちょっ', 'と']);
    });

    /// web の `td a { white-space: nowrap }`（本番の記事 `2cjtbt` で店名が
    /// 3 行に割れていた）。
    test('リンクは折り返せなくし、続く折り返せない字ごと 1 つの一続きにする', () {
      const cell = '[松のや 草加店（草加駅前）](https://x)（9/21 9時 終売）';
      final nowrap = ParsedTable.noWrapLinks(cell);
      expect(nowrap, endsWith('](https://x)（9/21 9時 終売）'));
      // 空白は NO-BREAK SPACE、字の間は WORD JOINER
      expect(nowrap, startsWith('[松\u2060の\u2060や\u2060\u00A0\u2060草'));
      // 見た目の文字は変わらない
      expect(
        ParsedTable.plainText(
          nowrap,
        ).replaceAll('\u2060', '').replaceAll('\u00A0', ' '),
        ParsedTable.plainText(cell),
      );
      // **`）（` は切らない**ので、リンクの後ろの `（9/21` まで 1 つ
      expect(
        ParsedTable.unbreakableSegments(
          ParsedTable.plainText(nowrap),
        ).map((s) => s.replaceAll('\u2060', '').replaceAll('\u00A0', ' ')),
        ['松のや 草加店（草加駅前）（9/21', '9', '時', '終', '売）'],
      );
      // 強調の記号は割らない
      expect(
        ParsedTable.noWrapLinks('[**店**](https://x)'),
        '[**店**](https://x)',
      );
    });

    test('折り返せない一続きは、漢字・かなを 1 字ずつ、英数字は語ごと', () {
      expect(ParsedTable.unbreakableSegments('京都府96-1 PayPay'), [
        '京',
        '都',
        '府',
        '96-1',
        'PayPay',
      ]);
    });
  });

  group('columnWidths（ブラウザの自動表レイアウトと同じ配り方）', () {
    // 見出しは min == max、本文は min < max
    ({double min, double max}) Function(String, {required bool header}) measure(
      Map<String, ({double min, double max})> sizes,
    ) =>
        (text, {required header}) => sizes[text]!;

    final table = ParsedTable.parse('| A | B |\n|---|---|\n| a | b |')!;

    test('広げた幅で収まれば、その幅のまま（fit-content）', () {
      final layout = columnWidths(
        table,
        available: 400,
        measure: measure({
          'A': (min: 50, max: 50),
          'B': (min: 50, max: 50),
          'a': (min: 20, max: 100),
          'b': (min: 20, max: 150),
        }),
      );
      expect(layout.widths, [100, 150]);
      expect(layout.overflows, isFalse);
    });

    test('収まらなければ、最小幅に余りを「広げた幅 − 最小幅」に比例して配る', () {
      final layout = columnWidths(
        table,
        available: 201, // 左端の罫 1 を引いて 200
        measure: measure({
          'A': (min: 50, max: 50),
          'B': (min: 50, max: 50),
          'a': (min: 20, max: 150),
          'b': (min: 20, max: 350),
        }),
      );
      // min は見出しの 50 ずつ。余り 100 を (100 : 300) で配る
      expect(layout.widths, [75, 125]);
      expect(layout.overflows, isFalse);
    });

    test('最小幅でも収まらなければ、最小幅で横に送る', () {
      final layout = columnWidths(
        table,
        available: 150,
        measure: measure({
          'A': (min: 100, max: 100),
          'B': (min: 100, max: 100),
          'a': (min: 20, max: 300),
          'b': (min: 20, max: 300),
        }),
      );
      expect(layout.widths, [100, 100]);
      expect(layout.overflows, isTrue);
    });
  });
}
