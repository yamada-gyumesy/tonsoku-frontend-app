import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tonsoku/features/map/data/map_repository.dart';
import 'package:tonsoku/features/map/domain/google_maps.dart';
import 'package:tonsoku/shared/models/shop.dart';

void main() {
  test('店名で検索する URL（Google の公開の形）', () {
    const shop = Shop(
      code: '1',
      name: '松のや 西新宿店',
      lat: 35.6942853,
      lon: 139.6990776,
    );
    final uri = googleMapsUri(shop);
    expect(uri.scheme, 'https');
    expect(uri.host, 'www.google.com');
    expect(uri.path, '/maps/search/');
    expect(uri.queryParameters, {'api': '1', 'query': '松のや 西新宿店'});
    // 日本語と空白は符号化される
    expect(uri.toString(), isNot(contains(' ')));
  });

  test('店名だけで店が 1 つに決まる（本番の 681 軒に重複が無い）', () {
    final shops = MapRepository.decodeShops(
      File('test/fixtures/app_shop_production.json').readAsStringSync(),
    );
    final names = {for (final s in shops) s.name};
    expect(names, hasLength(shops.length));
  });

  group('英語・中国語で店名の訳が無い（null）', () {
    test('屋号とローマ字名で引く', () {
      const shop = Shop(
        code: '1',
        nameRoman: 'NISHISHINJUKU',
        lat: 35.6942853,
        lon: 139.6990776,
      );
      expect(
        googleMapsUri(shop).queryParameters['query'],
        'Matsunoya NISHISHINJUKU',
      );
    });

    test('ローマ字名も無ければ座標', () {
      const shop = Shop(code: '1', lat: 35.69, lon: 139.69);
      expect(googleMapsUri(shop).queryParameters['query'], '35.69,139.69');
    });
  });
}
