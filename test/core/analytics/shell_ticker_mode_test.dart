import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// **`TrackScreen` が寄りかかっている前提を、実物の go_router で固定する。**
///
/// `TrackScreen` は「いま表になっているか」を `TickerMode` で見ている。これは
/// `StatefulShellRoute.indexedStack` が**裏のブランチを
/// `Offstage` ＋ `TickerMode(enabled: false)` で包む**という、go_router の
/// 内部実装に依るもの（gyumesy が確かめたのは 17.5.0 の
/// `_buildRouteBranchContainer`）。gyumesy-frontend-app のものを写した。
///
/// **ここが変わると、`screen_view` が黙って「初回だけ」に戻る。**
/// `track_screen_test.dart` は `TickerMode` を直に動かして測っているので、
/// 前提のほうが壊れても気づけない。**だからここで実物を通す。**
void main() {
  /// いま自分が表になっているかを記録するだけの画面。
  Widget probe(String name, Map<String, bool> seen) => Builder(
    builder: (context) {
      seen[name] = TickerMode.valuesOf(context).enabled;
      return Text(name);
    },
  );

  testWidgets('裏のブランチは TickerMode が落ちる', (tester) async {
    final seen = <String, bool>{};

    final router = GoRouter(
      initialLocation: '/a',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => shell,
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(path: '/a', builder: (c, s) => probe('a', seen)),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(path: '/b', builder: (c, s) => probe('b', seen)),
              ],
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(seen['a'], isTrue, reason: '開いているブランチが表になっていない');

    // 別のタブへ送る
    router.go('/b');
    await tester.pumpAndSettle();

    expect(seen['b'], isTrue);
    expect(
      seen['a'],
      isFalse,
      reason:
          '裏へ回ったブランチの TickerMode が落ちていない '
          '（go_router がこの包み方をやめた可能性がある。'
          'TrackScreen の「また見えるようになった」判定が効かなくなる）',
    );

    // 戻ってくると、また表になる
    seen.clear();
    router.go('/a');
    await tester.pumpAndSettle();

    expect(seen['a'], isTrue, reason: '戻ってきたブランチが表になっていない');
  });
}
