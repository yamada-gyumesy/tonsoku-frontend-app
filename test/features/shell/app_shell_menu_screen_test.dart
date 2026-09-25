import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tonsoku/core/i18n/app_locale.dart';
import 'package:tonsoku/core/storage/preferences_provider.dart';
import 'package:tonsoku/core/theme/app_theme.dart';
import 'package:tonsoku/features/calendar/data/calendar_repository.dart';
import 'package:tonsoku/features/notifications/domain/deep_link.dart';
import 'package:tonsoku/features/ranking/data/ranking_repository.dart';
import 'package:tonsoku/features/shell/presentation/app_shell.dart';
import 'package:tonsoku/features/shell/presentation/menu_screen_request.dart';

/// メニューから開く画面（ランキング・カレンダー）とタブの行き来。
///
/// **メニューから開いた画面はどのタブにも属さない**ので、タブを移ったら畳む
/// （ユーザーの指摘: ホーム → ランキング → クーポン → ホームでランキングが出た）。
void main() {
  // **要求はアプリ全体で 1 つ**（`menuScreenRequest`）なので、前のテストの
  // 要求を次のシェルが拾わないよう毎回空にする
  setUp(() => menuScreenRequest.value = null);

  Future<GoRouter> pump(
    WidgetTester tester, {
    Map<String, Object> prefs = const {},
  }) async {
    SharedPreferences.setMockInitialValues({'app_locale': 'ja', ...prefs});
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
                        path: 'calendar',
                        builder: (context, state) =>
                            Text('カレンダー画面 ${state.uri}'),
                      ),
                      GoRoute(
                        path: 'notifications',
                        builder: (context, state) =>
                            Text('通知設定画面 ${state.uri}'),
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
          calendarEventsProvider.overrideWithValue(const AsyncValue.loading()),
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

  /// **印はタブごとに持つ**（1 つだけだと上書きされ、ホームにランキングが
  /// 残った。PR #20 のレビューで再現）。
  testWidgets('2 つのタブでメニューの画面を開いても、どちらも畳まれる', (tester) async {
    await pump(tester);
    await openRanking(tester);

    await tester.tap(find.text('クーポン'));
    await tester.pumpAndSettle();
    await openRanking(tester);

    await tester.tap(find.text('ホーム'));
    await tester.pumpAndSettle();
    expect(find.text('ランキング画面'), findsNothing);
    expect(find.text('root /'), findsOneWidget);

    await tester.tap(find.text('クーポン'));
    await tester.pumpAndSettle();
    expect(find.text('ランキング画面'), findsNothing);
    expect(find.text('root /coupon'), findsOneWidget);
  });

  /// **カレンダーもランキングと同じ扱い**（いま居るタブの中に積み、タブを
  /// 移ったら畳む）。
  testWidgets('カレンダーはいま居るタブの中に積み、タブを移ると畳まれる', (tester) async {
    await pump(tester);
    await tester.tap(find.text('クーポン'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('メニュー'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('カレンダー'));
    await tester.pumpAndSettle();
    // クーポンのタブの中に、絞り込みなしで積まれる
    expect(find.text('カレンダー画面 /coupon/calendar'), findsOneWidget);

    await tester.tap(find.text('ホーム'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('クーポン'));
    await tester.pumpAndSettle();
    expect(find.textContaining('カレンダー画面'), findsNothing);
    expect(find.text('root /coupon'), findsOneWidget);
  });

  /// **通知設定もメニューから開く画面**（ランキングと同じく、いま居るタブの中に
  /// 積み、タブを移ったら畳む）。並びはランキングの下（ユーザーの指定）。
  testWidgets('通知設定はいま居るタブの中に積み、タブを移ると畳まれる', (tester) async {
    await pump(tester);
    await tester.tap(find.text('マップ'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('メニュー'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('通知設定'));
    await tester.pumpAndSettle();
    expect(find.text('通知設定画面 /map/notifications'), findsOneWidget);

    await tester.tap(find.text('ホーム'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('マップ'));
    await tester.pumpAndSettle();
    expect(find.textContaining('通知設定画面'), findsNothing);
    expect(find.text('root /map'), findsOneWidget);
  });

  group('通知のタップ（外から来た URL）', () {
    /// **積むのはシェル。** どのタブに積むかを知っているのはシェルだけ
    testWidgets('メニューの画面はいま居るタブに積む', (tester) async {
      await pump(tester);
      await tester.tap(find.text('クーポン'));
      await tester.pumpAndSettle();

      requestOpenMenuScreen(const MenuScreenTarget(MenuScreen.notifications));
      await tester.pumpAndSettle();
      expect(find.text('通知設定画面 /coupon/notifications'), findsOneWidget);
    });

    /// **同じ画面を 2 枚積まない。** 重なると、戻るを押しても見た目が変わらず
    /// 「戻るが効かない」に見える（gyumesy の通知設定と同じ）
    testWidgets('同じ画面が出ていれば積み直さない', (tester) async {
      final router = await pump(tester);

      requestOpenMenuScreen(const MenuScreenTarget(MenuScreen.notifications));
      await tester.pumpAndSettle();
      requestOpenMenuScreen(const MenuScreenTarget(MenuScreen.notifications));
      await tester.pumpAndSettle();

      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('root /'), findsOneWidget);
    });

    /// **`go` は他のタブに触らない。** 別のタブに積んだメニューの画面が
    /// 残ったままだと、下タブでそのタブへ戻った時に出てくる
    testWidgets('別の面へ移ったら、他のタブに積んだメニューの画面も畳む', (tester) async {
      final router = await pump(tester);
      await tester.tap(find.text('クーポン'));
      await tester.pumpAndSettle();
      await openRanking(tester);

      // 通知から記事（ホームのタブ）へ
      router.go('/article');
      requestFoldMenuScreens();
      await tester.pumpAndSettle();
      expect(find.text('記事'), findsOneWidget);

      await tester.tap(find.text('クーポン'));
      await tester.pumpAndSettle();
      expect(find.text('ランキング画面'), findsNothing);
      expect(find.text('root /coupon'), findsOneWidget);

      // **移った先で開いた記事は畳まない**（印を消しただけ）
      await tester.tap(find.text('ホーム'));
      await tester.pumpAndSettle();
      expect(find.text('記事'), findsOneWidget);
    });
  });

  /// **Android は通知の権限を取り消されるとプロセスを殺す**ので、設定アプリから
  /// 戻るとコールドスタートになる。送り出す時の印を見て通知設定へ戻す
  /// （gyumesy と同じ）。
  group('設定アプリから戻った時', () {
    testWidgets('印があれば通知設定を開き、印を消す', (tester) async {
      await pump(tester, prefs: {'tonsoku-notification-returning': true});

      expect(find.text('通知設定画面 /notifications'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('tonsoku-notification-returning'), isNull);
    });

    testWidgets('印が無ければホームのまま', (tester) async {
      await pump(tester);
      expect(find.textContaining('通知設定画面'), findsNothing);
    });
  });
}
