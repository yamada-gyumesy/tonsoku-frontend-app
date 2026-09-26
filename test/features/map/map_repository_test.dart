import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tonsoku/core/cdn/cdn_paths.dart';
import 'package:tonsoku/core/cdn/cdn_repository.dart';
import 'package:tonsoku/core/i18n/app_locale.dart';
import 'package:tonsoku/core/i18n/locale_controller.dart';
import 'package:tonsoku/core/network/cdn_client.dart';
import 'package:tonsoku/core/storage/json_cache.dart';
import 'package:tonsoku/core/storage/preferences_provider.dart';
import 'package:tonsoku/features/map/data/map_repository.dart';

class _MockCdnClient extends Mock implements CdnClient {}

/// マップの配信を**表示言語の面から読む**こと（英語・中国語は `i18n/{locale}/app/…`。
/// tonsoku-backend-batch#286）と、**英語・中国語の面がまだ無い（404）時に
/// 日本語へ落とさない**こと。
void main() {
  late Directory dir;
  late JsonCache cache;
  late _MockCdnClient client;

  String shop(String code, String? name) => jsonEncode([
    {
      'code': code,
      'name': name,
      'name_roman': 'NISHISHINJUKU',
      'lat': 35.69,
      'lon': 139.69,
      'closing_date': null,
      'opening_date': null,
      'brands': <String>[],
      'address': null,
      'business_hours': null,
      'phone': null,
      'temp_closed': null,
    },
  ]);

  Map<String, dynamic> menu(String id, String? name) => {
    'campaign_id': id,
    'name': name,
    'start_date': '2026-09-23 15:00',
    'shops': ['0000001202'],
    'sold_out_shops': <String>[],
    'ended_shops': <Object>[],
    'ended_at': null,
    'article_slug': null,
    'thumbnail_url': null,
    'image_url': null,
  };

  void serves(String path, String body) {
    when(() => client.fetch(path, etag: any(named: 'etag'))).thenAnswer(
      (_) async => CdnPayload(body: body, etag: null, notModified: false),
    );
  }

  void notFound(String path) {
    when(
      () => client.fetch(path, etag: any(named: 'etag')),
    ).thenThrow(CdnNotFoundException(path));
  }

  MapRepository repositoryFor(AppLocale locale) => MapRepository(
    cdn: CdnRepository(client: client, cache: cache),
    locale: locale,
  );

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('map_repository_test');
    cache = JsonCache(dir);
    client = _MockCdnClient();
  });

  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  test('パスは表示言語の名前空間に従う', () {
    expect(const CdnPaths(AppLocale.ja).appShops, 'app/shop.json');
    expect(const CdnPaths(AppLocale.ja).appLimited, 'app/limited.json');
    expect(const CdnPaths(AppLocale.en).appShops, 'i18n/en/app/shop.json');
    expect(const CdnPaths(AppLocale.zh).appLimited, 'i18n/zh/app/limited.json');
  });

  test('英語の画面は英語の面を読み、日本語の面を読まない', () async {
    serves('i18n/en/app/shop.json', shop('1', 'Matsunoya Nishi-Shinjuku'));
    final shops = await repositoryFor(AppLocale.en).watchShops().last;
    expect(shops.single.name, 'Matsunoya Nishi-Shinjuku');
    verifyNever(() => client.fetch('app/shop.json', etag: any(named: 'etag')));
  });

  group('英語・中国語の面がまだ無い（404）', () {
    test('店も品も 0 件で流す（日本語に落とさず、失敗にもしない）', () async {
      notFound('i18n/zh/app/shop.json');
      notFound('i18n/zh/app/limited.json');
      serves('app/shop.json', shop('1', '松のや 西新宿店'));
      // 「単品」を見分けるためだけに読む（品名は画面に出さない）。前に読んだ
      // ものと同じなので「変わっていない」
      serves('app/limited.json', '[]');
      await cache.write('app/limited.json', '[]');

      final repository = repositoryFor(AppLocale.zh);
      expect(await repository.watchShops().toList(), [isEmpty]);
      expect(await repository.watchLimited().toList(), [isEmpty]);
      expect(await repository.refreshIfChanged(), isFalse);
      verifyNever(
        () => client.fetch('app/shop.json', etag: any(named: 'etag')),
      );
    });

    test('日本語の面の 404 は今までどおり失敗', () async {
      notFound('app/shop.json');
      expect(
        repositoryFor(AppLocale.ja).watchShops().toList(),
        throwsA(isA<CdnNotFoundException>()),
      );
    });
  });

  group('品', () {
    test('品名が null の品は出さない', () {
      final menus = MapRepository.decodeLimited(
        jsonEncode([
          menu('1', 'Thick-Cut Pork Loin Set Meal'),
          menu('2', null),
        ]),
      );
      expect(menus.map((m) => m.campaignId), ['1']);
    });

    test('英語・中国語では「単品◯◯」を日本語の面の ID で落とす', () async {
      serves(
        'app/limited.json',
        jsonEncode([menu('1', '“極厚”肩ロース定食'), menu('2', '単品“極厚”肩ロース')]),
      );
      serves(
        'i18n/en/app/limited.json',
        jsonEncode([
          menu('1', 'Extra-Thick Pork Shoulder Set Meal'),
          menu('2', 'Extra-Thick Pork Shoulder only'),
        ]),
      );
      final repository = repositoryFor(AppLocale.en);
      final singles = await repository.watchSingleMenuIds().last;
      expect(singles, {'2'});
      final menus = await repository.watchLimited(singles: singles).last;
      expect(menus.map((m) => m.campaignId), ['1']);
    });

    test('日本語では品名で見分けるので、日本語の面を別に読まない', () async {
      expect(await repositoryFor(AppLocale.ja).watchSingleMenuIds().toList(), [
        isEmpty,
      ]);
      verifyNever(() => client.fetch(any(), etag: any(named: 'etag')));
    });
  });

  test('言語を切り替えると読み直し、キャッシュも言語ごとに分かれる', () async {
    serves('app/shop.json', shop('1', '松のや 西新宿店'));
    serves('i18n/en/app/shop.json', shop('1', 'Matsunoya Nishi-Shinjuku'));
    SharedPreferences.setMockInitialValues({'app_locale': 'ja'});
    final store = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(store),
        cdnClientProvider.overrideWithValue(client),
        jsonCacheProvider.overrideWithValue(cache),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(shopsProvider, (_, _) {});
    addTearDown(sub.close);

    expect(
      (await container.read(shopsProvider.future)).single.name,
      '松のや 西新宿店',
    );

    await container.read(localeControllerProvider.notifier).set(AppLocale.en);
    expect(
      (await container.read(shopsProvider.future)).single.name,
      'Matsunoya Nishi-Shinjuku',
    );

    expect((await cache.read('app/shop.json'))?.body, contains('松のや'));
    expect(
      (await cache.read('i18n/en/app/shop.json'))?.body,
      contains('Matsunoya'),
    );
  });

  test('英語の画面の品は、訳の無い品と「単品◯◯」を落として届く', () async {
    serves(
      'app/limited.json',
      jsonEncode([
        menu('1', '“極厚”肩ロース定食'),
        menu('2', '単品“極厚”肩ロース'),
        menu('3', 'ささみかつ定食'),
      ]),
    );
    serves(
      'i18n/en/app/limited.json',
      jsonEncode([
        menu('1', 'Extra-Thick Pork Shoulder Set Meal'),
        menu('2', 'Extra-Thick Pork Shoulder only'),
        menu('3', null),
      ]),
    );
    SharedPreferences.setMockInitialValues({'app_locale': 'en'});
    final store = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(store),
        cdnClientProvider.overrideWithValue(client),
        jsonCacheProvider.overrideWithValue(cache),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(limitedMenusProvider, (_, _) {});
    addTearDown(sub.close);

    final menus = await container.read(limitedMenusProvider.future);
    expect(menus.map((m) => m.name), ['Extra-Thick Pork Shoulder Set Meal']);
  });
}
