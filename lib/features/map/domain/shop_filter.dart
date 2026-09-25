import 'package:tonsoku/features/map/domain/limited_status.dart';
import 'package:tonsoku/shared/models/shop.dart';

/// 併設のブランド。**フィルタに出すのはここに載っているものだけ。**
///
/// **`matsunoya` を載せない。** 配信の `brands` には松のや自身が入ることがあるが、
/// とん速のマップは全店が松のやの店（専門店ベース）なので「松のや併設」は意味を
/// 持たない。知らないブランドが増えても、名前を決めるまでは出さない（名前の
/// 無いチップを出すより、出さないほうが誤解が無い）。
///
/// **並びはチップの並び。** 店の多い順（本番で松屋 483 軒・マイカリー食堂 86 軒）。
enum ShopBrand {
  matsuya('matsuya'),
  mycurry('mycurry');

  const ShopBrand(this.key);

  /// 配信の `brands` に入る値。
  final String key;
}

/// マップの絞り込み。**何も選ばなければ全店を出す。**
///
/// 牛めしレーダー（`shop_filter_provider.dart`）と同じく、**同じ種類の中は OR、
/// 種類をまたぐと AND**。「松屋併設」と「マイカリー食堂併設」を両方選ぶと
/// どちらかを併設する店、そこへ品を選ぶと「そのどちらかを併設し、かつ
/// その品を扱う店」になる。
class ShopFilter {
  const ShopFilter({
    this.brands = const {},
    this.menuIds = const {},
    this.includeInactive = false,
  });

  final Set<ShopBrand> brands;

  /// 選んだ品（`campaign_id`）。
  final Set<String> menuIds;

  /// 「売り切れ・終売の店も含める」。**品を選んでいる時だけ意味を持つ。**
  final bool includeInactive;

  bool get isActive => brands.isNotEmpty || menuIds.isNotEmpty;

  ShopFilter copyWith({
    Set<ShopBrand>? brands,
    Set<String>? menuIds,
    bool? includeInactive,
  }) => ShopFilter(
    brands: brands ?? this.brands,
    menuIds: menuIds ?? this.menuIds,
    includeInactive: includeInactive ?? this.includeInactive,
  );

  /// [shop] を出すか。[limited] はその店の品と状態（`LimitedIndex.at`）。
  bool matches(Shop shop, List<ShopLimited> limited) {
    if (brands.isNotEmpty && !brands.any((b) => shop.brands.contains(b.key))) {
      return false;
    }
    if (menuIds.isNotEmpty && relevant(limited).isEmpty) return false;
    return true;
  }

  /// 印と店の詳細に出す品。**品を選んでいる時は選んだ品だけ**（選んでいない品の
  /// 状態で印の色が変わると、何を見ているのか分からなくなる）。
  ///
  /// 品を選んでいて「売り切れ・終売の店も含める」が外れている時は、
  /// 販売中・発売前のものだけ。
  List<ShopLimited> relevant(List<ShopLimited> limited) {
    if (menuIds.isEmpty) return limited;
    return [
      for (final item in limited)
        if (menuIds.contains(item.menu.campaignId) &&
            (includeInactive || item.availability.isActive))
          item,
    ];
  }
}
