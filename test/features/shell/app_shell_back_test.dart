import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tonsoku/core/i18n/app_locale.dart';
import 'package:tonsoku/core/storage/preferences_provider.dart';
import 'package:tonsoku/core/theme/app_theme.dart';
import 'package:tonsoku/features/menu/presentation/menu_sheet.dart';
import 'package:tonsoku/features/menu/presentation/widgets/menu_list_row.dart';
import 'package:tonsoku/features/shell/presentation/app_shell.dart';

/// メニューのシートと Android の戻る操作。
///
/// **タブの中に画面を積んだ構成で確かめる。** go_router は戻る操作を深い側の
/// ナビゲータ（ブランチ）から処理するので、積んだ画面があるとそこで消費され、
/// シェルの `PopScope` まで届かない（PR #17 のレビューで再現）。ナビゲータが 1 つ
/// の構成では、この経路を通らない。
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
        overrides: [sharedPreferencesProvider.overrideWithValue(store)],
        child: MaterialApp.router(
          theme: AppTheme.light(AppLocale.ja),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.text('メニュー'));
    await tester.pumpAndSettle();
    expect(find.byType(MenuSheet), findsOneWidget);
  }

  testWidgets('記事を積んだタブでも、戻るはまずシートを閉じる', (tester) async {
    final router = await pump(tester);
    router.push('/article');
    await tester.pumpAndSettle();
    expect(find.text('記事'), findsOneWidget);

    await openSheet(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(MenuSheet), findsNothing, reason: 'シートが閉じていない');
    expect(find.text('記事'), findsOneWidget, reason: '裏の記事が閉じた');

    // シートが閉じた後の戻るは、いつもどおり記事を閉じる
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('記事'), findsNothing);
  });

  testWidgets('2 階層目を開いていたら、戻るはメニューへ戻すだけ', (tester) async {
    final router = await pump(tester);
    router.push('/article');
    await tester.pumpAndSettle();

    await openSheet(tester);
    await tester.tap(find.widgetWithText(MenuListRow, '言語'));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(MenuSheet), findsOneWidget, reason: 'メニューへ戻らずに閉じた');
    expect(find.text('記事'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(MenuSheet), findsNothing);
    expect(find.text('記事'), findsOneWidget);
  });

  testWidgets('何も積んでいないタブでも、戻るはシートを閉じる', (tester) async {
    await pump(tester);
    await openSheet(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(MenuSheet), findsNothing);
    expect(find.text('root /'), findsOneWidget);
  });

  /// **OS に「戻るはアプリが扱う」と伝えること。** Android 16（予測型「戻る」が
  /// 既定）は、これが無いと戻る操作をアプリに渡さずにホーム画面へ抜ける。
  /// `handlePopRoute` はこの判定を迂回するので、上のテストでは見えない
  /// （PR #17 の 2 回目のレビュー）。
  testWidgets('シートを開いたら、OS に戻る操作はアプリが扱うと伝える', (tester) async {
    final calls = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemNavigator.setFrameworkHandlesBack') {
          calls.add(call.arguments);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    // **ライフサイクルを resumed にする。** 未設定だと `WidgetsApp` は OS へ
    // 何も送らない（起動前の扱い）
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await pump(tester);
    calls.clear();
    await openSheet(tester);
    expect(calls, contains(true), reason: '何も積んでいないタブで伝えていない');
  });
}
