import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tonsoku/core/i18n/app_locale.dart';
import 'package:tonsoku/core/storage/preferences_provider.dart';
import 'package:tonsoku/core/theme/app_theme.dart';
import 'package:tonsoku/features/map/data/bundled_tile_provider.dart';
import 'package:tonsoku/features/map/data/location_repository.dart';
import 'package:tonsoku/features/map/data/map_repository.dart';
import 'package:tonsoku/features/map/data/stations.dart';
import 'package:tonsoku/features/map/presentation/map_page.dart';
import 'package:tonsoku/features/map/presentation/widgets/map_legend.dart';

/// 位置情報を使わない（テストに OS の許可の口は無い）。
class _NoLocation implements LocationRepository {
  @override
  Future<Position?> current() async => null;

  @override
  Future<Position?> currentIfPermitted() async => null;
}

/// マップの画面。**背景地図は描かない**（読み込みを待たせたまま）で、店の印と
/// 絞り込みの組み合わせだけを見る。
void main() {
  final shops = MapRepository.decodeShops(
    File('test/fixtures/app_shop_production.json').readAsStringSync(),
  );
  final menus = MapRepository.decodeLimited(
    File('test/fixtures/app_limited_production.json').readAsStringSync(),
  );

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
        ],
        child: MaterialApp(
          theme: AppTheme.light(AppLocale.ja),
          home: MapPage(onOpenArticle: (_) {}),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('681店舗'), findsOneWidget);
    expect(find.byType(MapLegend), findsOneWidget);
    expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
    // 品を選ぶまでは「含める」を出さない
    expect(find.text('売り切れ・終売の店も含める'), findsNothing);

    await tester.tap(find.text('松屋併設'));
    await tester.pump();
    expect(find.text('483店舗'), findsOneWidget);

    // 併設を外して、販売中の品を選ぶ（15 店。売り切れの店は無い）
    await tester.tap(find.text('松屋併設'));
    await tester.pump();
    await tester.tap(find.text('たっぷりねぎと味噌ダレの超厚切りリブロースかつ定食'));
    await tester.pump();
    expect(find.text('15店舗'), findsOneWidget);
    expect(find.text('売り切れ・終売の店も含める'), findsOneWidget);

    // 全店で終売した品: 含めなければ 0 店、含めれば取扱店が戻る
    await tester.tap(find.text('たっぷりねぎと味噌ダレの超厚切りリブロースかつ定食'));
    await tester.pump();
    await tester.tap(find.text('“極厚”肩ロース定食'));
    await tester.pump();
    expect(find.text('0店舗'), findsOneWidget);
    await tester.tap(find.text('売り切れ・終売の店も含める'));
    await tester.pump();
    expect(find.text('15店舗'), findsOneWidget);
  });
}
