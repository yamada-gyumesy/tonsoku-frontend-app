import 'package:flutter_test/flutter_test.dart';
import 'package:tonsoku/features/map/domain/limited_status.dart';
import 'package:tonsoku/features/map/domain/shop_filter.dart';
import 'package:tonsoku/shared/models/limited_menu.dart';
import 'package:tonsoku/shared/models/shop.dart';

/// 絞り込み。**同じ種類の中は OR、種類をまたぐと AND**（牛めしレーダーと同じ）。
void main() {
  Shop shop(String code, List<String> brands) =>
      Shop(code: code, name: code, lat: 35, lon: 139, brands: brands);

  ShopLimited item(String id, LimitedAvailability a) => ShopLimited(
    menu: LimitedMenu(campaignId: id, name: id),
    availability: a,
  );

  final matsuya = shop('1', ['matsuya']);
  final mycurry = shop('2', ['mycurry']);
  final both = shop('3', ['mycurry', 'matsuya']);
  final alone = shop('4', []);
  final selfOnly = shop('5', ['matsunoya']);

  test('何も選ばなければ全店', () {
    const f = ShopFilter();
    expect(f.isActive, isFalse);
    for (final s in [matsuya, mycurry, both, alone, selfOnly]) {
      expect(f.matches(s, const []), isTrue);
    }
  });

  test('併設は OR', () {
    const f = ShopFilter(brands: {ShopBrand.matsuya, ShopBrand.mycurry});
    expect(f.matches(matsuya, const []), isTrue);
    expect(f.matches(mycurry, const []), isTrue);
    expect(f.matches(both, const []), isTrue);
    expect(f.matches(alone, const []), isFalse);
    // 松のや自身（matsunoya）は併設に数えない
    expect(f.matches(selfOnly, const []), isFalse);
  });

  test('松のや専門店は何も併設していない店（matsunoya だけの店も含む）', () {
    const f = ShopFilter(standalone: true);
    expect(f.isActive, isTrue);
    expect(f.matches(alone, const []), isTrue);
    expect(f.matches(selfOnly, const []), isTrue);
    expect(f.matches(matsuya, const []), isFalse);
    expect(f.matches(both, const []), isFalse);
    // 知らないブランドを併設する店も専門店ではない
    expect(f.matches(shop('6', ['unknown']), const []), isFalse);
  });

  test('専門店と併設は同じ種類なので OR', () {
    const f = ShopFilter(standalone: true, brands: {ShopBrand.mycurry});
    expect(f.matches(alone, const []), isTrue);
    expect(f.matches(mycurry, const []), isTrue);
    expect(f.matches(matsuya, const []), isFalse);
  });

  test('品も OR（どれか 1 つを扱えばよい）', () {
    const f = ShopFilter(menuIds: {'x', 'y'});
    expect(f.matches(alone, [item('y', LimitedAvailability.selling)]), isTrue);
    expect(f.matches(alone, [item('z', LimitedAvailability.selling)]), isFalse);
    expect(f.matches(alone, const []), isFalse);
  });

  test('種類をまたぐと AND', () {
    const f = ShopFilter(brands: {ShopBrand.mycurry}, menuIds: {'x'});
    final selling = [item('x', LimitedAvailability.selling)];
    expect(f.matches(mycurry, selling), isTrue);
    expect(f.matches(matsuya, selling), isFalse); // 品はあるが併設が違う
    expect(f.matches(mycurry, const []), isFalse); // 併設は合うが品が無い
  });

  test('終売は「含める」を入れた時だけ数える（発売前は常に数える）', () {
    const off = ShopFilter(menuIds: {'x'});
    const on = ShopFilter(menuIds: {'x'}, includeInactive: true);
    for (final a in LimitedAvailability.values) {
      final limited = [item('x', a)];
      expect(off.matches(alone, limited), a.isActive, reason: '$a');
      expect(on.matches(alone, limited), isTrue, reason: '$a');
    }
  });

  test('印に出す品は選んだ品だけ（選んでいなければ全部）', () {
    final limited = [
      item('x', LimitedAvailability.ended),
      item('y', LimitedAvailability.selling),
    ];
    expect(const ShopFilter().relevant(limited), limited);
    final onlyX = const ShopFilter(
      menuIds: {'x'},
      includeInactive: true,
    ).relevant(limited);
    expect(strongest(onlyX), LimitedAvailability.ended);
  });
}
