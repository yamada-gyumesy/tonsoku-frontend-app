import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tonsoku/core/analytics/analytics.dart';
import 'package:tonsoku/core/analytics/screen_path.dart';
import 'package:tonsoku/core/analytics/track_screen.dart';

class _RecordingAnalytics implements Analytics {
  final sent = <ScreenPath>[];

  @override
  Future<void> screen(ScreenPath screen) async => sent.add(screen);
}

/// 画面の送信。
///
/// **`build` のたびに送らない。** スクロールや再描画で何度も数えられると、
/// web の Pageview と比べられなくなる。
void main() {
  const a = ScreenPath(path: '/coupon/', title: '松のやのクーポン | とん速');
  const b = ScreenPath(path: '/ranking/', title: 'ランキング | とん速');

  Future<_RecordingAnalytics> pump(
    WidgetTester tester,
    ValueNotifier<ScreenPath?> screen,
  ) async {
    final recorder = _RecordingAnalytics();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [analyticsProvider.overrideWithValue(recorder)],
        child: MaterialApp(
          home: ValueListenableBuilder<ScreenPath?>(
            valueListenable: screen,
            builder: (context, value, _) =>
                TrackScreen(screen: value, child: const SizedBox()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return recorder;
  }

  testWidgets('開いたら 1 回だけ送る', (tester) async {
    final screen = ValueNotifier<ScreenPath?>(a);
    addTearDown(screen.dispose);
    final rec = await pump(tester, screen);

    expect(rec.sent, [a]);

    // 同じ中身で描き直しても増えない
    screen.value = const ScreenPath(path: '/coupon/', title: '松のやのクーポン | とん速');
    await tester.pumpAndSettle();
    expect(rec.sent, [a], reason: '同じ画面を二度数えている');
  });

  testWidgets('中身が変わったら送り直す', (tester) async {
    final screen = ValueNotifier<ScreenPath?>(a);
    addTearDown(screen.dispose);
    final rec = await pump(tester, screen);

    screen.value = b;
    await tester.pumpAndSettle();
    expect(rec.sent, [a, b]);
  });

  /// **また見えるようになったら送り直す。**
  ///
  /// タブは `StatefulShellRoute.indexedStack` で一度開いたら生き続けるので、
  /// これが無いと **1 セッション 1 件**に潰れる。web は遷移のたびに Pageview が
  /// 立つので、**パスの文字列が揃っていても件数の意味が違えば突き合わせられない**
  /// （gyumesy の実測で 7 回の遷移に対して 4 件しか立っていなかった）。
  testWidgets('隠れてから出たら送り直す', (tester) async {
    final visible = ValueNotifier<bool>(true);
    addTearDown(visible.dispose);
    final rec = _RecordingAnalytics();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [analyticsProvider.overrideWithValue(rec)],
        child: MaterialApp(
          home: ValueListenableBuilder<bool>(
            valueListenable: visible,
            builder: (context, on, _) => TickerMode(
              enabled: on,
              child: const TrackScreen(screen: a, child: SizedBox()),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(rec.sent, [a]);

    // 別のタブへ送った（`indexedStack` は裏のブランチの TickerMode を落とす）
    visible.value = false;
    await tester.pumpAndSettle();
    expect(rec.sent, [a], reason: '隠れた時に送っている');

    // 戻ってきた
    visible.value = true;
    await tester.pumpAndSettle();
    expect(rec.sent, [a, a], reason: '戻ってきたのに送られていない');
  });

  /// **隠れていない間の再描画では送らない。** スクロールや再描画で何度も
  /// 数えられると、こんどは web より多く立つ
  testWidgets('表になったまま描き直しても増えない', (tester) async {
    final rec = _RecordingAnalytics();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [analyticsProvider.overrideWithValue(rec)],
        child: const MaterialApp(
          home: TickerMode(
            enabled: true,
            child: TrackScreen(screen: a, child: SizedBox()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(rec.sent, [a]);

    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }
    expect(rec.sent, [a], reason: '再描画で数え過ぎている');
  });

  /// **表題が決まるまで送らない。** 記事は取得前だと表題が無く、送ると
  /// 「表題の無いページ」として別に数えられる
  testWidgets('null の間は送らない', (tester) async {
    final screen = ValueNotifier<ScreenPath?>(null);
    addTearDown(screen.dispose);
    final rec = await pump(tester, screen);

    expect(rec.sent, isEmpty);

    screen.value = a;
    await tester.pumpAndSettle();
    expect(rec.sent, [a]);
  });
}
