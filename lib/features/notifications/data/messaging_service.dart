import 'package:app_settings/app_settings.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// 通知の権限。**web の `Notification.permission` と同じ 3 値。**
///
/// web の `unsupported` は作らない —— ネイティブは必ず対応する。
enum NotificationPermission { granted, denied, notDetermined }

/// FCM と OS の通知設定を触る所を 1 箇所に閉じる（gyumesy-frontend-app を写した）。
///
/// **カテゴリごとの通知チャンネルは作らない。** Android にはチャンネルという
/// 単位があるが、**iOS には無い**（`UNNotificationCategory` は通知に付ける
/// アクションボタンの定義で、設定アプリで切れるものではない）。片方だけ
/// OS と連動する画面になるうえ、配信側が各メッセージに `channel_id` を
/// 入れないと効かないので、**購読の管理はアプリ内に閉じる**。
///
/// **画面から `FirebaseMessaging` を直接呼ばない**（テストで差し替えられなくなる）。
abstract class MessagingService {
  Future<NotificationPermission> currentPermission();

  /// 権限を求める。**まだ聞いていない時だけ OS のダイアログが出る。**
  Future<NotificationPermission> request();

  /// **トークンが取れなければ `null`。** web も `getToken` の失敗を握り潰して
  /// 何もしない。ここで投げると、権限はあるのに画面が壊れる。
  Future<String?> token();

  /// トークンが差し替わったことを知らせる。購読は貼り直しが要る。
  Stream<String> get tokenRefresh;

  Future<void> subscribe(String topic);
  Future<void> unsubscribe(String topic);

  /// 端末の通知設定を開く。**web には無い**（ブラウザは開いてやれない）。
  Future<void> openSettings();
}

class FirebaseMessagingService implements MessagingService {
  FirebaseMessagingService(this._messaging);

  final FirebaseMessaging _messaging;

  /// **送る側と同じ名前**にする。ここがずれると、**購読はできるのに通知が
  /// 1 通も届かない**（画面からは気づけない壊れ方）。正は 3 か所で、どれも
  /// `tonsoku.category.<categories.json の slug>`（ロケールは入れない）:
  ///
  /// - 送る側: tonsoku-backend-batch の `app/notify/push.py` の `TOPIC`
  /// - web の購読口: tonsoku-frontend-web の `functions/api/fcm/topics.ts`
  ///   （`TOPIC_PREFIX` + `category` + slug。送る側と 2026-09-04 に合意済み）
  ///
  /// **アプリは web の購読口（`/api/fcm/topics`）を通さず、`subscribeToTopic`
  /// で直接購読する**（gyumesy と同じ）。あの口はブラウザが FCM の IID API を
  /// 叩けないために置いたもので、ネイティブの SDK は自分で購読できる。
  /// トピック名さえ揃っていれば、送る側から見て web とアプリの区別は無い。
  static String topicFor(String categoryId) => 'tonsoku.category.$categoryId';

  static NotificationPermission _from(AuthorizationStatus status) =>
      switch (status) {
        AuthorizationStatus.authorized ||
        // **暫定許可も許可として扱う。** iOS の provisional は通知が
        // 静かに届いている状態なので、「オフ」と見せると設定が噛み合わない
        AuthorizationStatus.provisional => NotificationPermission.granted,
        // **`deniedPermanently` も拒否。** 設定アプリからしか戻せない状態で、
        // アプリ側の扱いは `denied` と同じ（マスターを押すと設定アプリを開く）
        AuthorizationStatus.denied ||
        AuthorizationStatus.deniedPermanently => NotificationPermission.denied,
        AuthorizationStatus.notDetermined =>
          NotificationPermission.notDetermined,
      };

  @override
  Future<NotificationPermission> currentPermission() async =>
      _from((await _messaging.getNotificationSettings()).authorizationStatus);

  @override
  Future<NotificationPermission> request() async =>
      _from((await _messaging.requestPermission()).authorizationStatus);

  @override
  Future<String?> token() async {
    try {
      return await _messaging.getToken();
    } on FirebaseException catch (_) {
      // **投げる場合がある。** iOS は APNs のトークンが非同期に届くので、
      // 届く前に呼ぶと `apns-token-not-set` で落ちる（シミュレータでは
      // そもそも届かないので常にこれ）。**契約は「取れなければ null」**なので
      // ここで受ける —— 呼び出し側は null を「まだ購読できない」として扱う
      return null;
    }
  }

  @override
  Stream<String> get tokenRefresh => _messaging.onTokenRefresh;

  @override
  Future<void> subscribe(String topic) => _messaging.subscribeToTopic(topic);

  @override
  Future<void> unsubscribe(String topic) =>
      _messaging.unsubscribeFromTopic(topic);

  @override
  // **アプリ全体の設定ではなく通知の画面を直接開く。** 拒否を直すために
  // 開かせるので、着いた先でさらに探させない
  Future<void> openSettings() =>
      AppSettings.openAppSettings(type: AppSettingsType.notification);
}
