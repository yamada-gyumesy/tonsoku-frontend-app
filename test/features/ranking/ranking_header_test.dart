import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonsoku/core/storage/preferences_provider.dart';
import 'package:tonsoku/core/i18n/app_locale.dart';
import 'package:tonsoku/core/theme/app_theme.dart';
import 'package:tonsoku/features/ranking/presentation/ranking_page.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 見出しと更新日。**端末の文字サイズを上げても壊れないこと。**
///
/// 同じ行に並べるだけだと、更新日が見出しを押し潰す（実測で 320pt の x1.5 から
/// 見出しが 1 文字ずつ折り返し、x2.0 で幅 0 になって消え、更新日が画面外へ出る）。
void main() {
  Future<void> pumpHeader(
    WidgetTester tester, {
    required double width,
    required double textScale,
  }) async {
    SharedPreferences.setMockInitialValues({'app_locale': 'ja'});
    final store = await SharedPreferences.getInstance();

    tester.view.physicalSize = Size(width * 3, 400 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(store)],
        child: MaterialApp(
          theme: AppTheme.light(AppLocale.ja),
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: const Scaffold(
              body: RankingHeader(updatedAt: '2026-08-23T22:30:00Z'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  for (final (width, scale) in [
    (320.0, 1.0),
    (320.0, 1.5),
    (320.0, 2.0),
    (390.0, 2.5),
    (320.0, 3.0),
  ]) {
    testWidgets('見出しが潰れない（幅 $width・文字 x$scale）', (tester) async {
      await pumpHeader(tester, width: width, textScale: scale);

      expect(tester.takeException(), isNull, reason: '器から溢れている');

      final title = tester.getRect(find.text('ランキング'));
      expect(title.width, greaterThan(0), reason: '見出しが消えている');
      // **1 行に収まること。** 幅を押し潰されると 1 文字ずつ折り返して
      // 縦に伸びる（実測で x1.5 のとき幅 32.5pt・高さ 215pt）。溢れ警告は
      // 出ないので、高さで見るしかない
      // 上限は 2 行ぶん。x3.0 では文字が本当に入り切らないので 2 行は許す
      // （壊れているのは 1 文字ずつ折り返す形）
      expect(
        title.height,
        lessThanOrEqualTo(20 * scale * 3),
        reason: '見出しが 1 文字ずつ折り返している',
      );
      expect(title.right, lessThanOrEqualTo(width), reason: '見出しが画面外へ出ている');

      final date = tester.getRect(find.textContaining('更新日'));
      expect(date.right, lessThanOrEqualTo(width), reason: '更新日が画面外へ出ている');
    });
  }
}
