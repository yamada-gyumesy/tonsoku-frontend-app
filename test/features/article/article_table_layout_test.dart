import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonsoku/core/i18n/app_locale.dart';
import 'package:tonsoku/core/theme/app_theme.dart';
import 'package:tonsoku/features/article/presentation/widgets/article_table.dart';

/// 本番の表を **Klee One の実寸**で組んで、折り返し位置を確かめる。
///
/// テストの既定の書体（Ahem）は全部の字が同じ幅の四角で、禁則も漢字の
/// 折り返しも本物と違う。**書体を読み込まないと、このテストは何も見ていない。**
void main() {
  setUpAll(() async {
    final loader = FontLoader(AppTheme.jaFontFamily)
      ..addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/KleeOne-SemiBold.ttf').readAsBytesSync(),
          ),
        ),
      );
    await loader.load();
  });

  Future<void> pump(WidgetTester tester, String markdown) async {
    // iPhone の幅（375pt）から本文の左右の余白（16 × 2）を引いた幅
    tester.view.physicalSize = const Size(375 * 3, 2000 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(AppLocale.ja),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ArticleTable(markdown: markdown),
          ),
        ),
      ),
    );
  }

  /// [text] を含む段落の、各行の文字。
  List<String> linesOf(WidgetTester tester, String text) {
    final paragraph = tester
        .renderObjectList<RenderParagraph>(find.byType(RichText))
        .firstWhere(
          (p) => p.text.toPlainText().replaceAll('\u2060', '').contains(text),
        );
    final plain = paragraph.text.toPlainText();
    // 字ごとの箱の上端で行を分ける
    final lines = <double, StringBuffer>{};
    for (var i = 0; i < plain.length; i++) {
      final boxes = paragraph.getBoxesForSelection(
        TextSelection(baseOffset: i, extentOffset: i + 1),
      );
      if (boxes.isEmpty) continue;
      final top = boxes.first.top.roundToDouble();
      (lines[top] ??= StringBuffer()).write(plain[i]);
    }
    final ordered = lines.keys.toList()..sort();
    final result = [for (final top in ordered) lines[top].toString()];
    return result;
  }

  /// 本番の記事 `6gdw35`。以前は「差」の列が `-280` の幅で決まり、
  /// `）` が 1 字だけ最後の行に落ちていた。
  testWidgets('閉じ括弧は 1 字だけで次の行に落ちない', (tester) async {
    await pump(
      tester,
      '| 品名 | これまでの価格 | 今回の価格 | 差 |\n'
      '|---|---|---|---|\n'
      '| ロースかつ＆海老フライ（2尾）定食 | 1250円 | 970円 | -280円（約22%） |\n'
      '| 超厚切りリブロースかつ＆海老フライ2尾定食 | 1530円 | 1250円 | -280円（約18%） |',
    );
    for (final text in ['-280円（約22%）', '-280円（約18%）']) {
      final lines = linesOf(tester, text);
      expect(
        lines.where((l) => l.trim() == '）'),
        isEmpty,
        reason: '$text → $lines',
      );
    }
  });

  /// 本番の記事 `2cjtbt`。web の `td a { white-space: nowrap }` と同じく、
  /// 店名のリンクは 1 行のまま（以前は `松のや 草 / 加店（草加 / 駅前）` と 3 行に割れた）。
  testWidgets('表の中のリンクは折り返さない', (tester) async {
    await pump(
      tester,
      '| 店舗名 | 所在地 | 営業時間 |\n'
      '|---|---|---|\n'
      '| [松のや 草加店（草加駅前）](https://example.com/a)（9/21 9時 終売） '
      '| 埼玉県草加市 [Map](https://example.com/b) '
      '| 月から木：9時から23時30分、金：9時から翌2時、土：5時から翌2時、'
      '日：5時から23時30分、ラストオーダー30分前 |',
    );
    final lines = linesOf(tester, '草加店');
    final withLink = lines.where((l) => l.contains('松')).toList();
    expect(withLink, hasLength(1), reason: '$lines');
    expect(
      withLink.single.replaceAll('⁠', '').replaceAll(' ', ' '),
      contains('松のや 草加店（草加駅前）'),
      reason: '$lines',
    );
  });
}
