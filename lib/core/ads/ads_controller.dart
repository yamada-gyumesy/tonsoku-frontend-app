import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tonsoku/core/ads/ad_gateway.dart';
import 'package:tonsoku/core/config/ad_config.dart';
import 'package:tonsoku/core/purchase/remove_ads_controller.dart';

/// 広告の設定。**広告を外す課金を買ってあれば全部の枠が空になる**（[AdConfig.adsRemoved]）。
///
/// 買った瞬間にここが組み直され、[AdsController] が [AdsStatus.off] に、
/// [adUnitProvider] が null になる ―― 出ていたバナーはその場で消える（枠が
/// ID を失うと持っている広告を捨てる。`ad_banner.dart`）。**SDK は初期化済みの
/// まま残るが、以後は何も要求しない**（初期化を取り消す口は SDK に無い）。
final adConfigProvider = Provider<AdConfig>(
  (ref) => AdConfig.resolve(adsRemoved: ref.watch(adsRemovedProvider)),
);

/// 広告の SDK の状態。
enum AdsStatus {
  /// 出す枠が 1 つも無い（本番の ID が空・広告を外す課金を買ってある）。
  /// **SDK に一切触れない。**
  off,

  /// まだ始めていない（[AdsController.start] 待ち）。
  idle,

  /// 同意・ATT・初期化の途中。
  starting,

  /// 広告を要求してよい。
  ready,

  /// 同意が得られない・初期化に失敗した。**広告は出さない。**
  unavailable,
}

/// 広告の SDK を始める（同意 → ATT → 初期化）。**画面はこの状態が [AdsStatus.ready]
/// になってから広告を読み込む。**
///
/// **始める合図は `main.dart` の 1 か所だけ**（最初のフレームの後。初回起動は
/// オンボーディングを閉じた後 ―― `startAdsAfterOnboarding`。ATT をオンボーディングと
/// 通知の許可に重ねないため）。
/// **ATT は同意（UMP）の後**に聞く（UMP が ATT の説明を出す設定の時に、
/// 二重に聞かないため。`GoogleAdGateway.requestTracking`）。
///
/// **テストでは誰も [start] を呼ばない**ので、既存の画面のテストは SDK に触れない
/// （広告の枠は [AdsStatus.ready] になるまで何も描かない）。
class AdsController extends Notifier<AdsStatus> {
  /// [build] のたびに進める。[start] の途中で組み直されたことを見分ける
  /// （**`ref.mounted` では見分けられない** ―― 組み直しても Notifier は同じものが
  /// 使い回され、`ref.mounted` は真のまま。テストで確かめた）。
  int _generation = 0;

  @override
  AdsStatus build() {
    _generation++;
    return ref.watch(adConfigProvider).enabled ? AdsStatus.idle : AdsStatus.off;
  }

  Future<void> start() async {
    if (state != AdsStatus.idle) return;
    state = AdsStatus.starting;
    final generation = _generation;
    // **設定そのものも読み直す。** 組み直しは次に読まれるまで遅れることがあり
    // （誰も読んでいない間は走らない）、世代だけでは買った直後に気づけない
    bool stale() =>
        !ref.mounted ||
        generation != _generation ||
        !ref.read(adConfigProvider).enabled;
    final gateway = ref.read(adGatewayProvider);
    var ok = false;
    try {
      // **途中で広告を外す課金を買ったら、そこで止める。** 同意のフォームの
      // 後に ATT を重ねない・初期化もしない。**状態も書かない** ―― 書くと
      // 組み直した後の [AdsStatus.off] を上書きして、広告が戻る
      await gateway.gatherConsent();
      if (stale()) return;
      await gateway.requestTracking();
      if (stale()) return;
      ok = await gateway.canRequestAds();
      if (stale()) return;
      if (ok) await gateway.initialize();
    } on Object {
      ok = false;
    }
    if (stale()) return;
    state = ok ? AdsStatus.ready : AdsStatus.unavailable;
  }
}

final adsControllerProvider = NotifierProvider<AdsController, AdsStatus>(
  AdsController.new,
);

/// [slot] の広告ユニット ID。**出せる状態（[AdsStatus.ready]）で、ID がある時だけ。**
final adUnitProvider = Provider.family<String?, AdSlot>((ref, slot) {
  if (ref.watch(adsControllerProvider) != AdsStatus.ready) return null;
  return ref.watch(adConfigProvider).unitId(slot);
});
