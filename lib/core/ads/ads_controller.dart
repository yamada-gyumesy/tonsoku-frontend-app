import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tonsoku/core/ads/ad_gateway.dart';
import 'package:tonsoku/core/config/ad_config.dart';

final adConfigProvider = Provider<AdConfig>((ref) => AdConfig.resolve());

/// 広告の SDK の状態。
enum AdsStatus {
  /// 出す枠が 1 つも無い（本番の ID が空・広告を外す課金）。**SDK に一切触れない。**
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
  @override
  AdsStatus build() =>
      ref.watch(adConfigProvider).enabled ? AdsStatus.idle : AdsStatus.off;

  Future<void> start() async {
    if (state != AdsStatus.idle) return;
    state = AdsStatus.starting;
    final gateway = ref.read(adGatewayProvider);
    var ok = false;
    try {
      await gateway.gatherConsent();
      await gateway.requestTracking();
      ok = await gateway.canRequestAds();
      if (ok) await gateway.initialize();
    } on Object {
      ok = false;
    }
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
