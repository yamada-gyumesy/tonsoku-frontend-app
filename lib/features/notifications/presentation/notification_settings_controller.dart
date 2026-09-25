import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tonsoku/core/storage/preferences_provider.dart';
import 'package:tonsoku/features/notifications/data/messaging_service.dart';
import 'package:tonsoku/features/notifications/data/notification_store.dart';
import 'package:tonsoku/features/notifications/domain/topic_selection.dart';

class NotificationSettingsState {
  const NotificationSettingsState({
    required this.permission,
    required this.topics,
    required this.pending,
    this.loading = false,
  });

  const NotificationSettingsState.loading()
    : permission = null,
      topics = const TopicSelection.empty(),
      pending = const {},
      loading = true;

  /// OS の通知許可。**これがマスターのトグルそのもの。**
  /// 読み込み中は `null`。
  final NotificationPermission? permission;

  /// カテゴリごとの購読。**保存ボタンは無く、触った時点で反映される。**
  final TopicSelection topics;

  /// いま反映中のカテゴリ。**その行のトグルは触らせない**
  /// （連打すると購読と解除が入れ違う）。
  final Set<String> pending;

  final bool loading;

  /// マスターが入っているか。
  bool get enabled => permission == NotificationPermission.granted;

  NotificationSettingsState copyWith({
    NotificationPermission? permission,
    TopicSelection? topics,
    Set<String>? pending,
    bool? loading,
  }) => NotificationSettingsState(
    permission: permission ?? this.permission,
    topics: topics ?? this.topics,
    pending: pending ?? this.pending,
    loading: loading ?? this.loading,
  );
}

final messagingServiceProvider = Provider<MessagingService>(
  (ref) => FirebaseMessagingService(FirebaseMessaging.instance),
);

final notificationStoreProvider = Provider<NotificationStore>(
  (ref) => NotificationStore(ref.watch(sharedPreferencesProvider)),
);

