import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tonsoku/features/map/data/map_repository.dart';

/// `app/shop.json` / `app/limited.json` の実物（cdn.ton-soku.com、2026-09-25）を
/// そのまま読めること。**スキーマは `additionalProperties: false`** なので、
/// 配信の鍵とモデルの鍵が 1 対 1 に揃っていることも見る（片方にしか無い鍵は、
/// 読み落としか、配信の形が変わった印）。
void main() {
  final shopBody = File(
    'test/fixtures/app_shop_production.json',
  ).readAsStringSync();
  final limitedBody = File(
    'test/fixtures/app_limited_production.json',
  ).readAsStringSync();

  test('店は 681 軒とも読める', () {
    final shops = MapRepository.decodeShops(shopBody);
    expect(shops, hasLength(681));

    final first = shops.first;
    expect(first.code, '0000001202');
    expect(first.name, '松のや 西新宿店');
    expect(first.lat, closeTo(35.694, 0.001));
    expect(first.address, startsWith('東京都新宿区'));
    expect(first.businessHours, contains('5時から翌2時'));
    expect(first.phone, '080-5928-1178');
    expect(first.tempClosed, isNull);

    // 一時閉店を持つ店（再開日つき）
    final itabashi = shops.firstWhere((s) => s.name == '松のや 板橋区役所前店');
    expect(itabashi.tempClosed?.startDate, '2026-09-06');
    expect(itabashi.tempClosed?.endDate, '2026-09-28');

    // 併設
    expect(shops.where((s) => s.brands.contains('matsuya')), hasLength(483));
    expect(shops.where((s) => s.brands.contains('mycurry')), hasLength(86));
  });

  test('店の鍵は配信と 1 対 1', () {
    final raw = jsonDecode(shopBody) as List<dynamic>;
    final shops = MapRepository.decodeShops(shopBody);
    for (final (i, e) in raw.indexed) {
      final json = e as Map<String, dynamic>;
      expect(shops[i].toJson().keys.toSet(), json.keys.toSet());
      if (json['temp_closed'] case final Map<String, dynamic> temp) {
        expect(shops[i].tempClosed!.toJson().keys.toSet(), temp.keys.toSet());
      }
    }
  });

  test('店舗限定の品を読める（全店で終売した品も）', () {
    final menus = MapRepository.decodeLimitedAll(limitedBody);
    expect(menus, hasLength(3));

    final selling = menus.first;
    expect(selling.campaignId, '177979');
    expect(selling.shops, hasLength(15));
    expect(selling.soldOutShops, isEmpty);
    expect(selling.endedAt, isNull);
    expect(selling.articleSlug, 'lsmujz');
    expect(selling.imageUrl, startsWith('https://cdn.ton-soku.com/menu/'));

    final ended = menus[1];
    expect(ended.shops, isEmpty);
    expect(ended.endedAt, '2026-09-23 15:16');
    expect(ended.endedShops, hasLength(15));
    expect(ended.endedShops.first.code, '0000001214');
    expect(ended.endedShops.first.endedAt, '2026-09-19 08:01');
  });

  test('品の鍵は配信と 1 対 1', () {
    final raw = jsonDecode(limitedBody) as List<dynamic>;
    final menus = MapRepository.decodeLimitedAll(limitedBody);
    for (final (i, e) in raw.indexed) {
      final json = e as Map<String, dynamic>;
      expect(menus[i].toJson().keys.toSet(), json.keys.toSet());
      for (final (j, ended) in (json['ended_shops'] as List<dynamic>).indexed) {
        expect(
          menus[i].endedShops[j].toJson().keys.toSet(),
          (ended as Map<String, dynamic>).keys.toSet(),
        );
      }
    }
  });

  test('品が 0 件の週は空で読める（失敗にしない）', () {
    expect(MapRepository.decodeLimited('[]'), isEmpty);
  });

  test('全店で終売した品と「単品◯◯」は地図に出さない', () {
    final raw = jsonDecode(limitedBody) as List<dynamic>;
    final selling = Map<String, dynamic>.from(raw[0] as Map);
    final side = {
      ...selling,
      'campaign_id': '1',
      'name': '単品${selling['name']}',
    };
    final partlyEnded = {
      ...selling,
      'campaign_id': '2',
      'name': '一部の店で終売',
      'ended_shops': [
        {'code': '0000001214', 'ended_at': '2026-09-19 08:01'},
      ],
    };
    final names = MapRepository.decodeLimited(
      jsonEncode([...raw, side, partlyEnded]),
    ).map((m) => m.name);
    expect(names, [selling['name'], '一部の店で終売']);
  });

  test('1 軒の形が崩れても残りは出す', () {
    final raw = jsonDecode(shopBody) as List<dynamic>;
    final broken = [
      {'code': 'x'},
      ...raw.take(2),
    ];
    expect(MapRepository.decodeShops(jsonEncode(broken)), hasLength(2));
  });
}
