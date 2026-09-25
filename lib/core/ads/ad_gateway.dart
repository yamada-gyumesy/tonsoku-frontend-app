import 'dart:async';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 読み込み済みのバナー 1 枚。**画面から外したら [dispose] する。**
abstract class BannerHandle {
  /// 実際に入った広告の大きさ（論理ピクセル）。枠の高さはこれで取る。
  Size get size;

  /// 画面に置く部品。
  Widget get view;

  void dispose();
}

/// リワード動画を出した結果。
enum RewardOutcome {
  /// 最後まで見た（報酬が出た）。
  earned,

  /// 途中で閉じた（報酬は出ていない）。
  dismissed,

  /// 読み込めない・出せない。
  failed,
}

/// 読み込み済みのリワード動画 1 本。**出せるのは 1 回だけ。**
abstract class RewardedHandle {
  /// 全画面で出し、閉じられるまで待つ。
  Future<RewardOutcome> show();

  void dispose();
}

/// 広告の SDK との境目。**画面と状態はここだけを通して SDK に触る**
/// ―― テストで本物の広告を読み込まないため（テストは偽物に差し替える）。
abstract class AdGateway {
  /// 同意（UMP）を集める。必要な地域・状態ならここで同意のフォームが出る。
  Future<void> gatherConsent();

  /// iOS の App Tracking Transparency の確認を出す（まだ聞いていなければ）。
  Future<void> requestTracking();

  /// 同意の結果、広告を要求してよいか。
  Future<bool> canRequestAds();

  /// SDK を初期化する。
  Future<void> initialize();

  /// 画面幅いっぱいのアンカーのアダプティブバナー。読み込めなければ null。
  Future<BannerHandle?> loadAnchoredBanner(String unitId, int width);

  /// 本文の中に置くインラインのアダプティブバナー（高さは [maxHeight] まで）。
  Future<BannerHandle?> loadInlineBanner(
    String unitId,
    int width,
    int maxHeight,
  );

  /// リワード動画。読み込めなければ null。
  Future<RewardedHandle?> loadRewarded(String unitId);
}

final adGatewayProvider = Provider<AdGateway>((ref) => GoogleAdGateway());

/// Google Mobile Ads SDK（AdMob）での実装。
class GoogleAdGateway implements AdGateway {
  @override
  Future<void> gatherConsent() async {
    // 更新 → 必要ならフォーム、の順（UMP の手順どおり）。**失敗しても先へ進む**
    // ―― 前回までの同意が残っていれば [canRequestAds] が真を返し、残っていなければ
    // 偽を返すので、ここで止める必要は無い
    final updated = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      updated.complete,
      (_) => updated.complete(),
    );
    await updated.future;
    final shown = Completer<void>();
    await ConsentForm.loadAndShowConsentFormIfRequired((_) => shown.complete());
    await shown.future;
  }

  @override
  Future<void> requestTracking() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    // **AdMob の管理画面で UMP の「IDFA の説明」を設定すると、UMP が先に ATT を
    // 出す。** その時はここに来た時点で決まっているので何もしない
    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status == TrackingStatus.notDetermined) {
      await AppTrackingTransparency.requestTrackingAuthorization();
    }
  }

  @override
  Future<bool> canRequestAds() => ConsentInformation.instance.canRequestAds();

  @override
  Future<void> initialize() => MobileAds.instance.initialize();

  @override
  Future<BannerHandle?> loadAnchoredBanner(String unitId, int width) async {
    // `getCurrentOrientationAnchoredAdaptiveBannerAdSize` は 8.0.0 で非推奨になり、
    // 置き換え先がこれ（寸法の選び方は同じく「端末の向きの高さの 15% まで・
    // 50 以上」で、幅と端末が同じなら常に同じ高さ）
    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    if (size == null) return null;
    return _loadBanner(unitId, size);
  }

  @override
  Future<BannerHandle?> loadInlineBanner(
    String unitId,
    int width,
    int maxHeight,
  ) => _loadBanner(
    unitId,
    AdSize.getInlineAdaptiveBannerAdSize(width, maxHeight),
  );

  Future<BannerHandle?> _loadBanner(String unitId, AdSize size) {
    final done = Completer<BannerHandle?>();
    BannerAd(
      adUnitId: unitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) async {
          final banner = ad as BannerAd;
          // インラインは入った広告で高さが決まる（要求した寸法は上限）
          final actual = await banner.getPlatformAdSize() ?? size;
          done.complete(
            _GoogleBanner(
              banner,
              Size(actual.width.toDouble(), actual.height.toDouble()),
            ),
          );
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          done.complete(null);
        },
      ),
    ).load();
    return done.future;
  }

  @override
  Future<RewardedHandle?> loadRewarded(String unitId) {
    final done = Completer<RewardedHandle?>();
    RewardedAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => done.complete(_GoogleRewarded(ad)),
        onAdFailedToLoad: (_) => done.complete(null),
      ),
    );
    return done.future;
  }
}

class _GoogleBanner implements BannerHandle {
  _GoogleBanner(this._ad, this.size);

  final BannerAd _ad;

  @override
  final Size size;

  @override
  late final Widget view = AdWidget(ad: _ad);

  @override
  void dispose() => unawaited(_ad.dispose());
}

class _GoogleRewarded implements RewardedHandle {
  _GoogleRewarded(this._ad);

  final RewardedAd _ad;
  bool _shown = false;

  @override
  Future<RewardOutcome> show() {
    _shown = true;
    final done = Completer<RewardOutcome>();
    var earned = false;
    _ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!done.isCompleted) {
          done.complete(
            earned ? RewardOutcome.earned : RewardOutcome.dismissed,
          );
        }
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        if (!done.isCompleted) done.complete(RewardOutcome.failed);
      },
    );
    // **報酬が出たことは閉じた時にまとめて返す**（報酬の通知は閉じる前に来る。
    // ここで開放すると、動画の裏で地図が組み変わる）
    unawaited(_ad.show(onUserEarnedReward: (_, _) => earned = true));
    return done.future;
  }

  /// 出した後は閉じた時に SDK 側で捨てている（上の callback）ので何もしない。
  @override
  void dispose() {
    if (!_shown) unawaited(_ad.dispose());
  }
}
