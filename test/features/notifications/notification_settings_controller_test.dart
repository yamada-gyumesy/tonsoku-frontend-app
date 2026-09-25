import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tonsoku/core/storage/preferences_provider.dart';
import 'package:tonsoku/features/notifications/data/messaging_service.dart';
import 'package:tonsoku/features/notifications/presentation/notification_settings_controller.dart';

class _MockMessaging extends Mock implements MessagingService {}

/// 通知設定の振る舞い。
///
/// **web と違うのは 3 点。**
/// 1. サーバーに聞かない（localStorage が消えるブラウザの事情はアプリに無い）
/// 2. **保存ボタンが無く、触った時点で反映する**
/// 3. マスターは OS の許可そのもの
void main() {
  const categories = ['menu', 'campaign'];
  late _MockMessaging messaging;

  setUp(() {
    messaging = _MockMessaging();
    when(() => messaging.tokenRefresh).thenAnswer((_) => const Stream.empty());
    when(() => messaging.subscribe(any())).thenAnswer((_) async {});
    when(() => messaging.unsubscribe(any())).thenAnswer((_) async {});
    when(messaging.token).thenAnswer((_) async => 'tok-1');
  });

  Future<ProviderContainer> boot({Map<String, Object> prefs = const {}}) async {
    SharedPreferences.setMockInitialValues(prefs);
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
        messagingServiceProvider.overrideWithValue(messaging),
      ],
    );
    addTearDown(container.dispose);
    container.read(notificationSettingsControllerProvider);
    // build() が microtask で refresh() を呼ぶので 1 回落とす
    await Future<void>.delayed(Duration.zero);
    return container;
  }

  NotificationSettingsState read(ProviderContainer c) =>
      c.read(notificationSettingsControllerProvider);
  NotificationSettingsController notifier(ProviderContainer c) =>
      c.read(notificationSettingsControllerProvider.notifier);

  group('開いた時', () {
    test('許可されていなければマスターはオフ', () async {
      when(
        messaging.currentPermission,
      ).thenAnswer((_) async => NotificationPermission.notDetermined);

      final c = await boot();
      expect(read(c).enabled, isFalse);
      expect(read(c).permission, NotificationPermission.notDetermined);
    });

    test('拒否も区別して持つ', () async {
      when(
        messaging.currentPermission,
      ).thenAnswer((_) async => NotificationPermission.denied);

      final c = await boot();
      expect(read(c).permission, NotificationPermission.denied);
    });

    /// **サーバーに聞きに行かない。** web との一番の違い
    test('許可済みならローカルの保存を読む', () async {
      when(
        messaging.currentPermission,
      ).thenAnswer((_) async => NotificationPermission.granted);

      final c = await boot(
        prefs: {
          'flutter.tonsoku-notification-topics': jsonEncode({
            'menu': true,
            'campaign': false,
          }),
          'flutter.tonsoku-notification-token': 'tok-1',
        },
      );

      expect(read(c).enabled, isTrue);
      expect(read(c).topics.isOn('menu'), isTrue);
      expect(read(c).topics.isOn('campaign'), isFalse);
    });

    test('権限を取れなくても読み込み中で止まらない', () async {
      when(messaging.currentPermission).thenThrow(Exception('no firebase'));

      final c = await boot();
      expect(read(c).loading, isFalse);
    });
  });

  group('マスターを入れる', () {
    setUp(() {
      when(
        messaging.currentPermission,
      ).thenAnswer((_) async => NotificationPermission.notDetermined);
      when(
        messaging.request,
      ).thenAnswer((_) async => NotificationPermission.granted);
    });

    /// **初回は全部オンで購読する。** 「通知を受け取る」を入れた人は通知が
    /// 欲しいので、そこからさらに 1 つずつ選ばせない
    test('ローカルに保存が無ければ全トピックを購読する', () async {
      final c = await boot();
      final ok = await notifier(c).enableMaster(categories);

      expect(ok, isTrue);
      expect(read(c).enabled, isTrue);
      for (final id in categories) {
        expect(read(c).topics.isOn(id), isTrue, reason: id);
        verify(() => messaging.subscribe('tonsoku.category.$id')).called(1);
      }
    });

    /// **カテゴリが 1 件も無いまま「設定済み」を焼かない。** 焼くと、後から
    /// カテゴリが届いても `stored != null` で購読が二度と貼られず、
    /// **許可はしたのに 1 通も来ない**状態が固定される。
    test('カテゴリが空なら何も保存せず、届いてから貼り直せる', () async {
      final c = await boot();

      // 圏外・低速で、カテゴリがまだ 1 件も届いていない
      final ok = await notifier(c).enableMaster(const []);

      expect(ok, isTrue, reason: '許可そのものは取れているので失敗ではない');
      expect(read(c).enabled, isTrue);
      verifyNever(() => messaging.subscribe(any()));
      expect(
        (await SharedPreferences.getInstance()).getString(
          'flutter.tonsoku-notification-topics',
        ),
        isNull,
        reason: '空を「設定済み」として焼いている',
      );

      // カテゴリが届いた後にもう一度通れば、今度は貼れる
      expect(await notifier(c).enableMaster(categories), isTrue);
      for (final id in categories) {
        verify(() => messaging.subscribe('tonsoku.category.$id')).called(1);
      }
    });

    /// **既に `{}` が焼かれている端末も救う。** テスト配信で踏んだ端末が
    /// これに当たる。**「全部オフ」とは区別が付く** —— あちらはキーが残る
    test('保存が空マップなら未設定として読み、貼り直す', () async {
      final c = await boot(
        prefs: {'flutter.tonsoku-notification-topics': jsonEncode({})},
      );

      expect(await notifier(c).enableMaster(categories), isTrue);
      for (final id in categories) {
        expect(read(c).topics.isOn(id), isTrue, reason: id);
        verify(() => messaging.subscribe('tonsoku.category.$id')).called(1);
      }
    });

    /// **2 回目以降はローカルが優先。** 切ったものが勝手に戻らない
    test('ローカルに保存があればそちらに従う', () async {
      final c = await boot(
        prefs: {
          'flutter.tonsoku-notification-topics': jsonEncode({
            'menu': false,
            'campaign': true,
          }),
        },
      );
      await notifier(c).enableMaster(categories);

      expect(read(c).topics.isOn('menu'), isFalse);
      expect(read(c).topics.isOn('campaign'), isTrue);
      // **貼り直さない。** 既に購読済みのはずなので、押すたびに投げ直さない
      verifyNever(() => messaging.subscribe(any()));
    });

    test('許可されなければ拒否として画面に出す', () async {
      when(
        messaging.request,
      ).thenAnswer((_) async => NotificationPermission.denied);

      final c = await boot();
      await notifier(c).enableMaster(categories);

      expect(read(c).permission, NotificationPermission.denied);
      expect(read(c).enabled, isFalse);
    });

    test('トークンが取れなければ失敗を返す', () async {
      when(messaging.token).thenAnswer((_) async => null);

      final c = await boot();
      expect(await notifier(c).enableMaster(categories), isFalse);
    });
  });

  group('カテゴリを切り替える', () {
    setUp(() {
      when(
        messaging.currentPermission,
      ).thenAnswer((_) async => NotificationPermission.granted);
    });

    Future<ProviderContainer> granted({
      Map<String, bool> topics = const {'menu': true, 'campaign': true},
    }) => boot(
      prefs: {
        'flutter.tonsoku-notification-topics': jsonEncode(topics),
        'flutter.tonsoku-notification-token': 'tok-1',
      },
    );

    /// **保存ボタンは無い。** 押した時点で反映する
    test('切ると即座に購読を解除して保存する', () async {
      final c = await granted();
      final ok = await notifier(c).toggle('menu', on: false);

      expect(ok, isTrue);
      verify(() => messaging.unsubscribe('tonsoku.category.menu')).called(1);
      expect(read(c).topics.isOn('menu'), isFalse);

      final saved = jsonDecode(
        c
            .read(sharedPreferencesProvider)
            .getString('tonsoku-notification-topics')!,
      );
      expect(saved, {'menu': false, 'campaign': true});
    });

    /// **画面だけ変わって実際は購読できていない、を作らない**
    test('失敗したら元に戻す', () async {
      when(() => messaging.unsubscribe(any())).thenThrow(Exception('offline'));

      final c = await granted();
      final ok = await notifier(c).toggle('menu', on: false);

      expect(ok, isFalse);
      expect(read(c).topics.isOn('menu'), isTrue, reason: '戻していない');
      final saved = jsonDecode(
        c
            .read(sharedPreferencesProvider)
            .getString('tonsoku-notification-topics')!,
      );
      expect(saved, {'menu': true, 'campaign': true}, reason: '保存してしまっている');
    });

    test('反映中はその行を触らせない', () async {
      final c = await granted();
      // 解除を握って離さない
      final blocker = Completer<void>();
      when(
        () => messaging.unsubscribe(any()),
      ).thenAnswer((_) => blocker.future);

      final first = notifier(c).toggle('menu', on: false);
      await Future<void>.delayed(Duration.zero);
      expect(read(c).pending, contains('menu'));

      // 2 回目は素通りする（連打で購読と解除が入れ違わない）
      await notifier(c).toggle('menu', on: true);
      expect(read(c).topics.isOn('menu'), isFalse);

      blocker.complete();
      await first;
      expect(read(c).pending, isEmpty);
    });

    Map<String, dynamic> savedTopics(ProviderContainer c) =>
        jsonDecode(
              c
                  .read(sharedPreferencesProvider)
                  .getString('tonsoku-notification-topics')!,
            )
            as Map<String, dynamic>;

    /// **2 つ続けて押した時。** `pending` はカテゴリ単位なので、別の行なら
    /// 同時に走る。ここで保存・FCM・画面が食い違わないこと。
    group('別のカテゴリを同時に押した', () {
      /// **先に成功したほうが、まだ FCM に届いていない値まで保存しない。**
      /// 保存してしまうと、後から失敗したほうが「保存済み」になって
      /// 二度と貼り直されない
      test('通ったキーだけ保存する', () async {
        final menu = Completer<void>();
        final campaign = Completer<void>();
        when(
          () => messaging.unsubscribe('tonsoku.category.menu'),
        ).thenAnswer((_) => menu.future);
        when(
          () => messaging.unsubscribe('tonsoku.category.campaign'),
        ).thenAnswer((_) => campaign.future);

        final c = await granted();
        final a = notifier(c).toggle('menu', on: false);
        final b = notifier(c).toggle('campaign', on: false);
        await Future<void>.delayed(Duration.zero);

        // menu だけ通す
        menu.complete();
        await a;

        expect(savedTopics(c), {
          'menu': false,
          'campaign': true,
        }, reason: 'campaign はまだ FCM に届いていないのに保存されている');

        campaign.completeError(Exception('offline'));
        expect(await b, isFalse);
        expect(savedTopics(c), {'menu': false, 'campaign': true});
      });

      /// **先に失敗したほうが、後から成功したほうの画面まで巻き戻さない。**
      /// 全体のスナップショットを取って戻すとこれが起きる
      test('失敗しても隣は巻き戻さない', () async {
        final menu = Completer<void>();
        when(
          () => messaging.unsubscribe('tonsoku.category.menu'),
        ).thenAnswer((_) => menu.future);

        final c = await granted();
        final a = notifier(c).toggle('menu', on: false);
        await notifier(c).toggle('campaign', on: false);

        menu.completeError(Exception('offline'));
        expect(await a, isFalse);

        expect(read(c).topics.isOn('menu'), isTrue, reason: '失敗した側は戻る');
        expect(
          read(c).topics.isOn('campaign'),
          isFalse,
          reason: '成功した側まで戻っている',
        );
        expect(savedTopics(c), {'menu': true, 'campaign': false});
      });
    });

    test('トークンが取れなければ切り替えない', () async {
      when(messaging.token).thenAnswer((_) async => null);

      final c = await granted();
      expect(await notifier(c).toggle('menu', on: false), isFalse);
      expect(read(c).topics.isOn('menu'), isTrue);
    });
  });

  /// **設定アプリへ送り出したことを覚えておく。**
  ///
  /// Android は権限を取り消されるとプロセスを殺すので、戻ってきた時は
  /// コールドスタートになりうる。印が無いとホームから始まってしまう。
  group('設定アプリへの行き来', () {
    setUp(() {
      when(
        messaging.currentPermission,
      ).thenAnswer((_) async => NotificationPermission.denied);
      when(messaging.openSettings).thenAnswer((_) async {});
    });

    test('開く前に印を付ける', () async {
      final c = await boot();
      await notifier(c).openSettings();

      expect(
        c
            .read(sharedPreferencesProvider)
            .getBool('tonsoku-notification-returning'),
        isTrue,
      );
    });

    /// **生きたまま戻れたら消す。** 残すと、次に普通に起動した時にも
    /// この画面が開く
    test('戻ってきたら印を消す', () async {
      final c = await boot();
      await notifier(c).openSettings();
      await notifier(c).clearReturning();

      expect(
        c
            .read(sharedPreferencesProvider)
            .getBool('tonsoku-notification-returning'),
        isNull,
      );
    });
  });

  /// 端末を復元するとローカルの設定だけが戻り、購読は無い状態になりうる
  group('トークンが変わった時', () {
    test('保存済みの設定を貼り直す', () async {
      when(
        messaging.currentPermission,
      ).thenAnswer((_) async => NotificationPermission.granted);
      when(messaging.token).thenAnswer((_) async => 'tok-NEW');

      await boot(
        prefs: {
          'flutter.tonsoku-notification-topics': jsonEncode({
            'menu': true,
            'campaign': false,
          }),
          'flutter.tonsoku-notification-token': 'tok-OLD',
        },
      );
      await Future<void>.delayed(Duration.zero);

      verify(() => messaging.subscribe('tonsoku.category.menu')).called(1);
      verify(
        () => messaging.unsubscribe('tonsoku.category.campaign'),
      ).called(1);
    });

    test('同じトークンなら貼り直さない', () async {
      when(
        messaging.currentPermission,
      ).thenAnswer((_) async => NotificationPermission.granted);

      await boot(
        prefs: {
          'flutter.tonsoku-notification-topics': jsonEncode({'menu': true}),
          'flutter.tonsoku-notification-token': 'tok-1',
        },
      );
      await Future<void>.delayed(Duration.zero);

      verifyNever(() => messaging.subscribe(any()));
    });
  });
}
