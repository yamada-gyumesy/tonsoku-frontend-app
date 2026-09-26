import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tonsoku/core/ads/ad_banner.dart';
import 'package:tonsoku/core/ads/ad_gateway.dart';
import 'package:tonsoku/core/ads/ads_controller.dart';
import 'package:tonsoku/core/config/ad_config.dart';
import 'package:tonsoku/core/i18n/app_locale.dart';
import 'package:tonsoku/core/theme/app_theme.dart';

import 'fake_ad_gateway.dart';

const _navKey = Key('nav');
const _bodyKey = Key('body');

void main() {
  Future<ProviderContainer> pump(
    WidgetTester tester, {
    required AdConfig config,
    required FakeAdGateway gateway,
    bool start = true,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adConfigProvider.overrideWithValue(config),
          adGatewayProvider.overrideWithValue(gateway),
        ],
        child: MaterialApp(
          theme: AppTheme.light(AppLocale.ja),
          home: Scaffold(
            body: const SizedBox.expand(key: _bodyKey),
            bottomNavigationBar: const WithAnchoredAd(
              nav: SizedBox(key: _navKey, height: 56),
            ),
          ),
        ),
      ),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byKey(_navKey)),
    );
    if (start) {
      await container.read(adsControllerProvider.notifier).start();
    }
    await tester.pump();
    await tester.pump();
    return container;
  }

  group('下タブの上のアンカー', () {
    testWidgets('本番の ID が空なら何も出さず、SDK に触れない', (tester) async {
      final gateway = FakeAdGateway();
      await pump(
        tester,
        config: const AdConfig(units: {}),
        gateway: gateway,
      );
      expect(find.byKey(FakeBanner.viewKey), findsNothing);
      expect(find.byKey(_navKey), findsOneWidget);
      expect(gateway.calls, isEmpty);
    });

    testWidgets('始まる前は読み込まない（高さも取らない）', (tester) async {
      final gateway = FakeAdGateway();
      await pump(
        tester,
        config: const AdConfig(units: AdConfig.testAndroid),
        gateway: gateway,
        start: false,
      );
      expect(find.byKey(FakeBanner.viewKey), findsNothing);
      expect(gateway.calls, isEmpty);
    });

    testWidgets('入ったら広告の高さだけ取り、本文はその上で終わる', (tester) async {
      final gateway = FakeAdGateway(bannerSize: const Size(320, 62));
      await pump(
        tester,
        config: const AdConfig(units: AdConfig.testAndroid),
        gateway: gateway,
      );
      expect(
        gateway.calls,
        contains('anchored:${AdConfig.testAndroid[AdSlot.anchorBanner]}'),
      );
      final ad = tester.getRect(find.byKey(FakeBanner.viewKey));
      expect(ad.height, 62);
      expect(ad.width, 320);
      // 下タブの真上に積み、本文と重ならない
      final nav = tester.getRect(find.byKey(_navKey));
      final body = tester.getRect(find.byKey(_bodyKey));
      expect(ad.bottom, lessThanOrEqualTo(nav.top));
      expect(body.bottom, lessThanOrEqualTo(ad.top));
    });

    testWidgets('入らなければ高さを取らない', (tester) async {
      final gateway = FakeAdGateway()..bannerSize = null;
      await pump(
        tester,
        config: const AdConfig(units: AdConfig.testAndroid),
        gateway: gateway,
      );
      expect(find.byKey(FakeBanner.viewKey), findsNothing);
      final nav = tester.getRect(find.byKey(_navKey));
      final body = tester.getRect(find.byKey(_bodyKey));
      expect(body.bottom, nav.top);
    });
  });

  group('記事の枠', () {
    Future<void> pumpInline(
      WidgetTester tester,
      FakeAdGateway gateway, {
      AdConfig config = const AdConfig(units: AdConfig.testIos),
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adConfigProvider.overrideWithValue(config),
            adGatewayProvider.overrideWithValue(gateway),
          ],
          child: MaterialApp(
            theme: AppTheme.light(AppLocale.ja),
            home: const Scaffold(
              body: Column(
                children: [
                  InlineAdSlot(slot: AdSlot.articleInline),
                  SizedBox(key: _navKey, height: 10),
                ],
              ),
            ),
          ),
        ),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byKey(_navKey)),
      );
      await container.read(adsControllerProvider.notifier).start();
      await tester.pump();
      await tester.pump();
    }

    testWidgets('入った広告の高さで出す', (tester) async {
      final gateway = FakeAdGateway(bannerSize: const Size(358, 280));
      await pumpInline(tester, gateway);
      expect(tester.getSize(find.byKey(FakeBanner.viewKey)).height, 280);
      expect(tester.getTopLeft(find.byKey(_navKey)).dy, 280);
    });

    testWidgets('入らなければ畳む', (tester) async {
      final gateway = FakeAdGateway()..bannerSize = null;
      await pumpInline(tester, gateway);
      expect(find.byKey(FakeBanner.viewKey), findsNothing);
      expect(tester.getTopLeft(find.byKey(_navKey)).dy, 0);
    });

    testWidgets('一覧の先読みの外へ出て戻っても読み込み直さない', (tester) async {
      final gateway = FakeAdGateway(bannerSize: const Size(358, 280));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adConfigProvider.overrideWithValue(
              const AdConfig(units: AdConfig.testIos),
            ),
            adGatewayProvider.overrideWithValue(gateway),
          ],
          child: MaterialApp(
            theme: AppTheme.light(AppLocale.ja),
            // 記事と同じく ListView(children:)。先読みを 0 にして外へ出す
            home: Scaffold(
              body: ListView(
                scrollCacheExtent: const ScrollCacheExtent.pixels(0),
                children: [
                  const InlineAdSlot(slot: AdSlot.articleInline),
                  const SizedBox(key: _navKey, height: 3000),
                ],
              ),
            ),
          ),
        ),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byKey(_navKey)),
      );
      await container.read(adsControllerProvider.notifier).start();
      await tester.pump();
      await tester.pump();
      final loads = gateway.calls.length;
      expect(find.byKey(FakeBanner.viewKey), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -2500));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, 2500));
      await tester.pumpAndSettle();

      expect(gateway.calls.length, loads);
      expect(tester.getSize(find.byKey(FakeBanner.viewKey)).height, 280);
    });

    testWidgets('本番の ID が空なら枠も取らない', (tester) async {
      final gateway = FakeAdGateway();
      await pumpInline(tester, gateway, config: const AdConfig(units: {}));
      expect(find.byKey(FakeBanner.viewKey), findsNothing);
      expect(tester.getTopLeft(find.byKey(_navKey)).dy, 0);
      expect(gateway.calls, isEmpty);
    });
  });
}
