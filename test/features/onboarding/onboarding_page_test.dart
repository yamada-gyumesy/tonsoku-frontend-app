import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tonsoku/core/i18n/app_messages.dart';
import 'package:tonsoku/core/storage/preferences_provider.dart';
import 'package:tonsoku/core/i18n/app_locale.dart';
import 'package:tonsoku/core/theme/app_theme.dart';
import 'package:tonsoku/features/home/data/article_providers.dart';
import 'package:tonsoku/features/notifications/data/messaging_service.dart';
import 'package:tonsoku/features/notifications/presentation/notification_settings_controller.dart';
import 'package:tonsoku/features/onboarding/data/onboarding_store.dart';
import 'package:tonsoku/features/onboarding/presentation/onboarding_page.dart';
import 'package:tonsoku/shared/models/category.dart';

class _MockMessaging extends Mock implements MessagingService {}

/// 初回起動の 2 画面。
///
/// **OS の通知許可をいきなり出さない。** 何が届くのかを 2 枚目で見せてから
/// 求める。一度拒否されると設定アプリへ行かない限り戻せない。
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

  Future<int> pump(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'app_locale': 'ja'});
    final store = await SharedPreferences.getInstance();
    var done = 0;

    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(store),
          messagingServiceProvider.overrideWithValue(messaging),
          categoriesProvider.overrideWith((ref) => Stream.value(categories)),
        ],
        child: MaterialApp(
          theme: AppTheme.light(AppLocale.ja),
          home: OnboardingPage(onDone: () => done++),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return done;
  }

  /// [pump] と同じだが、閉じた回数を後から読めるように返す。
  /// [categoriesStream] でカテゴリの届き方を差し替える。
  Future<ValueNotifier<int>> pumpCounting(
    WidgetTester tester, {
    Stream<List<Category>> Function()? categoriesStream,
  }) async {
    SharedPreferences.setMockInitialValues({'app_locale': 'ja'});
    final store = await SharedPreferences.getInstance();
    final done = ValueNotifier<int>(0);
    addTearDown(done.dispose);

    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(store),
          messagingServiceProvider.overrideWithValue(messaging),
          categoriesProvider.overrideWith(
            (ref) => categoriesStream?.call() ?? Stream.value(categories),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(AppLocale.ja),
          home: OnboardingPage(onDone: () => done.value++),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return done;
  }

  testWidgets('1 枚目はサービス紹介で、許可は求めない', (tester) async {
    await pump(tester);

    expect(find.text(AppMessages.ja.onboardingIntroTitle), findsOneWidget);
    // **いきなり許可を求めない**
    expect(find.text(AppMessages.ja.onboardingAllow), findsNothing);
    expect(find.text(AppMessages.ja.onboardingNext), findsOneWidget);
    verifyNever(messaging.request);
  });

  testWidgets('2 枚目で通知の価値を見せてから求める', (tester) async {
    await pump(tester);
    await tester.tap(find.text(AppMessages.ja.onboardingNext));
    await tester.pumpAndSettle();

    expect(find.text(AppMessages.ja.onboardingNotifyTitle), findsOneWidget);
    expect(find.text(AppMessages.ja.onboardingAllow), findsOneWidget);
    // **許可しなくても使える**
    expect(find.text(AppMessages.ja.onboardingSkip), findsOneWidget);
    // ここまで OS には触っていない
    verifyNever(messaging.request);
  });

  /// **初期購読は全カテゴリ**（gyumesy と同じ）。まず届く状態にして、多いと
  /// 感じたらメニューの通知設定で減らしてもらう
  testWidgets('許可すると全カテゴリを購読して閉じる', (tester) async {
    await pump(tester);
    await tester.tap(find.text(AppMessages.ja.onboardingNext));
    await tester.pumpAndSettle();
    await tester.tap(find.text('通知を有効にする'));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    verify(messaging.request).called(1);
    verify(() => messaging.subscribe('tonsoku.category.menu')).called(1);
    verify(() => messaging.subscribe('tonsoku.category.campaign')).called(1);
  });

  /// **購読の完了を待たない**（実機で踏んだ）。iOS は許可の直後にまだ APNs
  /// トークンが無く、`subscribeToTopic` が長く返らないことがある。待っていると
  /// OS のダイアログから戻った画面で「通知を受け取る」が押せないままになり、
  /// どうすればよいか分からなくなる。
  testWidgets('購読が返ってこなくても、許可した時点で閉じる', (tester) async {
    // **永遠に返らない購読。** 実機で起きていた状態をそのまま作る
    when(
      () => messaging.subscribe(any()),
    ).thenAnswer((_) => Completer<void>().future);

    var done = 0;
    SharedPreferences.setMockInitialValues({'app_locale': 'ja'});
    final store = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(store),
          messagingServiceProvider.overrideWithValue(messaging),
          categoriesProvider.overrideWith((ref) => Stream.value(categories)),
        ],
        child: MaterialApp(
          theme: AppTheme.light(AppLocale.ja),
          home: OnboardingPage(onDone: () => done++),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppMessages.ja.onboardingNext));
    await tester.pumpAndSettle();
    await tester.tap(find.text('通知を有効にする'));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    // **許可は取れていて、購読も始まっている**
    verify(messaging.request).called(1);
    verify(() => messaging.subscribe(any())).called(2);
    // **それでも閉じている**
    expect(done, 1);
  });

  testWidgets('「あとで」なら OS に触らずに閉じる', (tester) async {
    await pump(tester);
    await tester.tap(find.text(AppMessages.ja.onboardingNext));
    await tester.pumpAndSettle();
    await tester.tap(find.text('あとで'));
    await tester.pumpAndSettle();

    verifyNever(messaging.request);
    verifyNever(() => messaging.subscribe(any()));
  });

  /// **バージョンアップでは再表示しない。** 版ではなく「一度出したか」を持つ
  test('一度出したら二度と出さない', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = OnboardingStore(prefs);

    expect(store.isDone, isFalse);
    await store.markDone();
    expect(store.isDone, isTrue);

    // 別の版として読み直しても残る
    expect(OnboardingStore(prefs).isDone, isTrue);
  });

  /// 通知の許可のダイアログを出している間は閉じない。
  ///
  /// **閉じると広告の SDK が始まり、ATT のダイアログが出る**
  /// （`startAdsAfterOnboarding`）。許可のダイアログより先に閉じると、
  /// 2 つのダイアログが重なる。
  testWidgets('通知の許可に答えるまでは閉じない', (tester) async {
    final answer = Completer<NotificationPermission>();
    when(messaging.request).thenAnswer((_) => answer.future);

    final done = await pumpCounting(tester);
    await tester.tap(find.text(AppMessages.ja.onboardingNext));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppMessages.ja.onboardingAllow));
    await tester.pump(const Duration(milliseconds: 50));

    verify(messaging.request).called(1);
    expect(done.value, 0, reason: 'ダイアログが出ている間に閉じている');

    answer.complete(NotificationPermission.granted);
    await tester.pump(const Duration(milliseconds: 50));
    expect(done.value, 1);
  });

  /// **カテゴリが届く前に押されても、届くのを待ってから購読する。**
  ///
  /// gyumesy の 79d2ce4 で直した不具合。初回起動はキャッシュが無いので
  /// 必ず通信が要り、押された時点ではまだ空のことがある。待たずに進むと
  /// **OS の許可だけ取れて購読が 0 件**になる。
  group('カテゴリがまだ届いていない', () {
    late StreamController<List<Category>> feed;

    setUp(() {
      feed = StreamController<List<Category>>();
      addTearDown(feed.close);
    });

    testWidgets('届くのを待ってから全カテゴリを購読して保存する', (tester) async {
      final done = await pumpCounting(
        tester,
        categoriesStream: () => feed.stream,
      );
      await tester.tap(find.text(AppMessages.ja.onboardingNext));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppMessages.ja.onboardingAllow));
      await tester.pump(const Duration(seconds: 1));

      // **まだ OS に聞いていない**（カテゴリを待っている）
      verifyNever(messaging.request);

      feed.add(categories);
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      verify(messaging.request).called(1);
      verify(() => messaging.subscribe('tonsoku.category.menu')).called(1);
      verify(() => messaging.subscribe('tonsoku.category.campaign')).called(1);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString('tonsoku-notification-topics'),
        '{"menu":true,"campaign":true}',
      );
      expect(done.value, 1);
    });

    /// **待ちきれなければ許可だけ取り、何も保存しない。** 空の `{}` を焼くと
    /// 「保存済み」と見なされて、カテゴリが届いた後も二度と貼られない
    testWidgets('5 秒待っても届かなければ、空の購読を保存しない', (tester) async {
      final done = await pumpCounting(
        tester,
        categoriesStream: () => feed.stream,
      );
      await tester.tap(find.text(AppMessages.ja.onboardingNext));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppMessages.ja.onboardingAllow));
      await tester.pump(const Duration(seconds: 4));
      verifyNever(messaging.request);

      await tester.pump(const Duration(seconds: 2));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // 許可は利用者の意思なので取る
      verify(messaging.request).called(1);
      verifyNever(() => messaging.subscribe(any()));
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.containsKey('tonsoku-notification-topics'),
        isFalse,
        reason: '空の購読（{}）が保存されている',
      );
      expect(done.value, 1, reason: '待ちきれなくても閉じる');
    });
  });
}
