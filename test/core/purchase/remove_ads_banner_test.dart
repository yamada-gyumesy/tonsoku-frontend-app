import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tonsoku/core/ads/ad_banner.dart';
import 'package:tonsoku/core/ads/ad_gateway.dart';
import 'package:tonsoku/core/ads/ads_controller.dart';
import 'package:tonsoku/core/config/ad_config.dart';
import 'package:tonsoku/core/i18n/app_locale.dart';
import 'package:tonsoku/core/purchase/purchase_gateway.dart';
import 'package:tonsoku/core/purchase/remove_ads_controller.dart';
import 'package:tonsoku/core/storage/preferences_provider.dart';
import 'package:tonsoku/core/theme/app_theme.dart';

import '../ads/fake_ad_gateway.dart';
import 'fake_purchase_gateway.dart';

/// **買った瞬間に、出ていた広告が画面から消える**（Issue #42）。広告の設定は
/// 本物の `adConfigProvider`（課金を見て枠を空にする所）を通す。
void main() {
  testWidgets('買った瞬間にアンカーも記事の枠も消え、持っていた広告を捨てる', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final ads = FakeAdGateway(bannerSize: const Size(320, 62));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          adGatewayProvider.overrideWithValue(ads),
          purchaseGatewayProvider.overrideWithValue(FakePurchaseGateway()),
        ],
        child: MaterialApp(
          theme: AppTheme.light(AppLocale.ja),
          home: const Scaffold(
            body: InlineAdSlot(slot: AdSlot.articleInline),
            bottomNavigationBar: WithAnchoredAd(nav: SizedBox(height: 56)),
          ),
        ),
      ),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(WithAnchoredAd)),
    );
    await container.read(adsControllerProvider.notifier).start();
    for (var i = 0; i < 4; i++) {
      await tester.pump();
    }
    expect(find.byKey(FakeBanner.viewKey), findsNWidgets(2));

    await container.read(removeAdsProvider.notifier).buy();
    await tester.pump();
    await tester.pump();

    expect(find.byKey(FakeBanner.viewKey), findsNothing);
    expect(container.read(adsControllerProvider), AdsStatus.off);
  });
}
