import 'package:clock/clock.dart';

import 'package:tonsoku/features/map/domain/jst.dart';
import 'package:tonsoku/shared/models/limited_menu.dart';

/// 店舗限定メニューの、**ある店での**状態。
///
/// **並びは強い順**（1 軒が複数の品を持つ時、印には一番強いものを出す）。
/// 「いま食べられる」が最優先で、発売前・売り切れ・終売の順に弱くなる。
///
/// **売り切れと終売は分けて出す**（ユーザーの判断。一度「終売」に揃えたが戻した）。
/// 売り切れは一時的（15 分ごとの巡回で戻りうる）、終売は戻らない。印も変える
/// （`LimitedMark`）。
enum LimitedAvailability {
  /// 販売中（`shops` にあり、`sold_out_shops` に無い）。
  selling,

  /// 発売前（`shops` にあるが `start_date` がまだ来ていない）。
  upcoming,

  /// 売り切れ（`sold_out_shops` にある）。**巡回は 15 分ごと**なので、
  /// 戻っている可能性はある
  soldOut,

  /// 終売（`ended_shops` にある。全店で終売した品もここ）。
  ended;

  /// 絞り込みで「扱っている店」に数えるか。**売り切れ・終売は
  /// 「売り切れ・終売の店も含める」を入れた時だけ数える**。
  /// 発売前は数える（その店が取扱店であることは確かなので）
  bool get isActive => this == selling || this == upcoming;
}

/// 1 軒の店での 1 品の状態。
class ShopLimited {
  const ShopLimited({
    required this.menu,
    required this.availability,
    this.at,
    this.dateOnly = false,
  });

  final LimitedMenu menu;
  final LimitedAvailability availability;

  /// 発売前なら発売の時刻、終売なら終売の時刻。無ければ null。
  final DateTime? at;

  /// [at] が日付だけか（終売の時刻が分からない品）。**時刻を出さない。**
  final bool dateOnly;
}

/// 店のコードから、その店に関わる品を引く索引。
///
/// **時刻に依存しない形だけを持つ**（どの品がどの店に載っているか）。
/// 発売前かどうかは時刻で変わるので [LimitedIndex.at] が呼ばれるたびに求める
/// ―― 牛めしレーダーの `shopLimitedMenuMapProvider` の注記と同じ理由で、
/// provider に判定を焼き付けると、開いたまま発売の時刻をまたいでも変わらない。
class LimitedIndex {
  LimitedIndex(this.menus) {
    for (final menu in menus) {
      for (final code in {
        ...menu.shops,
        for (final e in menu.endedShops) e.code,
      }) {
        (_byShop[code] ??= []).add(menu);
      }
    }
  }

  static final empty = LimitedIndex(const []);

  final List<LimitedMenu> menus;
  final _byShop = <String, List<LimitedMenu>>{};

  /// その店に関わる品と、それぞれの状態（配信の並び順のまま）。
  List<ShopLimited> at(String shopCode, {DateTime? now}) {
    final list = _byShop[shopCode];
    if (list == null) return const [];
    return [for (final menu in list) ?availabilityAt(menu, shopCode, now: now)];
  }
}

/// [menu] の、[shopCode] の店での状態。**その店に関わりが無ければ null。**
///
/// **`shops` を `ended_shops` より先に見る。** 掲載が外れた店が後で戻ることがあり、
/// 両方に載っている時は「いま載っている」ほうが正しい。
ShopLimited? availabilityAt(
  LimitedMenu menu,
  String shopCode, {
  DateTime? now,
}) {
  final at = now ?? clock.now();

  if (menu.shops.contains(shopCode)) {
    if (menu.soldOutShops.contains(shopCode)) {
      return ShopLimited(menu: menu, availability: LimitedAvailability.soldOut);
    }
    final start = parseJst(menu.startDate);
    if (start != null && start.isAfter(at)) {
      return ShopLimited(
        menu: menu,
        availability: LimitedAvailability.upcoming,
        at: start,
      );
    }
    return ShopLimited(menu: menu, availability: LimitedAvailability.selling);
  }

  for (final ended in menu.endedShops) {
    if (ended.code != shopCode) continue;
    // 店ごとの時刻が読めなければ、全店の終売の時刻に落とす
    final own = parseJst(ended.endedAt);
    final whole = menu.endedAt;
    return ShopLimited(
      menu: menu,
      availability: LimitedAvailability.ended,
      at: own ?? parseJst(whole),
      dateOnly: own == null && whole != null && isDateOnly(whole),
    );
  }
  return null;
}

/// 一番強い状態（[LimitedAvailability] の並び）。空なら null。
LimitedAvailability? strongest(Iterable<ShopLimited> items) {
  LimitedAvailability? best;
  for (final item in items) {
    if (best == null || item.availability.index < best.index) {
      best = item.availability;
    }
  }
  return best;
}
