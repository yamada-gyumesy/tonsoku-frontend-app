import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tonsoku/features/map/data/map_repository.dart';
import 'package:tonsoku/shared/models/coupon.dart';
import 'package:tonsoku/shared/models/limited_week.dart';

/// 英語・中国語の面は、**訳が無い値を日本語に落とさず null で出す**
/// （tonsoku-backend-batch#286）。null が来ても解析ごと落ちないこと。
void main() {
  test('週の面: 品名が null でも読める', () {
    final weeks = LimitedWeeks.fromJson({
      'generated_at': '2026-09-26T00:00:00+00:00',
      'weeks': [
        {
          'week_start': '2026-09-23',
          'week_end': '2026-09-29',
          'status': 'items',
          'items': [
            {
              'cms_id': '177979',
              'name': null,
              'image_url': null,
              'article_slug': 'abc',
              'shop_count': 15,
              'shops_live': 15,
              'shops_ended': 0,
              'started_at': '2026-09-23',
              'ended_at': null,
            },
          ],
        },
      ],
    });
    expect(weeks.weeks.single.items.single.name, isNull);
  });

  test('クーポン: 根拠の品名・注文例の品名が null でも読める', () {
    final raw =
        jsonDecode(
              File('test/fixtures/coupon_synthetic.json').readAsStringSync(),
            )
            as Map<String, dynamic>;
    // 施策の根拠（読まないが、null で落ちないこと）と注文例の品名を null にする
    for (final key in ['offers', 'upcoming']) {
      for (final o in (raw[key] as List).cast<Map<String, dynamic>>()) {
        if (o['basis'] case final Map<String, dynamic> basis) {
          basis['menu_name'] = null;
        }
      }
    }
    final patterns = (raw['best_deal'] as Map<String, dynamic>)['patterns'];
    for (final p in (patterns as List).cast<Map<String, dynamic>>()) {
      for (final i in (p['items'] as List).cast<Map<String, dynamic>>()) {
        i['name'] = null;
      }
    }

    final coupon = Coupon.fromJson(raw);
    expect(coupon.offers, isNotEmpty);
    final items = coupon.bestDeal!.patterns.expand((p) => p.items).toList();
    expect(items, isNotEmpty);
    expect(items.every((i) => i.name == null), isTrue);
    // 絵と値段は残る
    expect(items.first.priceYen, isNotNull);
  });

  test('地図の店: 店名・住所・営業時間が null でも読める', () {
    final shops = MapRepository.decodeShops(
      jsonEncode([
        {
          'code': '0000001202',
          'name': null,
          'name_roman': 'NISHISHINJUKU',
          'lat': 35.69,
          'lon': 139.69,
          'closing_date': null,
          'opening_date': null,
          'brands': <String>[],
          'address': null,
          'business_hours': null,
          'phone': '080-5928-1178',
          'temp_closed': null,
        },
      ]),
    );
    final shop = shops.single;
    expect(shop.name, isNull);
    expect(shop.address, isNull);
    expect(shop.businessHours, isNull);
    expect(shop.nameRoman, 'NISHISHINJUKU');
  });

  test('地図の品: 品名が null でも読める（地図には出さない）', () {
    final body = jsonEncode([
      {
        'campaign_id': '177979',
        'name': null,
        'start_date': '2026-09-23 15:00',
        'shops': ['0000001202'],
        'sold_out_shops': <String>[],
        'ended_shops': <Object>[],
        'ended_at': null,
        'article_slug': null,
        'thumbnail_url': null,
        'image_url': null,
      },
    ]);
    expect(MapRepository.decodeLimitedAll(body).single.name, isNull);
    expect(MapRepository.decodeLimited(body), isEmpty);
  });
}
