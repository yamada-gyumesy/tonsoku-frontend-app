import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tonsoku/core/ads/ad_gateway.dart';
import 'package:tonsoku/core/ads/ads_controller.dart';
import 'package:tonsoku/core/config/ad_config.dart';
import 'package:tonsoku/core/purchase/purchase_gateway.dart';
import 'package:tonsoku/core/purchase/remove_ads_controller.dart';
import 'package:tonsoku/core/storage/preferences_provider.dart';
import 'package:tonsoku/features/map/data/map_unlock.dart';
import 'package:tonsoku/features/onboarding/data/ads_after_onboarding.dart';

import '../ads/fake_ad_gateway.dart';
import 'fake_purchase_gateway.dart';

/// 広告を外す課金（買い切り。Issue #42）。**本物のストアにも広告の SDK にも
/// 触れない**（どちらも偽物に差し替える）。
///
/// 広告の設定は**本物の `adConfigProvider`**（課金を見て枠を空にする所）を通す。
/// 枠の ID は release 以外と同じテスト用の ID になる。
void main() {
  Future<(ProviderContainer, FakePurchaseGateway, FakeAdGateway)> boot({
    bool purchased = false,
    FakePurchaseGateway? store,
    FakeAdGateway? ads,
  }) async {
    SharedPreferences.setMockInitialValues({
      // オンボーディングは見終わっている（広告はすぐ始まる）
      'flutter.tonsoku-onboarding-done': true,
      if (purchased) 'flutter.${RemoveAdsController.prefsKey}': true,
    });
    final prefs = await SharedPreferences.getInstance();
    final purchase = store ?? FakePurchaseGateway();
    final adGateway = ads ?? FakeAdGateway();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        purchaseGatewayProvider.overrideWithValue(purchase),
        adGatewayProvider.overrideWithValue(adGateway),
      ],
    );
    addTearDown(container.dispose);
    return (container, purchase, adGateway);
  }

  RemoveAdsController controller(ProviderContainer c) =>
      c.read(removeAdsProvider.notifier);

  bool saved(ProviderContainer c) =>
      c.read(sharedPreferencesProvider).getBool(RemoveAdsController.prefsKey) ??
      false;

  group('買う', () {
    test('買った瞬間に広告の枠が全部消え、端末に残す', () async {
      final (c, store, ads) = await boot();
      await startAdsAfterOnboarding(c);
      expect(c.read(adsControllerProvider), AdsStatus.ready);
      expect(c.read(adUnitProvider(AdSlot.anchorBanner)), isNotNull);

      final result = await controller(c).buy();

      expect(result, RemoveAdsResult.purchased);
      expect(c.read(removeAdsProvider).purchased, isTrue);
      expect(c.read(removeAdsProvider).busy, isFalse);
      expect(saved(c), isTrue);
      expect(c.read(adConfigProvider).adsRemoved, isTrue);
      expect(c.read(adsControllerProvider), AdsStatus.off);
      for (final slot in AdSlot.values) {
        expect(c.read(adUnitProvider(slot)), isNull, reason: '$slot');
      }
      // **始め直さない**（off は idle ではない）
      await pumpEventQueue();
      expect(ads.calls.where((call) => call == 'initialize'), hasLength(1));
      expect(store.calls, ['buy']);
    });

    test('買ったらマップの店舗限定は常に開く', () async {
      final (c, _, _) = await boot();
      await startAdsAfterOnboarding(c);
      expect(c.read(mapLimitedGateProvider), MapLimitedGate.locked);

      await controller(c).buy();

      expect(c.read(mapLimitedGateProvider), MapLimitedGate.open);
    });

    test('シートを閉じた: 何も変わらず、知らせない', () async {
      final (c, _, _) = await boot(
        store: FakePurchaseGateway(buyResult: PurchaseUpdate.canceled),
      );
      expect(await controller(c).buy(), RemoveAdsResult.canceled);
      expect(c.read(removeAdsProvider).purchased, isFalse);
      expect(c.read(removeAdsProvider).busy, isFalse);
      expect(saved(c), isFalse);
    });

    test('買えなかった', () async {
      final (c, _, _) = await boot(
        store: FakePurchaseGateway(buyResult: PurchaseUpdate.failed),
      );
      expect(await controller(c).buy(), RemoveAdsResult.failed);
      expect(c.read(removeAdsProvider).purchased, isFalse);
      expect(c.read(removeAdsProvider).busy, isFalse);
    });

    test('ストアが受け付けなかった（シートが出ない）', () async {
      final (c, _, _) = await boot(
        store: FakePurchaseGateway(buyStart: BuyStart.failed),
      );
      expect(await controller(c).buy(), RemoveAdsResult.failed);
      expect(c.read(removeAdsProvider).busy, isFalse);
    });

    test('ストアに繋がらない', () async {
      final (c, _, _) = await boot(
        store: FakePurchaseGateway(buyStart: BuyStart.unavailable),
      );
      expect(await controller(c).buy(), RemoveAdsResult.unavailable);
      expect(c.read(removeAdsProvider).busy, isFalse);
    });

    test('保留: 広告はまだ外さず、支払いが済んだ知らせで外す', () async {
      final (c, store, _) = await boot(
        store: FakePurchaseGateway(buyResult: PurchaseUpdate.pending),
      );
      await startAdsAfterOnboarding(c);

      expect(await controller(c).buy(), RemoveAdsResult.pending);
      expect(c.read(removeAdsProvider).pending, isTrue);
      expect(c.read(removeAdsProvider).purchased, isFalse);
      expect(c.read(removeAdsProvider).busy, isFalse);
      expect(c.read(adsControllerProvider), AdsStatus.ready);
      expect(saved(c), isFalse);

      // 支払いが済んだ（ストアから知らせが届く）
      store.emit(PurchaseUpdate.purchased);
      await pumpEventQueue();
      expect(c.read(removeAdsProvider).purchased, isTrue);
      expect(c.read(removeAdsProvider).pending, isFalse);
      expect(c.read(adsControllerProvider), AdsStatus.off);
    });

    test('シートを出している間は二重に買わない', () async {
      final store = FakePurchaseGateway(buyResult: null);
      final (c, _, _) = await boot(store: store);

      final first = controller(c).buy();
      await pumpEventQueue();
      expect(c.read(removeAdsProvider).busy, isTrue);
      expect(await controller(c).buy(), RemoveAdsResult.canceled);
      expect(store.calls, ['buy']);

      store.emit(PurchaseUpdate.purchased);
      expect(await first, RemoveAdsResult.purchased);
    });
  });

  group('起動', () {
    test('買ってあれば、最初から SDK・同意・ATT に一切触れない', () async {
      final (c, _, ads) = await boot(purchased: true);

      expect(c.read(adsControllerProvider), AdsStatus.off);
      await startAdsAfterOnboarding(c);

      expect(ads.calls, isEmpty);
      for (final slot in AdSlot.values) {
        expect(c.read(adUnitProvider(slot)), isNull, reason: '$slot');
      }
      expect(c.read(mapLimitedGateProvider), MapLimitedGate.open);
    });

    test('同意の途中で買った: ATT も初期化もしない', () async {
      final consent = Completer<void>();
      final ads = _SlowConsentGateway(consent.future);
      final (c, _, _) = await boot(ads: ads);

      final starting = startAdsAfterOnboarding(c);
      await pumpEventQueue();
      expect(c.read(adsControllerProvider), AdsStatus.starting);

      await controller(c).buy();
      consent.complete();
      await starting;

      expect(ads.calls, ['consent']);
      expect(c.read(adsControllerProvider), AdsStatus.off);
    });

    test('ストアに記録がある: 端末に無くても広告を外す（別の端末で買った・保留が済んだ）', () async {
      final (c, store, _) = await boot(
        store: FakePurchaseGateway(ownership: Ownership.owned),
      );
      await controller(c).start();

      expect(c.read(removeAdsProvider).purchased, isTrue);
      expect(saved(c), isTrue);
      expect(store.calls, ['queryOwnership']);
    });

    test('ストアが「持っていない」と答えた（返金・取り消し）: 広告を戻し、始め直す', () async {
      final (c, _, ads) = await boot(purchased: true);
      await startAdsAfterOnboarding(c);
      expect(ads.calls, isEmpty);

      await controller(c).start();
      await pumpEventQueue();

      expect(c.read(removeAdsProvider).purchased, isFalse);
      expect(saved(c), isFalse);
      // **取り消しに気づいたら、その起動のうちに広告を始め直す**
      expect(c.read(adsControllerProvider), AdsStatus.ready);
      expect(ads.calls, ['consent', 'tracking', 'canRequestAds', 'initialize']);
      expect(c.read(mapLimitedGateProvider), MapLimitedGate.locked);
    });

    test('ストアに聞けない（圏外など）: 端末の記録のまま', () async {
      final (c, _, _) = await boot(
        purchased: true,
        store: FakePurchaseGateway(ownership: Ownership.unknown),
      );
      await controller(c).start();

      expect(c.read(removeAdsProvider).purchased, isTrue);
      expect(saved(c), isTrue);
    });

    test('保留中の購入がある: 広告はまだ外さない', () async {
      final (c, _, _) = await boot(
        store: FakePurchaseGateway(ownership: Ownership.pending),
      );
      await controller(c).start();

      expect(c.read(removeAdsProvider).pending, isTrue);
      expect(c.read(removeAdsProvider).purchased, isFalse);
    });

    test('価格は start の後に取る（start の前はストアに触れない）', () async {
      final (c, store, _) = await boot();
      await controller(c).refreshProduct();
      expect(store.calls, isEmpty);
      expect(c.read(removeAdsProvider).price, isNull);

      await controller(c).start();
      expect(c.read(removeAdsProvider).price, '¥550');
    });

    test('起動時に価格が取れなくても、あとで取り直せる', () async {
      final store = FakePurchaseGateway(price: null);
      final (c, _, _) = await boot(store: store);
      await controller(c).start();
      expect(c.read(removeAdsProvider).price, isNull);

      store.price = '¥550';
      await controller(c).refreshProduct();
      expect(c.read(removeAdsProvider).price, '¥550');
    });
  });

  group('復元', () {
    test('ストアに記録がある: 広告を外す', () async {
      final (c, _, _) = await boot(
        store: FakePurchaseGateway(ownership: Ownership.owned),
      );
      expect(await controller(c).restore(), RemoveAdsResult.restored);
      expect(c.read(removeAdsProvider).purchased, isTrue);
      expect(c.read(removeAdsProvider).busy, isFalse);
      expect(saved(c), isTrue);
    });

    test('記録が無い: 知らせるだけ', () async {
      final (c, _, _) = await boot();
      expect(await controller(c).restore(), RemoveAdsResult.notFound);
      expect(c.read(removeAdsProvider).purchased, isFalse);
    });

    test('記録が無くても、買ってある端末からは取り上げない', () async {
      final (c, _, _) = await boot(purchased: true);
      expect(await controller(c).restore(), RemoveAdsResult.notFound);
      expect(c.read(removeAdsProvider).purchased, isTrue);
      expect(saved(c), isTrue);
    });

    test('ストアに聞けない', () async {
      final (c, _, _) = await boot(
        store: FakePurchaseGateway(ownership: Ownership.unknown),
      );
      expect(await controller(c).restore(), RemoveAdsResult.unavailable);
      expect(c.read(removeAdsProvider).busy, isFalse);
    });

    test('保留中', () async {
      final (c, _, _) = await boot(
        store: FakePurchaseGateway(ownership: Ownership.pending),
      );
      expect(await controller(c).restore(), RemoveAdsResult.pending);
      expect(c.read(removeAdsProvider).pending, isTrue);
      expect(c.read(removeAdsProvider).purchased, isFalse);
    });
  });
}

/// 同意（UMP）のフォームがなかなか閉じない広告。
class _SlowConsentGateway extends FakeAdGateway {
  _SlowConsentGateway(this._consent);

  final Future<void> _consent;

  @override
  Future<void> gatherConsent() async {
    calls.add('consent');
    await _consent;
  }
}
