import 'package:flutter_test/flutter_test.dart';

import 'package:tonsoku/features/map/domain/map_link_filter.dart';
import 'package:tonsoku/features/map/domain/shop_filter.dart';

/// マップを絞り込みを入れて開くリンクの読み書き（Issue #30）。
///
/// **外向きはハッシュ、アプリの中はクエリ**で、値の書き方は同じ。どちらから
/// 読んでも同じ絞り込みになり、書いたものを読み直すと元に戻ること。
void main() {
  const full = MapLinkFilter(
    standalone: true,
    brands: {ShopBrand.matsuya, ShopBrand.mycurry},
    menuIds: {'177979', '174161'},
    includeInactive: true,
  );

  test('web の LP のリンクの形（ハッシュ）を読む', () {
    expect(
      MapLinkFilter.fromFragment(
        'menu=177979,174161&brand=standalone,matsuya,mycurry&include=1',
      ),
      full,
    );
  });

  test('ハッシュとクエリで同じ絞り込みになる', () {
    const raw = 'menu=177979&brand=matsuya&include=1';
    expect(
      MapLinkFilter.fromQuery(Uri.parse('/map?$raw')),
      MapLinkFilter.fromFragment(raw),
    );
  });

  group('往復', () {
    const cases = [
      full,
      MapLinkFilter(menuIds: {'177979'}),
      MapLinkFilter(standalone: true),
      MapLinkFilter(brands: {ShopBrand.mycurry}),
      MapLinkFilter(menuIds: {'177979'}, includeInactive: true),
    ];
    for (final filter in cases) {
      test('$filter', () {
        // アプリの中の行き先（クエリ）
        expect(filter.location, startsWith('/map?'));
        expect(MapLinkFilter.fromQuery(Uri.parse(filter.location)), filter);
        // 外向きの URL のハッシュ
        expect(MapLinkFilter.fromFragment(filter.fragment), filter);
        final url = Uri.parse('https://ton-soku.com/map/#${filter.fragment}');
        expect(MapLinkFilter.fromFragment(url.fragment), filter);
      });
    }
  });

  /// **カンマは生のまま書く**（`%2C` にすると人が読めない。web の LP と同じ形）
  test('ハッシュはカンマ区切りのまま、並びはチップの順', () {
    expect(
      full.fragment,
      'menu=177979,174161&brand=standalone,matsuya,mycurry&include=1',
    );
    // 書いた順に関わらず、ブランドはいつも同じ並び
    expect(
      MapLinkFilter.fromFragment('brand=mycurry,standalone')!.fragment,
      'brand=standalone,mycurry',
    );
  });

  /// **知らない値は黙って捨てる**（知らないブランド・`include` の 1 以外・知らない鍵）
  test('知らない値は捨てる', () {
    expect(
      MapLinkFilter.fromFragment('brand=yoshinoya,matsuya&include=true&x=1'),
      const MapLinkFilter(brands: {ShopBrand.matsuya}),
    );
    // 空の値・余分なカンマ・空白
    expect(
      MapLinkFilter.fromFragment('menu=,177979,, 174161 &brand='),
      const MapLinkFilter(menuIds: {'177979', '174161'}),
    );
  });

  test('同じ鍵を 2 回書いた形も読む', () {
    expect(
      MapLinkFilter.fromQuery(Uri.parse('/map?menu=177979&menu=174161')),
      const MapLinkFilter(menuIds: {'177979', '174161'}),
    );
  });

  /// **読める値が無ければ null（＝指定なし）。** 素の `/map` は下タブの再タップ
  /// でも来るので、そこで絞り込みを消さない
  test('読める値が無ければ null', () {
    expect(MapLinkFilter.fromQuery(Uri.parse('/map')), isNull);
    expect(
      MapLinkFilter.fromQuery(Uri.parse('/map/calendar?month=2026-10')),
      isNull,
    );
    expect(MapLinkFilter.fromFragment(''), isNull);
    expect(MapLinkFilter.fromFragment('brand=yoshinoya&include=0'), isNull);
    // 壊れた `%` でも落ちない
    expect(MapLinkFilter.fromFragment('menu=%E3%81'), isNull);
    expect(const MapLinkFilter().location, '/map');
  });

  test('マップの絞り込みにする', () {
    final f = full.toShopFilter();
    expect(f.standalone, isTrue);
    expect(f.brands, {ShopBrand.matsuya, ShopBrand.mycurry});
    expect(f.menuIds, {'177979', '174161'});
    expect(f.includeInactive, isTrue);
  });
}
