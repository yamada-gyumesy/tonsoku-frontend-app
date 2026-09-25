import 'package:flutter_test/flutter_test.dart';
import 'package:tonsoku/features/map/presentation/widgets/map_search.dart';
import 'package:tonsoku/shared/models/shop.dart';

/// 店の検索（牛めしレーダーの `searchResultsProvider` と同じ規則）。
void main() {
  Shop shop(String code, String name, [String? roman]) =>
      Shop(code: code, name: name, nameRoman: roman, lat: 35, lon: 139);

  final shops = [
    shop('0000001208', '松のや 西船橋店', 'Nishifunabashi'),
    shop('0000001232', '松のや 船橋店', 'Funabashi'),
    shop('0000002510', '松のや 1208号線店'),
  ];

  test('空なら何も出さない', () {
    expect(searchShops('  ', shops), isEmpty);
  });

  test('店舗番号（下 4 桁）の一致を先に、続けて名前の部分一致', () {
    final r = searchShops('1208', shops);
    expect(r.map((s) => s.code), ['0000001208', '0000002510']);
    // 全角の数字でも同じ（日本語入力のまま打った時）
    expect(searchShops('１２０８', shops).first.code, '0000001208');
  });

  test('店名・ローマ字名（大文字小文字を区別しない）', () {
    expect(searchShops('船橋', shops), hasLength(2));
    expect(searchShops('funabashi', shops), hasLength(2));
    expect(searchShops('NISHI', shops).single.code, '0000001208');
  });

  test('20 件まで', () {
    final many = [for (var i = 0; i < 30; i++) shop('${1000 + i}', '松のや $i店')];
    expect(searchShops('松のや', many), hasLength(MapSearch.maxResults));
  });
}
