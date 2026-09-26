import 'dart:async';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tonsoku/core/ads/ad_gateway.dart';
import 'package:tonsoku/core/ads/ads_controller.dart';
import 'package:tonsoku/core/config/ad_config.dart';
import 'package:tonsoku/core/i18n/app_locale.dart';
import 'package:tonsoku/core/purchase/purchase_gateway.dart';
import 'package:tonsoku/core/purchase/remove_ads_controller.dart';
import 'package:tonsoku/core/storage/preferences_provider.dart';
import 'package:tonsoku/core/theme/app_theme.dart';
import 'package:tonsoku/features/map/data/bundled_tile_provider.dart';
import 'package:tonsoku/features/map/data/location_repository.dart';
import 'package:tonsoku/features/map/data/map_repository.dart';
import 'package:tonsoku/features/map/data/map_unlock.dart';
import 'package:tonsoku/features/map/data/stations.dart';
import 'package:tonsoku/features/map/domain/map_link_filter.dart';
import 'package:tonsoku/features/map/presentation/map_page.dart';
import 'package:tonsoku/features/map/presentation/widgets/map_filter_band.dart';
import 'package:tonsoku/features/map/presentation/widgets/map_search.dart';
import 'package:tonsoku/features/map/presentation/widgets/shop_marker.dart';

import '../../core/ads/fake_ad_gateway.dart';
import '../../core/purchase/fake_purchase_gateway.dart';

class _NoLocation implements LocationRepository {
  @override
  Future<Position?> current() async => null;
}

const _notice = '動画を見て店舗限定を表示';

