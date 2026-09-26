import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:tonsoku/core/ads/ad_gateway.dart';

/// テスト用の広告。**本物の SDK に触れない**（読み込みも表示もしない）。
class FakeAdGateway implements AdGateway {
  FakeAdGateway({
    this.canRequest = true,
    this.bannerSize = const Size(390, 62),
    this.rewardOutcome = RewardOutcome.earned,
  });

  bool canRequest;

  /// 読み込めたことにするバナーの大きさ。null なら読み込めない。
  Size? bannerSize;

  /// リワード動画の結果。[RewardOutcome.failed] なら読み込めない。
  RewardOutcome rewardOutcome;

  /// 設定すると、リワード動画の読み込みがこれを待つ（読み込み中を見るため）。
  Completer<void>? rewardGate;

  final calls = <String>[];

  @override
  Future<void> gatherConsent() async => calls.add('consent');

  @override
  Future<void> requestTracking() async => calls.add('tracking');

  @override
  Future<bool> canRequestAds() async {
    calls.add('canRequestAds');
    return canRequest;
  }

  @override
  Future<void> initialize() async => calls.add('initialize');

  @override
  Future<BannerHandle?> loadAnchoredBanner(String unitId, int width) async {
    calls.add('anchored:$unitId');
    final size = bannerSize;
    return size == null ? null : FakeBanner(size);
  }

  @override
  Future<BannerHandle?> loadInlineBanner(
    String unitId,
    int width,
    int maxHeight,
  ) async {
    calls.add('inline:$unitId');
    final size = bannerSize;
    return size == null ? null : FakeBanner(size);
  }

  @override
  Future<RewardedHandle?> loadRewarded(String unitId) async {
    calls.add('rewarded:$unitId');
    await rewardGate?.future;
    return rewardOutcome == RewardOutcome.failed
        ? null
        : _FakeRewarded(rewardOutcome, () => calls.add('showRewarded'));
  }
}

class FakeBanner implements BannerHandle {
  FakeBanner(this.size);

  static const viewKey = Key('fake-banner');

  @override
  final Size size;

  bool disposed = false;

  @override
  Widget get view => const SizedBox.expand(key: viewKey);

  @override
  void dispose() => disposed = true;
}

class _FakeRewarded implements RewardedHandle {
  _FakeRewarded(this.outcome, this.onShow);

  final RewardOutcome outcome;
  final void Function() onShow;

  @override
  Future<RewardOutcome> show() async {
    onShow();
    return outcome;
  }

  @override
  void dispose() {}
}
