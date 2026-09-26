import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tonsoku/core/ads/ad_gateway.dart';
import 'package:tonsoku/core/ads/ads_controller.dart';
import 'package:tonsoku/core/config/ad_config.dart';

import 'fake_ad_gateway.dart';

void main() {
  ProviderContainer containerFor(AdConfig config, FakeAdGateway gateway) {
    final container = ProviderContainer(
      overrides: [
        adConfigProvider.overrideWithValue(config),
        adGatewayProvider.overrideWithValue(gateway),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('出す枠が無ければ同意も ATT も初期化もしない', () async {
    final gateway = FakeAdGateway();
    final container = containerFor(const AdConfig(units: {}), gateway);
    expect(container.read(adsControllerProvider), AdsStatus.off);
    await container.read(adsControllerProvider.notifier).start();
    expect(container.read(adsControllerProvider), AdsStatus.off);
    expect(gateway.calls, isEmpty);
    expect(container.read(adUnitProvider(AdSlot.anchorBanner)), isNull);
  });

  test('同意 → ATT → 初期化の順に始め、終わるまで枠の ID を渡さない', () async {
    final gateway = FakeAdGateway();
    final container = containerFor(
      const AdConfig(units: AdConfig.testIos),
      gateway,
    );
    expect(container.read(adsControllerProvider), AdsStatus.idle);
    expect(container.read(adUnitProvider(AdSlot.anchorBanner)), isNull);

    await container.read(adsControllerProvider.notifier).start();
    expect(gateway.calls, [
      'consent',
      'tracking',
      'canRequestAds',
      'initialize',
    ]);
    expect(container.read(adsControllerProvider), AdsStatus.ready);
    expect(
      container.read(adUnitProvider(AdSlot.anchorBanner)),
      AdConfig.testIos[AdSlot.anchorBanner],
    );

    // 2 回目は何もしない（呼び出しは 1 か所だが、念のため）
    await container.read(adsControllerProvider.notifier).start();
    expect(gateway.calls, hasLength(4));
  });

  test('同意が得られなければ初期化せず、広告を出さない', () async {
    final gateway = FakeAdGateway(canRequest: false);
    final container = containerFor(
      const AdConfig(units: AdConfig.testIos),
      gateway,
    );
    await container.read(adsControllerProvider.notifier).start();
    expect(gateway.calls, isNot(contains('initialize')));
    expect(container.read(adsControllerProvider), AdsStatus.unavailable);
    expect(container.read(adUnitProvider(AdSlot.anchorBanner)), isNull);
  });
}