void main() {
  const testUnits = AdConfig(units: AdConfig.testIos);
  final t0 = DateTime(2026, 9, 26, 12);

  group('開放の期限（MapUnlockController）', () {
    /// **時刻は読む側で `withClock` する**（provider は最初に読んだ時に組まれる）。
    Future<ProviderContainer> containerFor(
      FakeAdGateway gateway, {
      Map<String, Object> prefs = const {},
      AdConfig config = testUnits,
    }) async {
      SharedPreferences.setMockInitialValues(prefs);
      final store = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(store),
          adConfigProvider.overrideWithValue(config),
          adGatewayProvider.overrideWithValue(gateway),
        ],
      );
      addTearDown(container.dispose);
      await container.read(adsControllerProvider.notifier).start();
      return container;
    }

    test('開放前は閉じている', () async {
      final c = await containerFor(FakeAdGateway());
      withClock(Clock.fixed(t0), () {
        expect(c.read(mapUnlockProvider).unlocked, isFalse);
        expect(c.read(mapLimitedGateProvider), MapLimitedGate.locked);
      });
    });

    test('最後まで見たら 6 時間開放し、期限を残す', () async {
      final gateway = FakeAdGateway(rewardOutcome: RewardOutcome.earned);
      final c = await containerFor(gateway);
      await withClock(Clock.fixed(t0), () async {
        final outcome = await c.read(mapUnlockProvider.notifier).watchVideo();
        expect(outcome, RewardOutcome.earned);
        expect(c.read(mapUnlockProvider).unlocked, isTrue);
        expect(c.read(mapLimitedGateProvider), MapLimitedGate.open);
      });
      final store = c.read(sharedPreferencesProvider);
      expect(
        store.getInt(MapUnlockController.prefsKey),
        t0.add(const Duration(hours: 6)).millisecondsSinceEpoch,
      );
      expect(
        gateway.calls,
        contains('rewarded:${AdConfig.testIos[AdSlot.mapRewarded]}'),
      );
    });

    test('途中で閉じたら閉じたまま（自動では出し直さない印を付ける）', () async {
      final gateway = FakeAdGateway(rewardOutcome: RewardOutcome.dismissed);
      final c = await containerFor(gateway);
      await withClock(Clock.fixed(t0), () async {
        await c.read(mapUnlockProvider.notifier).watchVideo();
        final state = c.read(mapUnlockProvider);
        expect(state.unlocked, isFalse);
        expect(state.declined, isTrue);
        expect(c.read(mapLimitedGateProvider), MapLimitedGate.locked);
      });
      expect(
        c.read(sharedPreferencesProvider).getInt(MapUnlockController.prefsKey),
        isNull,
      );
    });

    test('期限の前はアプリを開き直しても開放のまま、過ぎたら閉じる', () async {
      final until = t0.add(const Duration(hours: 6));
      final prefs = {
        MapUnlockController.prefsKey: until.millisecondsSinceEpoch,
      };

      final justBefore = until.subtract(const Duration(minutes: 1));
      final before = await containerFor(FakeAdGateway(), prefs: prefs);
      withClock(Clock.fixed(justBefore), () {
        expect(before.read(mapUnlockProvider).unlocked, isTrue);
      });

      final after = await containerFor(FakeAdGateway(), prefs: prefs);
      withClock(Clock.fixed(until), () {
        expect(after.read(mapUnlockProvider).unlocked, isFalse);
      });
    });

    test('開いている間に期限が来たら閉じる', () {
      fakeAsync((async) {
        SharedPreferences.setMockInitialValues({});
        late ProviderContainer c;
        SharedPreferences.getInstance().then((store) {
          c = ProviderContainer(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(store),
              adConfigProvider.overrideWithValue(testUnits),
              adGatewayProvider.overrideWithValue(FakeAdGateway()),
            ],
          );
        });
        async.flushMicrotasks();
        c.read(adsControllerProvider.notifier).start();
        async.flushMicrotasks();
        c.read(mapUnlockProvider.notifier).watchVideo();
        async.flushMicrotasks();
        expect(c.read(mapUnlockProvider).unlocked, isTrue);
        async.elapse(const Duration(hours: 6) - const Duration(minutes: 1));
        expect(c.read(mapUnlockProvider).unlocked, isTrue);
        async.elapse(const Duration(minutes: 2));
        expect(c.read(mapUnlockProvider).unlocked, isFalse);
        expect(c.read(mapLimitedGateProvider), MapLimitedGate.locked);
        c.dispose();
      });
    });

    test('動画の読み込み中に広告を外す課金を買ったら、動画を出さずに終える', () async {
      // **設定は本物を使う**（購入で枠の ID が空になる流れごと確かめる）
      SharedPreferences.setMockInitialValues({});
      final store = await SharedPreferences.getInstance();
      final gateway = FakeAdGateway()..rewardGate = Completer<void>();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(store),
          adGatewayProvider.overrideWithValue(gateway),
          purchaseGatewayProvider.overrideWithValue(FakePurchaseGateway()),
        ],
      );
      addTearDown(container.dispose);
      await container.read(removeAdsProvider.notifier).start();
      await container.read(adsControllerProvider.notifier).start();

      final watching = container.read(mapUnlockProvider.notifier).watchVideo();
      await container.read(removeAdsProvider.notifier).buy();
      gateway.rewardGate!.complete();

      expect(await watching, isNull);
      expect(gateway.calls, isNot(contains('showRewarded')));
      expect(container.read(mapUnlockProvider).busy, isFalse);
      expect(container.read(mapLimitedGateProvider), MapLimitedGate.open);
    });

    test('本番の ID が空・同意が得られない時は開放扱い', () async {
      final empty = await containerFor(
        FakeAdGateway(),
        config: const AdConfig(units: {}),
      );
      expect(empty.read(mapLimitedGateProvider), MapLimitedGate.open);

      final removed = await containerFor(
        FakeAdGateway(),
        config: const AdConfig(units: AdConfig.testIos, adsRemoved: true),
      );
      expect(removed.read(mapLimitedGateProvider), MapLimitedGate.open);

      final refused = await containerFor(FakeAdGateway(canRequest: false));
      expect(refused.read(mapLimitedGateProvider), MapLimitedGate.open);
    });
  });

  group('マップの画面', () {
    final shops = MapRepository.decodeShops(
      File('test/fixtures/app_shop_production.json').readAsStringSync(),
    );
    final menus = MapRepository.decodeLimited(
      File('test/fixtures/app_limited_production.json').readAsStringSync(),
    );

    Future<ProviderContainer> pumpMap(
      WidgetTester tester,
      FakeAdGateway gateway, {
      Map<String, Object> prefs = const {},
      MapLinkFilter? link,
      FakePurchaseGateway? purchase,
    }) async {
      SharedPreferences.setMockInitialValues({'app_locale': 'ja', ...prefs});
      final store = await SharedPreferences.getInstance();
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(store),
            bundledTilesProvider.overrideWith(
              (ref) => Completer<BundledTileProvider>().future,
            ),
            stationsProvider.overrideWith((ref) async => const []),
            shopsProvider.overrideWith((ref) => Stream.value(shops)),
            limitedMenusProvider.overrideWith((ref) => Stream.value(menus)),
            locationRepositoryProvider.overrideWithValue(_NoLocation()),
            adConfigProvider.overrideWithValue(testUnits),
            adGatewayProvider.overrideWithValue(gateway),
            // **本物のストアに触れない**（動画の案内に添える課金）
            purchaseGatewayProvider.overrideWithValue(
              purchase ?? FakePurchaseGateway(),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(AppLocale.ja),
            home: MapPage(onOpenArticle: (_) {}, link: link),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MapPage)),
      );
      // 課金の突き合わせと広告の SDK を始める（本番は main.dart が最初の
      // フレームの後に呼ぶ）
      await container.read(removeAdsProvider.notifier).start();
      await container.read(adsControllerProvider.notifier).start();
      await tester.pump();
      await tester.pump();
      await tester.pump();
      return container;
    }

    /// 店舗限定に関わる表示（印・品のチップ）が出ているか。
    void expectLimitedShown(bool shown) {
      expect(find.byType(MenuChip), shown ? findsWidgets : findsNothing);
      expect(find.byType(LimitedMark), shown ? findsWidgets : findsNothing);
      // 普通の店の地図としては常に使える
      expect(find.text('681店舗'), findsOneWidget);
      expect(find.text('© OpenStreetMap'), findsOneWidget);
    }

    testWidgets('開放前（動画の読み込み中）は店舗限定の表示を出さない', (tester) async {
      final gateway = FakeAdGateway()..rewardGate = Completer<void>();
      await pumpMap(tester, gateway);
      // 開いたら動画を出しにいく
      expect(
        gateway.calls.where((c) => c.startsWith('rewarded:')),
        hasLength(1),
      );
      expectLimitedShown(false);
      expect(find.text(_notice), findsOneWidget);
      expect(
        tester.widget<MapUnlockNotice>(find.byType(MapUnlockNotice)).busy,
        isTrue,
      );
      gateway.rewardGate!.complete();
      await tester.pump();
    });

    testWidgets('最後まで見たら店舗限定の表示を出し、案内を消す', (tester) async {
      final gateway = FakeAdGateway(rewardOutcome: RewardOutcome.earned);
      await pumpMap(tester, gateway);
      expectLimitedShown(true);
      expect(find.text(_notice), findsNothing);
    });

    testWidgets('途中で閉じたら店舗限定の表示を出さず、案内から見直せる', (tester) async {
      final gateway = FakeAdGateway(rewardOutcome: RewardOutcome.dismissed);
      await pumpMap(tester, gateway);
      expectLimitedShown(false);
      expect(find.text(_notice), findsOneWidget);
      // 店の詳細の「店舗限定」の欄も出さない（閉じている間は品を無いものとして組む）
      expect(find.text('売り切れ・終売の店も含める'), findsNothing);

      // 案内を押して最後まで見れば開放
      gateway.rewardOutcome = RewardOutcome.earned;
      await tester.tap(find.text(_notice));
      await tester.pump();
      await tester.pump();
      expectLimitedShown(true);
      expect(find.text(_notice), findsNothing);
    });

    /// **閉じている間にリンクの品で開いても印は出さない。** いつもの流れで
    /// 開放すれば、リンクの品で絞られた状態になる（Issue #30）
    testWidgets('閉じている時のリンクの品は、開放したら入る', (tester) async {
      final gateway = FakeAdGateway(rewardOutcome: RewardOutcome.dismissed);
      await pumpMap(
        tester,
        gateway,
        link: MapLinkFilter.fromFragment('menu=177979&include=1'),
      );
      expectLimitedShown(false);
      expect(find.text('売り切れ・終売の店も含める'), findsNothing);

      gateway.rewardOutcome = RewardOutcome.earned;
      await tester.tap(find.text(_notice));
      await tester.pump();
      await tester.pump();
      // 検索バーの右端の、地図に出している店の数（品のチップの数とは別）
      expect(tester.widget<Text>(find.byKey(MapSearch.countKey)).data, '15店舗');
      expect(
        tester
            .widget<MenuChip>(
              find.widgetWithText(MenuChip, 'たっぷりねぎと味噌ダレの超厚切りリブロースかつ定食'),
            )
            .selected,
        isTrue,
      );
      expect(find.text('売り切れ・終売の店も含める'), findsOneWidget);
    });

    testWidgets('期限が切れていたら閉じる。読み込めなければ押した時に知らせる', (tester) async {
      final gateway = FakeAdGateway(rewardOutcome: RewardOutcome.failed);
      await pumpMap(
        tester,
        gateway,
        prefs: {
          MapUnlockController.prefsKey: clock
              .now()
              .subtract(const Duration(minutes: 1))
              .millisecondsSinceEpoch,
        },
      );
      expectLimitedShown(false);
      // 開いた時に自動で出しにいった分は、読み込めなくても知らせない
      expect(find.text('動画を読み込めませんでした'), findsNothing);

      await tester.tap(find.text(_notice));
      await tester.pump();
      await tester.pump();
      expect(find.text('動画を読み込めませんでした'), findsOneWidget);
      expectLimitedShown(false);
    });

    testWidgets('期限の内なら開いてすぐ出し、動画は出さない', (tester) async {
      final gateway = FakeAdGateway();
      await pumpMap(
        tester,
        gateway,
        prefs: {
          MapUnlockController.prefsKey: clock
              .now()
              .add(const Duration(hours: 1))
              .millisecondsSinceEpoch,
        },
      );
      expectLimitedShown(true);
      expect(gateway.calls.where((c) => c.startsWith('rewarded:')), isEmpty);
    });

    group('広告を外す課金（Issue #42）', () {
      const removeAds = '広告なしでいつでも表示';

      testWidgets('動画の案内の下に、表示価格つきで添える', (tester) async {
        final gateway = FakeAdGateway(rewardOutcome: RewardOutcome.dismissed);
        await pumpMap(tester, gateway);
        expect(find.text(_notice), findsOneWidget);
        final notice = find.byType(MapUnlockNotice);
        expect(
          find.descendant(of: notice, matching: find.text(removeAds)),
          findsOneWidget,
        );
        expect(
          find.descendant(of: notice, matching: find.text('¥550')),
          findsOneWidget,
        );
      });

      testWidgets('買ったらその場で店舗限定を出し、案内を消す', (tester) async {
        final gateway = FakeAdGateway(rewardOutcome: RewardOutcome.dismissed);
        final purchase = FakePurchaseGateway();
        await pumpMap(tester, gateway, purchase: purchase);
        expectLimitedShown(false);

        await tester.tap(find.text(removeAds));
        await tester.pump();
        await tester.pump();

        expectLimitedShown(true);
        expect(find.text(_notice), findsNothing);
        expect(purchase.calls.where((c) => c == 'buy'), hasLength(1));
        // 動画は開いた時の 1 回だけ（買った後に出し直さない）
        expect(
          gateway.calls.where((c) => c.startsWith('rewarded:')),
          hasLength(1),
        );
      });

      testWidgets('買えなかったら閉じたまま、下に知らせる', (tester) async {
        final gateway = FakeAdGateway(rewardOutcome: RewardOutcome.dismissed);
        await pumpMap(
          tester,
          gateway,
          purchase: FakePurchaseGateway(buyStart: BuyStart.unavailable),
        );
        await tester.tap(find.text(removeAds));
        await tester.pump();
        await tester.pump();
        expectLimitedShown(false);
        expect(find.text('ストアに接続できませんでした'), findsOneWidget);
      });

      testWidgets('買ってある端末は開いてすぐ出し、動画は出さない', (tester) async {
        final gateway = FakeAdGateway();
        await pumpMap(
          tester,
          gateway,
          prefs: {RemoveAdsController.prefsKey: true},
          purchase: FakePurchaseGateway(ownership: Ownership.owned),
        );
        expectLimitedShown(true);
        expect(find.byType(MapUnlockNotice), findsNothing);
        expect(gateway.calls.where((c) => c.startsWith('rewarded:')), isEmpty);
      });
    });
  });
}
