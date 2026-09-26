import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tonsoku/core/ads/ads_controller.dart';
import 'package:tonsoku/core/config/ad_config.dart';
import 'package:tonsoku/core/i18n/app_locale.dart';
import 'package:tonsoku/core/storage/preferences_provider.dart';
import 'package:tonsoku/core/theme/app_theme.dart';
import 'package:tonsoku/features/map/data/bundled_tile_provider.dart';
import 'package:tonsoku/features/map/data/location_repository.dart';
import 'package:tonsoku/features/map/data/map_repository.dart';
import 'package:tonsoku/features/map/data/stations.dart';
import 'package:tonsoku/features/map/domain/map_link_filter.dart';
import 'package:tonsoku/features/map/presentation/map_page.dart';
import 'package:tonsoku/features/map/presentation/widgets/map_search.dart';

/// 位置情報を使わない（テストに OS の許可の口は無い）。
class _NoLocation implements LocationRepository {
  @override
  Future<Position?> current() async => null;
}

/// マップの画面。**背景地図は描かない**（読み込みを待たせたまま）で、店の印と
/// 絞り込みの組み合わせだけを見る。
/// 検索バーの右端の、地図に出している店の数（品のチップの店の数と区別する）。
Finder shownCount(String text) => find.byWidgetPredicate(
  (w) => w is Text && w.key == MapSearch.countKey && w.data == text,
);

void main() {
  final shops = MapRepository.decodeShops(
    File('test/fixtures/app_shop_production.json').readAsStringSync(),
  );
  final menus = MapRepository.decodeLimited(
    File('test/fixtures/app_limited_production.json').readAsStringSync(),
  );

  /// マップを組む（店舗限定の表示は開放扱い）。[child] を渡すとその中に置く
  /// （go_router で組む時）。
  Future<void> pumpMap(
    WidgetTester tester, {
    MapLinkFilter? link,
    GoRouter? router,
  }) async {
    SharedPreferences.setMockInitialValues({'app_locale': 'ja'});
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
          adConfigProvider.overrideWithValue(const AdConfig(units: {})),
        ],
        child: router != null
            ? MaterialApp.router(
                theme: AppTheme.light(AppLocale.ja),
                routerConfig: router,
              )
            : MaterialApp(
                theme: AppTheme.light(AppLocale.ja),
                home: MapPage(onOpenArticle: (_) {}, link: link),
              ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  /// **リンクで渡された絞り込みを最初から入れる**（Issue #30）。
  group('リンクの絞り込み', () {
    testWidgets('品で絞り、知らない品は捨てる', (tester) async {
      await pumpMap(
        tester,
        link: MapLinkFilter.fromFragment('menu=177979,999999'),
      );
      expect(shownCount('15店舗'), findsOneWidget);
      expect(find.text('売り切れ・終売の店も含める'), findsOneWidget);
      // 併設で絞っていないので、併設の段は畳んだまま
      expect(find.text('松のや専門店'), findsNothing);
    });

    testWidgets('併設で絞る時は併設の段を開いて見せる', (tester) async {
      await pumpMap(
        tester,
        link: MapLinkFilter.fromFragment('brand=standalone'),
      );
      expect(shownCount('122店舗'), findsOneWidget);
      expect(find.text('松のや専門店'), findsOneWidget);
    });

    /// **マップが既に開いていても入れ直し、今の絞り込みを丸ごと置き換える**
    /// （go_router で組む。入れ終えたら URL からクエリを消すので、同じリンクを
    /// もう一度踏んでも効く）
    testWidgets('開いたまま踏んでも置き換え、同じリンクも効く', (tester) async {
      final router = GoRouter(
        initialLocation: '/map',
        routes: [
          GoRoute(
            path: '/map',
            builder: (context, state) => MapPage(
              onOpenArticle: (_) {},
              link: MapLinkFilter.fromQuery(state.uri),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      // 地図のタイマーが回り続けるので pumpAndSettle は使わない。移動の 1 フレーム
      // ＋ URL を消す post-frame ＋ その後の組み直し
      Future<void> settle() async {
        for (var i = 0; i < 4; i++) {
          await tester.pump();
        }
      }

      await pumpMap(tester, router: router);
      expect(shownCount('681店舗'), findsOneWidget);

      final standalone = MapLinkFilter.fromFragment('brand=standalone')!;
      router.go(standalone.location);
      await settle();
      expect(shownCount('122店舗'), findsOneWidget);
      // 入れ終えたらクエリを消す
      expect(router.state.uri.toString(), '/map');

      // 利用者が絞り込みを変えた後に、別のリンク → 置き換わる（足し合わせない）
      await tester.tap(find.text('松屋併設'));
      await tester.pump();
      router.go(MapLinkFilter.fromFragment('menu=177979')!.location);
      await settle();
      expect(shownCount('15店舗'), findsOneWidget);

      // 同じリンクをもう一度
      router.go(standalone.location);
      await settle();
      expect(shownCount('122店舗'), findsOneWidget);
      await tester.tap(find.text('松のや専門店'));
      await tester.pump();
      expect(shownCount('681店舗'), findsOneWidget);
      router.go(standalone.location);
      await settle();
      expect(shownCount('122店舗'), findsOneWidget);

      // 素の /map（下タブの再タップと同じ）では絞り込みに触らない
      router.go('/map');
      await settle();
      expect(shownCount('122店舗'), findsOneWidget);
    });
  });

  testWidgets('全店を出し、併設と品で絞れる', (tester) async {
    SharedPreferences.setMockInitialValues({'app_locale': 'ja'});
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
          // **広告を出さない構成で見る**（本番の ID が空の時と同じ ＝ 店舗限定の
          // 表示は開放扱い）。動画で開放する流れは map_unlock_test.dart
          adConfigProvider.overrideWithValue(const AdConfig(units: {})),
        ],
        child: MaterialApp(
          theme: AppTheme.light(AppLocale.ja),
          home: MapPage(onOpenArticle: (_) {}),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(shownCount('681店舗'), findsOneWidget);
    // 帰属表記は右下に常に出す（contributors は付けない。ユーザーの判断）
    expect(find.text('© OpenStreetMap'), findsOneWidget);
    // 品を選ぶまでは「含める」を出さない
    expect(find.text('売り切れ・終売の店も含める'), findsNothing);

    // 松のや専門店・併設は畳んである。検索バーの右のフィルタのボタンで開く
    expect(find.text('松のや専門店'), findsNothing);
    await tester.tap(find.byTooltip('絞り込み'));
    await tester.pump();
    await tester.tap(find.text('松のや専門店'));
    await tester.pump();
    expect(shownCount('122店舗'), findsOneWidget);
    await tester.tap(find.text('松のや専門店'));
    await tester.pump();

    await tester.tap(find.text('松屋併設'));
    await tester.pump();
    expect(shownCount('483店舗'), findsOneWidget);

    // 併設を外して、販売中の品を選ぶ（15 店。売り切れの店は無い）
    await tester.tap(find.text('松屋併設'));
    await tester.pump();
    await tester.tap(find.text('たっぷりねぎと味噌ダレの超厚切りリブロースかつ定食'));
    await tester.pump();
    expect(shownCount('15店舗'), findsOneWidget);
    expect(find.text('売り切れ・終売の店も含める'), findsOneWidget);

    // 全店で終売した品はチップごと出さない（行き先が無い）
    expect(find.text('“極厚”肩ロース定食'), findsNothing);
  });
}
