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

/// 何も併設していない店（松のや専門店）か。`matsunoya` は松のや自身なので数えない。
///
/// **知らないブランドを併設する店も専門店に数えない**（併設は併設。名前を決めて
/// [ShopBrand] に載せるまで、その店は「専門店」でも「◯◯併設」でも絞れない）。
bool isStandalone(Shop shop) => shop.brands.every((b) => b == 'matsunoya');

/// マップの絞り込み。**何も選ばなければ全店を出す。**
///
/// 牛めしレーダー（`shop_filter_provider.dart`）と同じく、**同じ種類の中は OR、
/// 種類をまたぐと AND**。「松屋併設」と「マイカリー食堂併設」を両方選ぶと
/// どちらかを併設する店、そこへ品を選ぶと「そのどちらかを併設し、かつ
/// その品を扱う店」になる。
///
/// **「松のや専門店」（[standalone]）は併設と同じ種類**（店の形の絞り込み）。
/// 専門店と松屋併設を両方選ぶと「専門店か、松屋併設の店」になる。
class ShopFilter {
  const ShopFilter({
    this.standalone = false,
    this.brands = const {},
    this.menuIds = const {},
    this.includeInactive = false,
  });

  /// 「松のや専門店」（[isStandalone]）。
  final bool standalone;

  final Set<ShopBrand> brands;

  /// 選んだ品（`campaign_id`）。
  final Set<String> menuIds;

  /// 「売り切れ・終売の店も含める」。**品を選んでいる時だけ意味を持つ。**
  final bool includeInactive;

  bool get isActive => standalone || brands.isNotEmpty || menuIds.isNotEmpty;

  ShopFilter copyWith({
    bool? standalone,
    Set<ShopBrand>? brands,
    Set<String>? menuIds,
    bool? includeInactive,
  }) => ShopFilter(
    standalone: standalone ?? this.standalone,
    brands: brands ?? this.brands,
    menuIds: menuIds ?? this.menuIds,
    includeInactive: includeInactive ?? this.includeInactive,
  );

  /// 選んだ品を、**いま配信にある品（[available]）だけに絞り直す。**
  ///
  /// 品は全店終売から 14 日で配信から消える。選んだまま消えるとチップも消えて
  /// 外す手段が無くなり、地図が 0 店のまま戻れなくなる（タブの状態はアプリを
  /// 終えるまで残る）。変わらなければ自身を返す。
  ShopFilter retainMenus(Set<String> available) {
    if (menuIds.every(available.contains)) return this;
    return copyWith(menuIds: menuIds.where(available.contains).toSet());
  }

  /// [shop] を出すか。[limited] はその店の品と状態（`LimitedIndex.at`）。
  bool matches(Shop shop, List<ShopLimited> limited) {
    if (standalone || brands.isNotEmpty) {
      final kind =
          (standalone && isStandalone(shop)) ||
          brands.any((b) => shop.brands.contains(b.key));
      if (!kind) return false;
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
