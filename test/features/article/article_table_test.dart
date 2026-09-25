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
