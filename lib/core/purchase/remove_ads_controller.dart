import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tonsoku/core/purchase/purchase_gateway.dart';
import 'package:tonsoku/core/storage/preferences_provider.dart';

/// 広告を外す課金（買い切り）の状態。
@immutable
class RemoveAdsState {
  const RemoveAdsState({
    this.purchased = false,
    this.pending = false,
    this.busy = false,
    this.price,
  });

  /// 買ってある。**真なら広告を一切出さない**（`AdConfig.adsRemoved`）。
  final bool purchased;

  /// 保留中の購入がある（支払いを待っている）。**広告はまだ外さない。**
  final bool pending;

  /// 購入・復元の途中（ストアのシートを出している・購入記録を聞いている）。
  final bool busy;

  /// ストアの表示価格（例: `¥550`）。**取れるまでは null**（金額をアプリで
  /// 持たない。three と同じ）。
  final String? price;

  RemoveAdsState copyWith({
    bool? purchased,
    bool? pending,
    bool? busy,
    String? price,
  }) => RemoveAdsState(
    purchased: purchased ?? this.purchased,
    pending: pending ?? this.pending,
    busy: busy ?? this.busy,
    price: price ?? this.price,
  );
}

/// 購入・復元を押した結果。画面はこれで知らせる文言を選ぶ。
enum RemoveAdsResult {
  /// 買えた（広告はもう消えている）。
  purchased,

  /// 復元できた。
  restored,

  /// 復元できる購入が無い。
  notFound,

  /// 保留中（支払いが済んだら外れる）。
  pending,

  /// ストアのシートで閉じた。**何も知らせない**（本人が閉じた）。
  canceled,

  /// 買えなかった・復元できなかった。
  failed,

  /// ストアに繋がらない（圏外・ストアのアプリが無い・商品が取れない）。
  unavailable,
}

/// 広告を外す課金（Issue #42）。**判定は端末の保存とストアの購入記録だけで行い、
/// サーバーは持たない**（買い切りなので。ユーザーの決定）。
///
/// - **端末に残す**（[prefsKey]）。起動した瞬間から広告を出さないため
///   （ストアの返事を待つと、その間に広告の SDK・同意・ATT が走る）
/// - **起動のたびにストアの購入記録と突き合わせる**（[start]）
///
/// ## 返金・取り消しの扱い
///
/// three はサーバーがストアの通知（App Store Server Notifications / Play の
/// RTDN）を受けて取り消しを反映し、アプリはサーバーに従うだけだった。
/// とん速はサーバーを持たないので、**起動時の突き合わせでストアが「持って
/// いない」とはっきり答えた時だけ、端末の記録を消して広告を戻す**（返金・
/// 取り消し・ファミリー共有から外れた等。どちらのストアも、取り消された購入を
/// 「持っているもの」に含めない。`InAppPurchaseGateway` の doc）。
///
/// **答えが得られない時（圏外・ストアのアプリが無い・エラー）は端末の記録の
/// まま**にする。買った人が圏外で起動しただけで広告が戻るほうが、返金した人に
/// 広告が出ない取りこぼし（1 人ぶんの広告収入）より害が大きい。
///
/// **「購入を復元」では消さない**（押した人から取り上げない。消すのは起動時の
/// 突き合わせだけ）。
///
/// 起動の途中で取り消しに気づいた時は、広告はその場で始まり直す
/// （`startAdsAfterOnboarding`）。
///
/// ## テスト
///
/// **テストでは誰も [start] を呼ばない**ので、既存の画面のテストはストアに
/// 触れない（`AdsController` と同じ）。価格も [start] の後にしか取りに行かない。
class RemoveAdsController extends Notifier<RemoveAdsState> {
  /// 買ったことを残す鍵。
  static const prefsKey = 'ads_removed';

  bool _started = false;
  StreamSubscription<PurchaseUpdate>? _sub;

  /// 押した購入の結果を待っている間だけ持つ。
  Completer<RemoveAdsResult>? _buying;

  @override
  RemoveAdsState build() {
    ref.onDispose(() {
      unawaited(_sub?.cancel());
      final buying = _buying;
      if (buying != null && !buying.isCompleted) {
        buying.complete(RemoveAdsResult.failed);
      }
    });
    final purchased =
        ref.read(sharedPreferencesProvider).getBool(prefsKey) ?? false;
    return RemoveAdsState(purchased: purchased);
  }

  PurchaseGateway get _gateway => ref.read(purchaseGatewayProvider);

  void _listen() {
    _sub ??= _gateway.updates.listen(_onUpdate);
  }

