import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tonsoku/core/ads/ad_gateway.dart';
import 'package:tonsoku/core/ads/ads_controller.dart';
import 'package:tonsoku/core/config/ad_config.dart';
import 'package:tonsoku/core/lifecycle/app_resume.dart';
import 'package:tonsoku/core/purchase/remove_ads_controller.dart';
import 'package:tonsoku/core/storage/preferences_provider.dart';

/// マップの店舗限定の表示の開放（リワード動画。ユーザーの決定）。
///
/// **動画を最後まで見たら 6 時間、店舗限定の表示を開放する。** 開放していない間は
/// 店舗限定に関わる表示を全部出さない（店舗限定の印・品のチップと「含める」・
/// 画面外の吹き出し・店の詳細の「店舗限定」の欄。`MapPage`）。普通の店の点・
/// 検索・併設の絞り込み・現在地・コンパスはそのまま使える。
@immutable
class MapUnlockState {
  const MapUnlockState({
    this.until,
    this.unlocked = false,
    this.busy = false,
    this.declined = false,
  });

  /// 開放の期限。**過ぎたら null**。
  final DateTime? until;

  /// いま開放しているか（[until] を最後に確かめた時点の値）。
  final bool unlocked;

  /// 動画を読み込んでいる・出している。
  final bool busy;

  /// **この起動の間に、動画を途中で閉じた。** マップを開いた時に自動で動画を
  /// 出すのをやめる（`MapPage`）。案内を押せばいつでも見直せる。
  final bool declined;
}

class MapUnlockController extends Notifier<MapUnlockState> {
  /// 開放する長さ（ユーザーの決定）。
  static const duration = Duration(hours: 6);

  /// 期限（エポックミリ秒）を残す鍵。**アプリを終えても期限までは開放のまま。**
  static const prefsKey = 'map_limited_unlocked_until';

  Timer? _expiry;

  @override
  MapUnlockState build() {
    // **期限はタイマーと復帰の両方で確かめる。** 裏にいる間はタイマーが止まる
    // （iOS）ので、期限を過ぎて戻ってきた時はタイマーより先に復帰で気づく
    ref.listen(appResumeSignalProvider, (_, _) => _refresh());
    ref.onDispose(() => _expiry?.cancel());
    final ms = ref.read(sharedPreferencesProvider).getInt(prefsKey);
    return _evaluate(
      ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms),
      busy: false,
      declined: false,
    );
  }

  MapUnlockState _evaluate(
    DateTime? until, {
    required bool busy,
    required bool declined,
  }) {
    final now = clock.now();
    final unlocked = until != null && now.isBefore(until);
    _expiry?.cancel();
    _expiry = null;
    if (unlocked) {
      // 境目ちょうどに確かめると前の側に落ちうるので、少しだけ後にする
      _expiry = Timer(
        until.difference(now) + const Duration(seconds: 1),
        _refresh,
      );
    }
    return MapUnlockState(
      until: unlocked ? until : null,
      unlocked: unlocked,
      busy: busy,
      declined: declined,
    );
  }

  void _refresh() => state = _evaluate(
    state.until,
    busy: state.busy,
    declined: state.declined,
  );

  /// 動画を出す。**最後まで見たら開放**、途中で閉じたら閉じたままにする。
  /// 既に読み込み中なら何もしない（null）。
  Future<RewardOutcome?> watchVideo() async {
    if (state.busy) return null;
    final unitId = ref.read(adUnitProvider(AdSlot.mapRewarded));
    if (unitId == null) return RewardOutcome.failed;
    state = MapUnlockState(
      until: state.until,
      unlocked: state.unlocked,
      busy: true,
      declined: state.declined,
    );
    RewardOutcome outcome;
    try {
      final ad = await ref.read(adGatewayProvider).loadRewarded(unitId);
      outcome = ad == null ? RewardOutcome.failed : await ad.show();
      ad?.dispose();
    } on Object {
      outcome = RewardOutcome.failed;
    }
    if (!ref.mounted) return outcome;
    switch (outcome) {
      case RewardOutcome.earned:
        final until = clock.now().add(duration);
        unawaited(
          ref
              .read(sharedPreferencesProvider)
              .setInt(prefsKey, until.millisecondsSinceEpoch),
        );
        state = _evaluate(until, busy: false, declined: false);
      case RewardOutcome.dismissed:
        state = _evaluate(state.until, busy: false, declined: true);
      case RewardOutcome.failed:
        state = _evaluate(state.until, busy: false, declined: state.declined);
    }
    return outcome;
  }
}

final mapUnlockProvider = NotifierProvider<MapUnlockController, MapUnlockState>(
  MapUnlockController.new,
);

/// マップの店舗限定の表示の状態。
enum MapLimitedGate {
  /// 出す（開放中・広告を外す課金を買ってある・動画を出せない）。
  open,

  /// 出さない。動画を見れば開放できる。
  locked,

  /// 出さない。広告の準備（同意・初期化）を待っている。
  waiting,
}

/// **広告を外す課金を買った人は常に開放**（ユーザーの決定。動画は広告の対価
/// なので、広告を外した人には求めない。Issue #42）。
///
/// **動画を出せない時も開放扱い**（ユーザーの指定）:
///
/// - **本番の ID が空** … 開放。見せる動画が無いのに閉じたままだと、
///   店舗限定の機能が誰にも使えなくなる
/// - **同意が得られない・SDK が始められない**（[AdsStatus.unavailable]）… 開放。
///   同じく、見る手段が無い
/// - **テスト用の ID**（debug / profile）… 動画を出す（テスト用の動画が出る）
///
/// **読み込めなかった時（在庫切れ・通信不可）は開放しない。** 案内を押した時に
/// 「動画を読み込めませんでした」と出す（ユーザーの指定。押しても何も起きない
/// 形にしない）。
final mapLimitedGateProvider = Provider<MapLimitedGate>((ref) {
  // **課金を先に見る。** 広告の設定（`adConfigProvider`）も買った人には枠を
  // 出さないので下の判定でも開くが、それは「動画を出せない」の扱いに乗っている
  // だけ。買った人を開く理由は別なので、別に書く
  if (ref.watch(adsRemovedProvider)) return MapLimitedGate.open;
  if (ref.watch(adConfigProvider).unitId(AdSlot.mapRewarded) == null) {
    return MapLimitedGate.open;
  }
  switch (ref.watch(adsControllerProvider)) {
    case AdsStatus.off:
    case AdsStatus.unavailable:
      return MapLimitedGate.open;
    case AdsStatus.idle:
    case AdsStatus.starting:
      return ref.watch(mapUnlockProvider).unlocked
          ? MapLimitedGate.open
          : MapLimitedGate.waiting;
    case AdsStatus.ready:
      return ref.watch(mapUnlockProvider).unlocked
          ? MapLimitedGate.open
          : MapLimitedGate.locked;
  }
});
