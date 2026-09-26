import 'package:flutter/foundation.dart';

import 'package:tonsoku/core/router/app_router.dart';
import 'package:tonsoku/features/map/domain/shop_filter.dart';

/// マップを開く時に**最初から入れておく絞り込み**。リンクの形の読み書きは
/// ここ 1 箇所に閉じる（Issue #30）。
///
/// **形は 2 つある。値の書き方は同じ。**
///
/// - **外から来る URL はハッシュ**: `https://ton-soku.com/map/#menu=177979,174161&brand=standalone,matsuya&include=1`
///   （web のカレンダーの `/calendar/#category=…&month=…` に揃えた。web の
///   LP のリンクもこの形で作る。読むのは `deepLinkTarget`）
/// - **アプリの中の go_router の行き先はクエリ**: `/map?menu=…&brand=…&include=1`
///   （[AppRoutes.calendar] と同じ理由。ルートの外 —— 通知・ユニバーサル
///   リンク —— から来る時にも同じ形で書ける）。アプリの中から開く時も
///   [location] で組む（`context.go(filter.location)`）
///
/// 鍵:
///
/// - `menu` … 店舗限定の品（`campaign_id`。カンマ区切りで複数）
/// - `brand` … `standalone`（松のや専門店）・`matsuya`・`mycurry`（カンマ区切り。
///   値は [ShopBrand.key]）
/// - `include=1` … 売り切れ・終売の店も含める
///
/// **知らない値は黙って捨てる。** 知らないブランドはここで捨て、配信から
/// 消えた品はマップが開いた後に `ShopFilter.retainMenus` が捨てる（品は
/// 配信を見ないと分からない）。同じ鍵を 2 回書いた形（`menu=a&menu=b`）も読む。
@immutable
class MapLinkFilter {
  const MapLinkFilter({
    this.standalone = false,
    this.brands = const {},
    this.menuIds = const {},
    this.includeInactive = false,
  });

  static const menuKey = 'menu';
  static const brandKey = 'brand';
  static const includeKey = 'include';

  /// `brand` の中で「松のや専門店」を表す値（[ShopFilter.standalone]）。
  /// 併設ではないので [ShopBrand] には載っていない。
  static const standaloneValue = 'standalone';

  final bool standalone;
  final Set<ShopBrand> brands;
  final Set<String> menuIds;
  final bool includeInactive;

  bool get isEmpty =>
      !standalone && brands.isEmpty && menuIds.isEmpty && !includeInactive;

  /// アプリの中の行き先（`/map?…`）から読む。**絞り込みが無ければ null。**
  ///
  /// **null と「空の絞り込み」を分ける理由:** 素の `/map` は下タブの再タップ
  /// （`goBranch` がブランチの初期位置へ `go` する）でも来る。そこで今の
  /// 絞り込みを消すと、地図へ戻るつもりでタブを押した人の絞り込みが消える。
  /// なので**何も読めなかった時は「指定なし」**として、マップは今の絞り込みに
  /// 触らない。
  static MapLinkFilter? fromQuery(Uri uri) =>
      _fromParameters(uri.queryParametersAll);

  /// 外から来た URL のハッシュ（`#` の後ろ。`Uri.fragment`）から読む。
  /// **絞り込みが無ければ null**（[fromQuery] と同じ）。
  static MapLinkFilter? fromFragment(String fragment) {
    if (fragment.isEmpty) return null;
    try {
      return _fromParameters(Uri(query: fragment).queryParametersAll);
    } on FormatException {
      // 壊れた `%` などは読めないものとして扱う（開くのはマップのまま）
      return null;
    }
  }

  static MapLinkFilter? _fromParameters(Map<String, List<String>> params) {
    List<String> values(String key) => [
      for (final raw in params[key] ?? const <String>[])
        for (final v in raw.split(','))
          if (v.trim() case final s when s.isNotEmpty) s,
    ];

    final brandValues = values(brandKey);
    final filter = MapLinkFilter(
      standalone: brandValues.contains(standaloneValue),
      brands: {
        for (final brand in ShopBrand.values)
          if (brandValues.contains(brand.key)) brand,
      },
      menuIds: values(menuKey).toSet(),
      includeInactive: values(includeKey).contains('1'),
    );
    return filter.isEmpty ? null : filter;
  }

  /// 鍵と値（空の鍵は書かない）。[location] と [fragment] の元。
  Map<String, String> toQuery() => {
    if (menuIds.isNotEmpty) menuKey: menuIds.join(','),
    if (standalone || brands.isNotEmpty)
      brandKey: [
        if (standalone) standaloneValue,
        // **並びは [ShopBrand] の順**（チップの並び）。同じ絞り込みが
        // いつも同じ URL になる
        for (final brand in ShopBrand.values)
          if (brands.contains(brand)) brand.key,
      ].join(','),
    if (includeInactive) includeKey: '1',
  };

  /// アプリの中の行き先（`/map?menu=…`）。空なら素の `/map`。
  String get location {
    final query = toQuery();
    return Uri(
      path: AppRoutes.map,
      queryParameters: query.isEmpty ? null : query,
    ).toString();
  }

  /// 外向きの URL のハッシュ（`#` の後ろ）。**web の LP のリンクと同じ形。**
  ///
  /// カンマは区切りなので生のまま書き、値の中だけを符号化する
  /// （`Uri` に任せると `%2C` になり、人が読めない URL になる）。
  String get fragment => [
    for (final MapEntry(:key, :value) in toQuery().entries)
      '$key=${value.split(',').map(Uri.encodeQueryComponent).join(',')}',
  ].join('&');

  /// マップの絞り込みにする。
  ShopFilter toShopFilter() => ShopFilter(
    standalone: standalone,
    brands: brands,
    menuIds: menuIds,
    includeInactive: includeInactive,
  );

  @override
  bool operator ==(Object other) =>
      other is MapLinkFilter &&
      other.standalone == standalone &&
      setEquals(other.brands, brands) &&
      setEquals(other.menuIds, menuIds) &&
      other.includeInactive == includeInactive;

  @override
  int get hashCode => Object.hash(
    standalone,
    Object.hashAllUnordered(brands),
    Object.hashAllUnordered(menuIds),
    includeInactive,
  );

  @override
  String toString() => 'MapLinkFilter($fragment)';
}
