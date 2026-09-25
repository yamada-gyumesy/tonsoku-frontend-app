import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tonsoku/core/i18n/app_locale.dart';
import 'package:tonsoku/core/storage/preferences_provider.dart';
import 'package:tonsoku/core/theme/app_theme.dart';
import 'package:tonsoku/features/ranking/data/ranking_repository.dart';
import 'package:tonsoku/features/shell/presentation/app_shell.dart';

/// メニューから開く画面（ランキング）とタブの行き来。
///
/// **メニューから開いた画面はどのタブにも属さない**ので、タブを移ったら畳む
/// （ユーザーの指摘: ホーム → ランキング → クーポン → ホームでランキングが出た）。
void main() {
  Future<GoRouter> pump(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'app_locale': 'ja'});
    final store = await SharedPreferences.getInstance();
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => AppShell(navigationShell: shell),
          branches: [
            for (final path in ['/', '/map', '/coupon'])
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: path,
                    builder: (context, state) => Text('root $path'),
                    routes: [
                      GoRoute(
                        path: 'ranking',
                        builder: (context, state) => const Text('ランキング画面'),
                      ),
                      GoRoute(
                        path: 'article',
                        builder: (context, state) => const Text('記事'),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(store),
          // 取得中はランキングの行を出しておく（`MenuSheet` の注記）
          rankingWindowsProvider.overrideWithValue(const AsyncValue.loading()),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(AppLocale.ja),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  Future<void> openRanking(WidgetTester tester) async {
    await tester.tap(find.text('メニュー'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ランキング'));
    await tester.pumpAndSettle();
    expect(find.text('ランキング画面'), findsOneWidget);
  }

  testWidgets('タブを移って戻ると、メニューから開いた画面は畳まれている', (tester) async {
    await pump(tester);
    await openRanking(tester);

    await tester.tap(find.text('クーポン'));
    await tester.pumpAndSettle();
    expect(find.text('root /coupon'), findsOneWidget);

    await tester.tap(find.text('ホーム'));
    await tester.pumpAndSettle();
    expect(find.text('ランキング画面'), findsNothing);
    expect(find.text('root /'), findsOneWidget);
  });

  testWidgets('積んだタブの中にいる間は、戻るでタブの画面へ帰る', (tester) async {
    final router = await pump(tester);
    await openRanking(tester);

    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('root /'), findsOneWidget);
  });

  /// **閉じた後は畳まない。** 畳む印が残っていると、そのあと同じタブに積んだ
  /// 記事までタブを移った時に消える。
  testWidgets('メニューの画面を閉じた後に積んだ記事は、タブを移っても残る', (tester) async {
    final router = await pump(tester);
    await openRanking(tester);
    router.pop();
    await tester.pumpAndSettle();

    router.push('/article');
    await tester.pumpAndSettle();
    await tester.tap(find.text('クーポン'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ホーム'));
    await tester.pumpAndSettle();
    expect(find.text('記事'), findsOneWidget);
  });
}