/// 通知設定の振る舞い。**gyumesy-frontend-app の同名のものをそのまま写した**
/// （トピック名と保存キーだけとん速のもの）。
///
/// **gyumesy が踏んだ「許可したのに購読 0 件のまま戻らない」（79d2ce4）を
/// 繰り返さない。** カテゴリが届く前に [enableMaster] が呼ばれても空の `{}` を
/// 焼かず（ここ）、焼かれた `{}` も未設定として読む（`NotificationStore.readTopics`）。
class NotificationSettingsController
    extends Notifier<NotificationSettingsState> {
  @override
  NotificationSettingsState build() {
    // **トークンが差し替わったら購読を貼り直す。** 購読はトークンに紐づくので、
    // 貼り直さないと設定は残ったまま通知だけ来なくなる
    final sub = _messaging.tokenRefresh.listen(_reapply);
    ref.onDispose(sub.cancel);

    Future.microtask(refresh);
    return const NotificationSettingsState.loading();
  }

  MessagingService get _messaging => ref.read(messagingServiceProvider);
  NotificationStore get _store => ref.read(notificationStoreProvider);

  /// **FCM に通っていて保存してよい値。**
  ///
  /// `state.topics` は押した瞬間に変わる（見た目の先取り）ので、そのまま
  /// 保存すると**まだ FCM に届いていないカテゴリまで「保存済み」になる**。
  /// 2 つ続けて押した時に、先に成功したほうがもう一方の未確定な値を焼いて
  /// しまい、そちらが失敗しても貼り直されない。**通ったキーだけここへ入れる。**
  TopicSelection _committed = const TopicSelection.empty();

  /// 権限とローカルの保存を読み直す。
  ///
  /// **戻ってくるたびに呼ぶ。** マスターは OS の許可そのものなので、設定アプリで
  /// 切られたらこの画面もそう見えなければならない。web は画面遷移のたびに
  /// 読み直すので、この経路は要らなかった。
  Future<void> refresh() async {
    final NotificationPermission permission;
    try {
      permission = await _messaging.currentPermission();
    } catch (_) {
      // **読み込み中のまま置き去りにしない。** Firebase の初期化に失敗して
      // いるとここが投げる。未許可として出しておけば、押した時にトーストで
      // 失敗が見える
      state = state.copyWith(
        permission: NotificationPermission.notDetermined,
        loading: false,
      );
      return;
    }

    // **ローカルが唯一の正。** web はここでサーバーに聞き直すが、それは
    // localStorage が消えうるブラウザの事情。アプリでは消えない
    _committed = _store.readTopics() ?? const TopicSelection.empty();
    state = state.copyWith(
      permission: permission,
      topics: _committed,
      loading: false,
    );

    if (permission == NotificationPermission.granted) {
      await _reapplyIfTokenChanged();
    }
  }

  /// 端末の復元でローカルだけが戻った場合に、購読を貼り直す。
  Future<void> _reapplyIfTokenChanged() async {
    final token = await _messaging.token();
    if (token == null) return;
    if (token == _store.readToken()) return;
    await _reapply(token);
  }

  Future<void> _reapply(String token) async {
    final topics = _store.readTopics();
    if (topics == null) return;
    try {
      await _applyToFcm(topics.values);
      await _store.writeToken(token);
    } catch (_) {
      // **黙って諦める。** 画面を開いていない時にも走るので、ここで
      // 見せる相手が居ない。次に開いた時にまた試す
    }
  }

  Future<void> _applyToFcm(Map<String, bool> topics) async {
    await Future.wait([
      for (final entry in topics.entries)
        entry.value
            ? _messaging.subscribe(FirebaseMessagingService.topicFor(entry.key))
            : _messaging.unsubscribe(
                FirebaseMessagingService.topicFor(entry.key),
              ),
    ]);
  }

  /// マスターを入れる。**まだ聞いていない時だけ OS のダイアログが出る。**
  ///
  /// 許可されたら、**保存済みが無ければ全カテゴリをオンにして購読する**。
  /// 「通知を受け取る」を入れた人は通知が欲しいので、そこからさらに 1 つずつ
  /// 選ばせない（要らないものだけ後で切ればよい）。
  ///
  /// 失敗したら `false`。
  ///
  /// [onPermissionDecided] は **OS のダイアログが閉じた直後**に 1 回だけ呼ぶ
  /// （許可・拒否のどちらでも。例外で抜けた時も呼ぶ）。**購読の完了を待たずに
  /// 先へ進みたい呼び手のため。** iOS は許可の直後にまだ APNs トークンが無く、
  /// `subscribeToTopic` が長く返らないことがある。
  Future<bool> enableMaster(
    List<String> categoryIds, {
    VoidCallback? onPermissionDecided,
  }) async {
    var decided = false;
    void decide() {
      if (decided) return;
      decided = true;
      onPermissionDecided?.call();
    }

    state = state.copyWith(loading: true);
    try {
      final permission = await _messaging.request();
      decide();
      if (permission != NotificationPermission.granted) {
        // **拒否されたら画面をその状態にする。** 保存ボタンが無いので、
        // web のように「次に開いた時に分かる」では遅い
        state = state.copyWith(permission: permission);
        return true;
      }

      final token = await _messaging.token();
      // **トークンが取れなければ何もしない。** 有効にしたつもりで届かない
      // 状態を作らない
      if (token == null) return false;

      final stored = _store.readTopics();
      final topics = stored ?? TopicSelection.allOn(categoryIds);
      // **購読するものが 1 つも無いなら、何も保存せずに終える。** カテゴリが
      // まだ届いていない／取得に失敗した状態で押されると、購読 0 件のまま
      // `{}` が焼かれ、**次に呼ばれても「保存済み」になって貼り直せない**。
      //
      // 許可そのものは取れているので、そこは反映して `true` を返す
      // （利用者から見て失敗ではない）。保存が無いままなので、カテゴリが
      // 届いた後にもう一度ここを通れば貼れる。
      if (topics.values.isEmpty) {
        state = state.copyWith(permission: NotificationPermission.granted);
        return true;
      }
      if (stored == null) await _applyToFcm(topics.values);
      _committed = topics;
      await _store.writeTopics(topics.values);
      await _store.writeToken(token);

      state = state.copyWith(
        permission: NotificationPermission.granted,
        topics: topics,
      );
      return true;
    } catch (_) {
      return false;
    } finally {
      // **必ず 1 回は呼ぶ。** 例外で抜けた時に呼ばないと、これを待って
      // いる呼び手が進めないまま取り残される
      decide();
      state = state.copyWith(loading: false);
    }
  }

  /// カテゴリを切り替える。**押した時点で反映する**（保存ボタンは無い）。
  ///
  /// 失敗したら元へ戻して `false` を返す。**画面だけ変わって実際は購読できて
  /// いない、という状態を作らない。**
  Future<bool> toggle(String categoryId, {required bool on}) async {
    if (state.pending.contains(categoryId)) return true;

    // **戻すのはこのカテゴリだけ。** 全体のスナップショットを取って戻すと、
    // 隣を同時に押していた時にそちらの結果まで巻き戻す
    final before = state.topics.isOn(categoryId);
    state = state.copyWith(
      topics: state.topics.toggled(categoryId, on: on),
      pending: {...state.pending, categoryId},
    );

    try {
      final token = await _messaging.token();
      if (token == null) throw StateError('token is not available');

      final topic = FirebaseMessagingService.topicFor(categoryId);
      // **FCM に反映できてから保存する。** 先に保存すると、失敗しても
      // 「保存済み」になって二度と貼り直されない
      if (on) {
        await _messaging.subscribe(topic);
      } else {
        await _messaging.unsubscribe(topic);
      }
      // **通ったキーだけ確定させる**（`state.topics` には隣の未確定な値が
      // 入っていることがある）
      _committed = _committed.toggled(categoryId, on: on);
      await _store.writeTopics(_committed.values);
      await _store.writeToken(token);
      return true;
    } catch (_) {
      state = state.copyWith(
        topics: state.topics.toggled(categoryId, on: before),
      );
      return false;
    } finally {
      state = state.copyWith(pending: {...state.pending}..remove(categoryId));
    }
  }

  /// 設定アプリを開く。
  ///
  /// **開く前に印を付ける。** Android は権限を取り消されるとプロセスを殺すので、
  /// 戻ってきた時はコールドスタートになりうる。起動時にこの印を見て、
  /// この画面へ戻す（[NotificationStore.readReturning] 参照）。
  Future<void> openSettings() async {
    await _store.writeReturning(value: true);
    await _messaging.openSettings();
  }

  /// 戻ってきたので印を消す。**画面が生きたまま戻れた時に呼ぶ**
  /// （消さないと、次に普通に起動した時までこの画面が開く）。
  Future<void> clearReturning() => _store.writeReturning(value: false);
}

final notificationSettingsControllerProvider =
    NotifierProvider<NotificationSettingsController, NotificationSettingsState>(
      NotificationSettingsController.new,
    );
