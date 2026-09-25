import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tonsoku/core/ads/ad_gateway.dart';
import 'package:tonsoku/core/ads/ads_controller.dart';
import 'package:tonsoku/core/config/ad_config.dart';
import 'package:tonsoku/core/storage/preferences_provider.dart';
import 'package:tonsoku/features/onboarding/data/ads_after_onboarding.dart';
import 'package:tonsoku/features/onboarding/data/onboarding_store.dart';

import '../../core/ads/fake_ad_gateway.dart';

/// 広告の SDK（同意 → ATT → 初期化）を始める時。
///
/// **初回起動はオンボーディングを閉じるまで始めない。** そのまま始めると
/// オンボーディングの上に同意と ATT のダイアログが被さり、2 枚目の通知の
/// 許可とも重なる。**2 回目以降は待たずに始める。**
void main() {
  Future<(ProviderContainer, FakeAdGateway)> boot({required bool done}) async {
    SharedPreferences.setMockInitialValues({
      if (done) 'flutter.tonsoku-onboarding-done': true,
    });
    final gateway = FakeAdGateway();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
        adConfigProvider.overrideWithValue(
          const AdConfig(units: AdConfig.testIos),
        ),
        adGatewayProvider.overrideWithValue(gateway),
      ],
    );
    addTearDown(container.dispose);
    return (container, gateway);
  }

  test('初回起動: オンボーディングを閉じるまで同意も ATT も出さない', () async {
    final (container, gateway) = await boot(done: false);

    final started = startAdsAfterOnboarding(container);
    // 何周か回しても始まらない
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(gateway.calls, isEmpty, reason: 'オンボーディングの上に ATT が被さる');
    expect(container.read(adsControllerProvider), AdsStatus.idle);

    // オンボーディングを閉じた（`OnboardingOverlay` の onDone）
    container.read(onboardingDoneProvider.notifier).markDone();
    await started;

    expect(gateway.calls, [
      'consent',
      'tracking',
      'canRequestAds',
      'initialize',
    ]);
    expect(container.read(adsControllerProvider), AdsStatus.ready);
  });

  test('2 回目以降: 待たずにすぐ始める', () async {
    final (container, gateway) = await boot(done: true);

    await startAdsAfterOnboarding(container);

    expect(gateway.calls, [
      'consent',
      'tracking',
      'canRequestAds',
      'initialize',
    ]);
  });

  test('見終わったことは保存にも残る（次の起動は待たない）', () async {
    final (container, _) = await boot(done: false);
    container.read(onboardingDoneProvider.notifier).markDone();

    final prefs = await SharedPreferences.getInstance();
    expect(OnboardingStore(prefs).isDone, isTrue);
  });
}
