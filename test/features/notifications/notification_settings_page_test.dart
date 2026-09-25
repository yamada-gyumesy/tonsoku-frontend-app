import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tonsoku/core/i18n/app_locale.dart';
import 'package:tonsoku/core/storage/preferences_provider.dart';
import 'package:tonsoku/core/theme/app_theme.dart';
import 'package:tonsoku/features/home/data/article_providers.dart';
import 'package:tonsoku/features/notifications/data/messaging_service.dart';
import 'package:tonsoku/features/notifications/presentation/notification_settings_controller.dart';
import 'package:tonsoku/features/notifications/presentation/notification_settings_page.dart';
import 'package:tonsoku/features/notifications/presentation/widgets/notification_toggle_row.dart';
import 'package:tonsoku/shared/models/article_meta.dart';
import 'package:tonsoku/shared/models/category.dart';

class _MockMessaging extends Mock implements MessagingService {}

/// 通知設定の画面。**保存ボタンは無く、触った時点で反映する。**
void main() {
  const categories = [
    Category(slug: 'menu', label: '新メニュー', description: '新商品の発売'),
    Category(slug: 'campaign', label: 'キャンペーン'),
  ];

  late _MockMessaging messaging;

  setUp(() {
    messaging = _MockMessaging();
    when(() => messaging.tokenRefresh).thenAnswer((_) => const Stream.empty());
    when(() => messaging.subscribe(any())).thenAnswer((_) async {});
    when(() => messaging.unsubscribe(any())).thenAnswer((_) async {});
    when(messaging.token).thenAnswer((_) async => 'tok-1');
    when(messaging.openSettings).thenAnswer((_) async {});
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    Map<String, Object> prefs = const {},
    EdgeInsets systemInsets = EdgeInsets.zero,
    List<ArticleMeta> feed = const [],
  }) async {
    // **表示言語を固定する。** 既定は端末の言語設定から推定するので、
    // 指定しないと実行環境（テストは en）で文言が変わる
    SharedPreferences.setMockInitialValues({'app_locale': 'ja', ...prefs});
    final store = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(store),
          messagingServiceProvider.overrideWithValue(messaging),
          categoriesProvider.overrideWith((ref) => Stream.value(categories)),
          // RSS の写し先を決めるのに見る（日本語は見ずに日本語のフィード）
          feedProvider.overrideWith((ref) => Stream.value(feed)),
        ],
        child: MaterialApp(
          theme: AppTheme.light(AppLocale.ja),
          home: MediaQuery(
            data: MediaQueryData(padding: systemInsets),
            child: const NotificationSettingsPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// **画面に入れてから押す。** 説明とサンプルで縦が埋まるので、テストの
  /// 既定サイズ（800×600）では下の行が画面外に出る
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
  }

  Finder rowFor(String label) =>
      find.widgetWithText(NotificationToggleRow, label);

  bool isDisabled(WidgetTester tester, String label) =>
      tester.widget<NotificationToggleRow>(rowFor(label)).onChanged == null;

  /// **引っ張って更新はどの画面にも要る**（カテゴリは配信から引いている）
  testWidgets('引っ張って更新できる', (tester) async {
    when(
      messaging.currentPermission,
    ).thenAnswer((_) async => NotificationPermission.granted);

    await pumpPage(tester);
    expect(find.byType(RefreshIndicator), findsOneWidget);
  });

  /// **RSS は開かずに URL を写す。** フィードは XML なので、ブラウザで開いても
  /// 読めるものが出てこない。読む人が欲しいのは購読先に貼る URL。
  testWidgets('RSS を押すと URL をコピーして知らせる', (tester) async {
    when(
      messaging.currentPermission,
    ).thenAnswer((_) async => NotificationPermission.granted);

    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
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

    await pumpPage(tester);
    await tapVisible(tester, find.text('RSS'));
    await tester.pump();
    await tester.pump();

    expect(copied, 'https://ton-soku.com/feed.xml');
    expect(find.text('RSSのURLをコピーしました'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });

  /// **記事の無いロケールの `feed.xml` は無い**（web の `rss.mts` が書かない）。
  /// 写した URL は購読先で初めて失敗するので、無い時は日本語のフィードを写す
  /// （web の `hasLocaleFeed`）。
  group('RSS の写し先はロケールのフィードの有無で決まる', () {
    Future<String?> copiedUrl(
      WidgetTester tester, {
      required List<ArticleMeta> feed,
    }) async {
      when(
        messaging.currentPermission,
      ).thenAnswer((_) async => NotificationPermission.granted);
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
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
      await pumpPage(tester, prefs: {'app_locale': 'en'}, feed: feed);
      await tapVisible(tester, find.text('RSS'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));
      return copied;
    }

    testWidgets('記事があればそのロケールのフィード', (tester) async {
      final url = await copiedUrl(
        tester,
        feed: [
          ArticleMeta(slug: 'a', title: 'A', createdAt: DateTime.utc(2026)),
        ],
      );
      expect(url, 'https://ton-soku.com/en/feed.xml');
    });

    testWidgets('無ければ日本語のフィード', (tester) async {
      final url = await copiedUrl(tester, feed: const []);
      expect(url, 'https://ton-soku.com/feed.xml');
    });
  });

  /// **Android のナビゲーションバーに最後の行が隠れて押せなくなった。**
  /// gyumesy が実機で見つけた。`pb-8`（32）だけだと足りない
  testWidgets('下の余白にシステムバーのぶんを足す', (tester) async {
    when(
      messaging.currentPermission,
    ).thenAnswer((_) async => NotificationPermission.granted);

    await pumpPage(tester, systemInsets: const EdgeInsets.only(bottom: 48));

    final padding =
        tester.widget<ListView>(find.byType(ListView)).padding! as EdgeInsets;
    // web の `pb-8`（32）＋ システムバー
    expect(padding.bottom, 80);
    // **左右は一覧では空けない。** 罫線を画面いっぱいに引くため、
    // 余白は要素ごとが持つ
    expect(padding.horizontal, 0);
  });

  group('マスターがオフ', () {
    setUp(() {
      when(
        messaging.currentPermission,
      ).thenAnswer((_) async => NotificationPermission.notDetermined);
    });

    /// **カテゴリ行は隠さない。** 隠すと「何が届くのか」が分からないまま
    /// 許可を求めることになる
    testWidgets('カテゴリ行は出すが触らせない', (tester) async {
      await pumpPage(tester);

      expect(find.byType(NotificationToggleRow), findsNWidgets(3));
      expect(isDisabled(tester, '新メニュー'), isTrue);
      expect(isDisabled(tester, 'キャンペーン'), isTrue);
      expect(isDisabled(tester, '通知を受け取る'), isFalse);
    });

    /// **オフにするのではなく触らせないだけ。** オフにすると、マスターを
    /// 入れ直した時に前の選択が消える
    testWidgets('保存済みの値は残したまま出す', (tester) async {
      await pumpPage(
        tester,
        prefs: {
          'flutter.tonsoku-notification-topics': jsonEncode({
            'menu': true,
            'campaign': false,
          }),
        },
      );

      expect(
        tester.widget<NotificationToggleRow>(rowFor('新メニュー')).value,
        isTrue,
      );
      expect(
        tester.widget<NotificationToggleRow>(rowFor('キャンペーン')).value,
        isFalse,
      );
    });

    testWidgets('マスターを入れると全トピックが購読される', (tester) async {
      when(
        messaging.request,
      ).thenAnswer((_) async => NotificationPermission.granted);

      await pumpPage(tester);
      await tapVisible(tester, rowFor('通知を受け取る'));
      await tester.pumpAndSettle();

      expect(isDisabled(tester, '新メニュー'), isFalse);
      expect(
        tester.widget<NotificationToggleRow>(rowFor('新メニュー')).value,
        isTrue,
      );
      verify(() => messaging.subscribe('tonsoku.category.menu')).called(1);
    });
  });

  group('拒否されている', () {
    setUp(() {
      when(
        messaging.currentPermission,
      ).thenAnswer((_) async => NotificationPermission.denied);
    });

    /// **アプリからは許可し直せない**ので、行き先は設定アプリだけ
    testWidgets('マスターを押すと設定アプリを開く', (tester) async {
      await pumpPage(tester);

      // **「設定から許可してください」とは書かない。** 押せば飛ぶ導線の隣に
      // 書くと、自分で設定を探しに行かせることになる
      expect(find.textContaining('端末の設定から'), findsNothing);
      await tapVisible(tester, rowFor('通知を受け取る'));
      verify(messaging.openSettings).called(1);
      verifyNever(messaging.request);
    });
  });

  group('マスターがオン', () {
    setUp(() {
      when(
        messaging.currentPermission,
      ).thenAnswer((_) async => NotificationPermission.granted);
    });

    Future<void> pumpGranted(
      WidgetTester tester, {
      Map<String, bool> topics = const {'menu': true, 'campaign': true},
    }) => pumpPage(
      tester,
      prefs: {
        'flutter.tonsoku-notification-topics': jsonEncode(topics),
        'flutter.tonsoku-notification-token': 'tok-1',
      },
    );

    testWidgets('保存ボタンは無い', (tester) async {
      await pumpGranted(tester);
      expect(find.text('設定を保存'), findsNothing);
    });

    testWidgets('切ると即座に反映される', (tester) async {
      await pumpGranted(tester);

      await tapVisible(tester, rowFor('新メニュー'));
      await tester.pumpAndSettle();

      verify(() => messaging.unsubscribe('tonsoku.category.menu')).called(1);
      expect(
        tester.widget<NotificationToggleRow>(rowFor('新メニュー')).value,
        isFalse,
      );
    });

    testWidgets('失敗したら戻して知らせる', (tester) async {
      when(() => messaging.unsubscribe(any())).thenThrow(Exception('offline'));
      await pumpGranted(tester);

      await tapVisible(tester, rowFor('新メニュー'));
      await tester.pump();
      await tester.pump();

      expect(find.text('エラーが発生しました'), findsOneWidget);
      expect(
        tester.widget<NotificationToggleRow>(rowFor('新メニュー')).value,
        isTrue,
      );
      // トーストの 3 秒タイマーを流す
      await tester.pump(const Duration(seconds: 4));
    });
  });
}
