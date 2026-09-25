import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tonsoku/core/storage/preferences_provider.dart';
import 'package:tonsoku/core/i18n/app_locale.dart';
import 'package:tonsoku/core/theme/app_theme.dart';
import 'package:tonsoku/features/home/data/article_providers.dart';
import 'package:tonsoku/features/notifications/data/messaging_service.dart';
import 'package:tonsoku/features/notifications/presentation/notification_settings_controller.dart';
import 'package:tonsoku/features/onboarding/data/onboarding_store.dart';
import 'package:tonsoku/features/onboarding/presentation/onboarding_overlay.dart';
import 'package:tonsoku/features/onboarding/presentation/onboarding_page.dart';
import 'package:tonsoku/shared/models/category.dart';

class _MockMessaging extends Mock implements MessagingService {}

/// オンボーディングの重ね方。
///
/// **重ねるのは `Stack` だけなので、下の本体はセマンティクス木に残る。**
/// 指のタップはオンボーディングが受け止めるが、スクリーンリーダーの activate は
/// `SemanticsAction.tap` を直に送るので**ヒットテストを迂回して発火する**。
/// 塞がないと、TalkBack / VoiceOver の利用者が右スワイプで読み進めるだけで、
/// **まだ見せていないホームのタブや記事カードへ到達して開けてしまう**
/// （オンボーディングは出たままなので、何が起きたのか分からない）。
///
/// `AppShell` の暗幕（メニューのシート）が既に同じ問題を解いている。
void main() {
  const categories = [
    Category(slug: 'menu', label: '新メニュー'),
    Category(slug: 'campaign', label: 'キャンペーン'),
  ];

  late _MockMessaging messaging;

  setUp(() {
    messaging = _MockMessaging();
    when(() => messaging.tokenRefresh).thenAnswer((_) => const Stream.empty());
    when(() => messaging.subscribe(any())).thenAnswer((_) async {});
    when(() => messaging.unsubscribe(any())).thenAnswer((_) async {});
    when(messaging.token).thenAnswer((_) async => 'tok-1');
    when(
      messaging.currentPermission,
    ).thenAnswer((_) async => NotificationPermission.notDetermined);
    when(
      messaging.request,
    ).thenAnswer((_) async => NotificationPermission.granted);
  });

  /// 下に本体の代わりを敷いて重ねる。**`done` が「既に見終わっている」。**
  Future<void> pump(WidgetTester tester, {required bool done}) async {
    SharedPreferences.setMockInitialValues({
      'app_locale': 'ja',
      if (done) 'flutter.tonsoku-onboarding-done': true,
    });
    final prefs = await SharedPreferences.getInstance();

    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          messagingServiceProvider.overrideWithValue(messaging),
          categoriesProvider.overrideWith((ref) => Stream.value(categories)),
        ],
        child: MaterialApp(
          theme: AppTheme.light(AppLocale.ja),
          home: OnboardingOverlay(
            child: Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('下のボタン'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('出ている間、下の本体は読み上げから外れる', (tester) async {
    await pump(tester, done: false);
    final handle = tester.ensureSemantics();

    expect(find.byType(OnboardingPage), findsOneWidget);
    // 描かれてはいる（重ねているだけなので）
    expect(find.text('下のボタン'), findsOneWidget);

    expect(
      find.bySemanticsLabel('下のボタン'),
      findsNothing,
      reason: '読み上げから下の画面を操作できてしまう',
    );
    handle.dispose();
  });

  /// **閉じたら戻す。** 外したままだと、本編がまるごと読み上げから消える
  testWidgets('閉じたら下の本体が読み上げに戻る', (tester) async {
    await pump(tester, done: false);
    final handle = tester.ensureSemantics();

    // 1 枚目 → 2 枚目 → 「あとで」で閉じる
    await tester.tap(find.text('次へ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('あとで'));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingPage), findsNothing);
    expect(find.bySemanticsLabel('下のボタン'), findsOneWidget);
    handle.dispose();
  });

  /// **一度見たら二度と重ねない。** 版ではなく「出したか」だけを持つ
  testWidgets('見終わっていれば重ねない', (tester) async {
    await pump(tester, done: true);
    final handle = tester.ensureSemantics();

    expect(find.byType(OnboardingPage), findsNothing);
    expect(find.bySemanticsLabel('下のボタン'), findsOneWidget);
    handle.dispose();
  });

  /// **閉じたら見終わったことを残す。** 次の起動（[OnboardingStore] を
  /// 読み直す）では重ねない
  testWidgets('閉じたら見終わったことが残る', (tester) async {
    await pump(tester, done: false);

    await tester.tap(find.text('次へ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('あとで'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(OnboardingStore(prefs).isDone, isTrue);
  });
}
