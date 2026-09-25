import 'dart:convert';

import 'package:tonsoku/features/notifications/domain/topic_selection.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 通知の購読状態の保存先。**アプリではここが唯一の正。**
/// gyumesy-frontend-app を写した（保存キーだけとん速のもの）。
///
/// web は localStorage が消えうる（プライベートウィンドウ・サイトデータの削除）
/// ので、消えていたらサーバーから取り直す経路を持っている。**アプリでは消えない**
/// のでその経路は要らない。
///
/// 代わりに**トークンも一緒に持つ**。購読は FCM のトークンに紐づくので、
/// 端末を復元すると**ここの設定だけが戻り、購読は無い**状態になりうる
/// （Android の自動バックアップ / iOS の iCloud 復元は `SharedPreferences` を
/// 復元するが、トークンは新しくなる）。保存時のトークンと違っていたら貼り直す。
class NotificationStore {
  const NotificationStore(this._prefs);

  final SharedPreferences _prefs;

  /// **キーはとん速のもの**（web の `TOPICS_KEY` と同じ `tonsoku-` 始まり）。
  static const _topicsKey = 'tonsoku-notification-topics';
  static const _tokenKey = 'tonsoku-notification-token';
  static const _returningKey = 'tonsoku-notification-returning';

  /// まだ一度も有効にしていなければ `null`。
  ///
  /// **「全部オフ」と「未設定」は違う。** 未設定は「有効にする」ボタンを出す状態、
  /// 全部オフはトグルを出したうえで全部切ってある状態。
  TopicSelection? readTopics() {
    final raw = _prefs.getString(_topicsKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final values = {
        for (final entry in decoded.entries)
          if (entry.key is String && entry.value is bool)
            entry.key as String: entry.value as bool,
      };
      // **空は未設定として返す。** カテゴリが 1 件も無い状態で有効にされると
      // `{}` が焼かれ、以後「保存済み」と見なされて**購読が二度と貼られない**
      // （許可はしたのに 1 通も来ない）。既にそう焼かれた端末もここで救う。
      //
      // **「全部オフ」とは区別が付く** —— あちらはキーが残って値が false。
      if (values.isEmpty) return null;
      return TopicSelection(values);
    } on FormatException {
      // 壊れていたら未設定として扱う。**握り潰すのはここだけ**
      // ——保存の失敗はトーストで見せる
      return null;
    }
  }

  Future<void> writeTopics(Map<String, bool> topics) =>
      _prefs.setString(_topicsKey, jsonEncode(topics));

  String? readToken() => _prefs.getString(_tokenKey);

  Future<void> writeToken(String token) => _prefs.setString(_tokenKey, token);

  /// **設定アプリへ送り出したまま戻ってきていないか。**
  ///
  /// Android は**実行時権限を取り消されるとアプリのプロセスを殺す**
  /// （実測: `pm revoke POST_NOTIFICATIONS` で pid が消える）。通知設定から
  /// 設定アプリへ行って通知を切ると、戻った時にコールドスタートになり、
  /// 初期ルート（ホーム）から始まってしまう。
  ///
  /// **Flutter の状態復元では直らなかった**（`restorationScopeId` と
  /// `restorablePush` を入れて実機で試したが、殺した後はホームに戻った）ので、
  /// 送り出す時に印を付けて、起動時に見る。**殺されようが殺されまいが同じ
  /// 結果**になるぶん、こちらのほうが読みやすい。
  bool readReturning() => _prefs.getBool(_returningKey) ?? false;

  Future<void> writeReturning({required bool value}) => value
      ? _prefs.setBool(_returningKey, true)
      : _prefs.remove(_returningKey);
}
