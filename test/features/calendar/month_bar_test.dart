import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonsoku/core/storage/preferences_provider.dart';
import 'package:tonsoku/core/i18n/app_locale.dart';
import 'package:tonsoku/core/theme/app_theme.dart';
import 'package:tonsoku/features/calendar/presentation/calendar_page.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 月ナビの並び。**狭い端末と大きな文字サイズで壊れないこと。**
void main() {
  Future<void> pumpBar(
    WidgetTester tester, {
    double width = 320,
    double textScale = 1,
  }) async {
    SharedPreferences.setMockInitialValues({'app_locale': 'ja'});
    final store = await SharedPreferences.getInstance();

    tester.view.physicalSize = Size(width * 3, 200 * 3);
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
            child: Scaffold(
              body: CalendarMonthBar(
                month: '2026-08',
                range: (min: '2026-01', max: '2026-12'),
                onShift: (_) {},
                onToday: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  // **文字サイズを上げても重ならないこと。** 幅を決め打ちで空けていた時は
  // x2.0 から重なり、x3.0 では矢印 48pt のうち 26pt が覆われて `Stack` の
  // 後勝ちで「今日」がタップを取っていた（押すたび今月へ戻される）
  for (final scale in [1.0, 1.5, 2.0, 3.0]) {
    testWidgets('狭い端末でも「今日」が「次の月」に重ならない（文字 x$scale）', (tester) async {
      // 重なると、その端末では横フリックしか月を送る手段がなくなる
      await pumpBar(tester, textScale: scale);

      // **アイコンではなく押せる範囲どうしを比べる。** アイコンは器の中で
      // 中央にあるので、器が重なっていてもアイコンだけなら離れて見える。
      // `InkResponse` が押せる範囲そのもの（`_NavButton` は private なので
      // 型では掴めないが、当たり判定を持っているのはこちら）
      final next = tester.getRect(
        find.ancestor(
          of: find.byIcon(Icons.arrow_forward_ios),
          matching: find.byType(InkResponse),
        ),
      );
      final today = tester.getRect(find.byType(OutlinedButton));

      expect(
        next.right,
        lessThanOrEqualTo(today.left),
        reason: '「次の月」と「今日」の押せる範囲が重なっている',
      );
    });
  }

  testWidgets('文字サイズを上げても月ラベルが切れない', (tester) async {
    await pumpBar(tester, textScale: 2);

    expect(tester.takeException(), isNull);
    expect(find.text('2026年8月'), findsOneWidget);
    // 縮めて収めるので、器からはみ出さない
    final label = tester.getRect(find.text('2026年8月'));
    expect(label.width, lessThanOrEqualTo(320));
  });

  testWidgets('端の月ではボタンを押せなくする', (tester) async {
    SharedPreferences.setMockInitialValues({'app_locale': 'ja'});
    final store = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(store)],
        child: MaterialApp(
          theme: AppTheme.light(AppLocale.ja),
          home: Scaffold(
            body: CalendarMonthBar(
              month: '2026-01',
              range: (min: '2026-01', max: '2026-12'),
              onShift: (_) {},
              onToday: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final prev = tester.widget<InkResponse>(
      find.ancestor(
        of: find.byIcon(Icons.arrow_back_ios),
        matching: find.byType(InkResponse),
      ),
    );
    expect(prev.onTap, isNull, reason: '空の月へ際限なく進めないこと');
  });
}
