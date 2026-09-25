import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// 受け取り側の用意。**画面（通知設定）とは別の関心事**なのでここに分ける。
/// gyumesy-frontend-app の `push_bootstrap.dart` を写した（チャンネル ID・色だけ違う）。
///
/// アプリが前面に居る間、**FCM は既定では通知を出さない**（データをアプリに
/// 渡すだけ）。web はブラウザの Service Worker が出してくれるので、この用意は
/// 要らなかった。
///
/// **出し方を OS で分ける。**
/// - iOS は FCM 自身に出させる（`setForegroundNotificationPresentationOptions`）
/// - Android にはその仕組みが無いので、ローカル通知で自分で出す
///
/// **両方でローカル通知を使わない。** iOS で両方やると同じ通知が 2 つ出る。
Future<void> registerPushHandlers() async {
  // **終了状態から通知で起動した時の 1 通。** `onMessageOpenedApp` には
  // 流れてこないので、両方を見ないと**その状態でだけ飛ばない**という
  // 再現しにくい形になる
  final initial = await FirebaseMessaging.instance.getInitialMessage();
  if (initial != null) pushedLink.value = initial.data['url'] as String?;

  // 背面から復帰した時
  FirebaseMessaging.onMessageOpenedApp.listen(
    (m) => pushedLink.value = m.data['url'] as String?,
  );

  if (defaultTargetPlatform == TargetPlatform.iOS) {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
    return;
  }
  if (defaultTargetPlatform != TargetPlatform.android) return;

  await _local.initialize(
    settings: const InitializationSettings(
      // **ランチャーアイコンを指さない。** Android は小アイコンをアルファの
      // マスクとしてしか見ないので、不透明なカラーアイコンは全面が塗り潰されて
      // 白い四角になる。素材は `tool/build_notification_icon.py` が作る。
      // **マニフェストの `default_notification_icon` と同じ絵にすること**
      // ——ずれると前面と背面で違う絵が出る（書き方は [_smallIcon] の doc）
      android: AndroidInitializationSettings(_smallIcon),
    ),
    // **前面の通知はアプリが出したもの**なので、FCM のタップ経路
    // （`onMessageOpenedApp`）に乗らない。ここで拾わないと**前面で出た通知を
    // タップした時だけ飛ばない**
    onDidReceiveNotificationResponse: (response) =>
        pushedLink.value = response.payload,
  );
  await _local
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(_channel);

  FirebaseMessaging.onMessage.listen(_showOnAndroid);
}

/// 通知をタップして開く先（`data.url`）。**画面が立ち上がる前にも積まれる。**
///
/// 通知は**アプリが無い状態からでも**開かれるので、行き先をここに置いて
/// 画面側（`TonsokuApp`）が拾う。直に `GoRouter` を触れないのは、
/// [registerPushHandlers] が `runApp` より前に走るため。
///
/// **ユニバーサルリンク / App Links（リリース整備の Issue #9）もここへ積むこと**
/// （gyumesy の `app.dart` がそうしている）。入口は別でも行き先の決め方は同じ
/// （`deepLinkTarget`）なので、分けて持つと片方だけ面が増えた時に食い違う。
final pushedLink = ValueNotifier<String?>(null);

final _local = FlutterLocalNotificationsPlugin();

/// 通知の小アイコン。**マニフェストの `default_notification_icon` と同じ絵**
/// （`android/app/src/main/AndroidManifest.xml`）。
///
/// **名前だけを渡す。** マニフェストは XML のリソース参照なので
/// `@drawable/ic_stat_notification` と書くが、こちらは
/// `getResources().getIdentifier(name, "drawable", packageName)` の引数
/// （`FlutterLocalNotificationsPlugin.java` の `getDrawableResourceId`）。
///
/// **`@drawable/` 付きでも動く**（Android の `getIdentifier` は先頭の `@` を
/// 剥がす。gyumesy の実機で確かめてある）。**それでも名前だけにするのは、
/// プラグインが求めている形がこちらだから。** `@` を剥がす親切に寄りかからない。
///
/// **ランチャーアイコン（`ic_launcher`）を指さないこと。** カラーで不透明なので
/// 全面が塗り潰されて白い四角になる（gyumesy が踏んだ。素材は
/// `tool/build_notification_icon.py`）。
const _smallIcon = 'ic_stat_notification';

/// Android 8 以降は**チャンネルが要る**。作らずに出すと既定チャンネルに落ちて、
/// 端末側の通知設定に項目が出ない。
///
/// **`AndroidManifest.xml` の既定チャンネル指定と同じ ID にすること。**
/// ずれると、アプリが背面に居る時（FCM が自分で出す時）だけ別チャンネル扱いになり、
/// 端末側のオン・オフが 2 つに割れる。
///
/// **カテゴリごとにチャンネルを分けない。** 分けると、購読のオン・オフを
/// アプリ側（トピック）と端末側（チャンネル）の 2 か所で持つことになり、
/// 片方だけ切った人に何も届かない理由が説明できなくなる。
///
/// **名前（`お知らせ`）は端末の通知設定に出る。** gyumesy と同じ語で、
/// ブランド名を含まない。
const _channel = AndroidNotificationChannel(
  'tonsoku_default',
  'お知らせ',
  importance: Importance.defaultImportance,
);

/// 小アイコンに乗る色。**`res/values/colors.xml` の `notification_color` と
/// 同じ値**（背面で FCM が出す時はそちらが使われる）。とん速のロゴの赤
/// （`AppColors.light` の `primary`）。**トークンから引かない**のは、ネイティブ側と
/// 同じ 1 色に固定するため（テーマで変わると前面と背面で色が割れる）。
const _accent = Color(0xFFA7232A);

Future<void> _showOnAndroid(RemoteMessage message) async {
  final notification = message.notification;
  // **通知の中身が無いものは出さない**（データだけのメッセージは表示を意図していない）
  if (notification == null) return;

  await _local.show(
    id: notification.hashCode,
    title: notification.title,
    body: notification.body,
    // **行き先を持たせる。** 渡さないと、前面で出た通知だけ押しても何も起きない
    payload: message.data['url'] as String?,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        icon: _smallIcon,
        color: _accent,
      ),
    ),
  );
}