  /// 起動時に 1 回。**購入の知らせの購読を始め、ストアの購入記録と突き合わせる。**
  /// 呼ぶのは `main.dart` の 1 か所だけ（最初のフレームの後。ダイアログは
  /// 出さないので、オンボーディングを待たない）。
  ///
  /// 購読を起動時に始めるのは、**アプリの外や前回の起動で済んだ購入（保留が
  /// 払われた・ストアが送り直した未完了の取引）が起動直後に届く**ため。
  Future<void> start() async {
    if (_started) return;
    _started = true;
    _listen();
    final ownership = await _gateway.queryOwnership();
    if (!ref.mounted) return;
    switch (ownership) {
      case Ownership.owned:
        _grant();
      case Ownership.pending:
        state = state.copyWith(pending: true);
      case Ownership.notOwned:
        if (state.purchased) {
          debugPrint('ストアに購入の記録が無いので、広告を戻します');
          _revoke();
        } else if (state.pending) {
          state = state.copyWith(pending: false);
        }
      case Ownership.unknown:
        break;
    }
    await refreshProduct();
  }

  /// 表示価格を取る（まだ取れていなければ）。**[start] の前は何もしない。**
  /// 起動時に取れなかった時（圏外など）のために、メニューとマップが開いた時にも
  /// 呼ぶ。
  Future<void> refreshProduct() async {
    if (!_started || state.price != null || state.purchased) return;
    final product = await _gateway.loadProduct();
    if (!ref.mounted || product == null) return;
    state = state.copyWith(price: product.price);
  }

  /// 買う。**ストアのシートを閉じるまで待つ**（保留になった時はそこで返る）。
  Future<RemoveAdsResult> buy() async {
    if (state.purchased) return RemoveAdsResult.purchased;
    if (state.busy) return RemoveAdsResult.canceled;
    _listen();
    state = state.copyWith(busy: true);
    final buying = _buying = Completer<RemoveAdsResult>();
    final started = await _gateway.buy();
    if (!ref.mounted) return RemoveAdsResult.failed;
    switch (started) {
      case BuyStart.started:
        break;
      case BuyStart.unavailable:
        _finishBuying(RemoveAdsResult.unavailable);
      case BuyStart.failed:
        _finishBuying(RemoveAdsResult.failed);
    }
    return buying.future;
  }

  /// 復元する（ストアの購入記録を見る）。**持っていなくても端末の記録は消さない。**
  Future<RemoveAdsResult> restore() async {
    if (state.busy) return RemoveAdsResult.canceled;
    _listen();
    state = state.copyWith(busy: true);
    final ownership = await _gateway.queryOwnership();
    if (!ref.mounted) return RemoveAdsResult.failed;
    state = state.copyWith(busy: false);
    switch (ownership) {
      case Ownership.owned:
        _grant();
        return RemoveAdsResult.restored;
      case Ownership.pending:
        state = state.copyWith(pending: true);
        return RemoveAdsResult.pending;
      case Ownership.notOwned:
        return RemoveAdsResult.notFound;
      case Ownership.unknown:
        return RemoveAdsResult.unavailable;
    }
  }

  void _onUpdate(PurchaseUpdate update) {
    if (!ref.mounted) return;
    switch (update) {
      case PurchaseUpdate.purchased:
      case PurchaseUpdate.restored:
        _grant();
        _finishBuying(RemoveAdsResult.purchased);
      case PurchaseUpdate.pending:
        state = state.copyWith(pending: true);
        _finishBuying(RemoveAdsResult.pending);
      case PurchaseUpdate.canceled:
        _finishBuying(RemoveAdsResult.canceled);
      case PurchaseUpdate.failed:
        _finishBuying(RemoveAdsResult.failed);
    }
  }

  void _finishBuying(RemoveAdsResult result) {
    final buying = _buying;
    if (buying == null) return;
    _buying = null;
    state = state.copyWith(busy: false);
    if (!buying.isCompleted) buying.complete(result);
  }

  /// **先に端末に残してから状態を変える**（`InAppPurchaseGateway` はこの後で
  /// ストアに完了を知らせる）。
  void _grant() {
    unawaited(ref.read(sharedPreferencesProvider).setBool(prefsKey, true));
    state = state.copyWith(purchased: true, pending: false);
  }

  void _revoke() {
    unawaited(ref.read(sharedPreferencesProvider).remove(prefsKey));
    state = state.copyWith(purchased: false);
  }
}

final removeAdsProvider = NotifierProvider<RemoveAdsController, RemoveAdsState>(
  RemoveAdsController.new,
);

/// 買ってあるか。**広告の設定（`adConfigProvider`）とマップの開放はこれを見る**
/// （価格や途中の状態が変わるたびに広告の設定を組み直さない）。
final adsRemovedProvider = Provider<bool>(
  (ref) => ref.watch(removeAdsProvider.select((s) => s.purchased)),
);
