import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tonsoku/core/i18n/locale_controller.dart';
import 'package:tonsoku/core/theme/app_colors.dart';
import 'package:tonsoku/features/map/domain/map_format.dart';
import 'package:tonsoku/features/map/domain/shop_filter.dart';
import 'package:tonsoku/shared/models/limited_menu.dart';
import 'package:tonsoku/shared/widgets/cdn_image.dart';
import 'package:tonsoku/shared/widgets/optical_center.dart';

/// 地図の上、検索バーの直下に置く絞り込み（ユーザーの指定）。上から:
///
/// 1. **松のや専門店と併設**（横並び。[_BrandChip]）
/// 2. **店舗限定の品**（縦並び。[MenuChip]。複数選べる）。品が 1 つも無い週は出さない
/// 3. 品を選んだ時だけ **「終売の店も含める」**（選んでいない時は意味を持たない）
///
/// 地図の上に浮かせるので、どの部品も面色の地に影を付ける（地が地図の模様に
/// なるため）。角は丸めた四角（ユーザーの指定。丸い端のピルにしない）。
class MapFilters extends ConsumerWidget {
  const MapFilters({
    required this.filter,
    required this.menus,
    required this.onChanged,
    super.key,
  });

  final ShopFilter filter;

  /// 選べる品（`app/limited.json` の並び）。
  final List<LimitedMenu> menus;
  final ValueChanged<ShopFilter> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final t = ref.watch(messagesProvider);

    Set<T> toggle<T>(Set<T> set, T value) =>
        set.contains(value) ? ({...set}..remove(value)) : {...set, value};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 横に流す（画面が狭い端末・英語の長い名前で溢れさせない）
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              _BrandChip(
                label: t.mapStandalone,
                selected: filter.standalone,
                onTap: () =>
                    onChanged(filter.copyWith(standalone: !filter.standalone)),
              ),
              for (final brand in ShopBrand.values) ...[
                const SizedBox(width: 6),
                _BrandChip(
                  label: brandLabel(brand, t),
                  selected: filter.brands.contains(brand),
                  onTap: () => onChanged(
                    filter.copyWith(brands: toggle(filter.brands, brand)),
                  ),
                ),
              ],
            ],
          ),
        ),
        for (final menu in menus) ...[
          const SizedBox(height: 6),
          MenuChip(
            menu: menu,
            selected: filter.menuIds.contains(menu.campaignId),
            onTap: () => onChanged(
              filter.copyWith(menuIds: toggle(filter.menuIds, menu.campaignId)),
            ),
          ),
        ],
        if (filter.menuIds.isNotEmpty) ...[
          const SizedBox(height: 6),
          Material(
            color: colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: colors.border),
            ),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: _IncludeInactive(
                label: t.mapIncludeInactive,
                value: filter.includeInactive,
                onChanged: (v) =>
                    onChanged(filter.copyWith(includeInactive: v)),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// 松のや専門店・併設のトグル。選ばれたら文字色で塗り、面色の文字（記事一覧の
/// タグのトグル `TagToggleChip` と同じ塗り分け）。地図の上に浮かせるので、
/// 選ばれていない時も面色の地を敷く。
class _BrandChip extends StatelessWidget {
  const _BrandChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      toggled: selected,
      button: true,
      child: Material(
        color: selected ? colors.text : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: selected ? colors.text : colors.border),
        ),
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                height: 1.2,
                color: selected ? colors.surface : colors.textSub,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 出している店の数を**丸で囲んで**出す（ユーザーの指定。右上の列、帰属の (i) の下）。
class ShopCountBadge extends ConsumerWidget {
  const ShopCountBadge({required this.count, super.key});

  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final t = ref.watch(messagesProvider);
    return Semantics(
      label: t.homeLimitedShops(count),
      child: ExcludeSemantics(
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.surface,
            // 地の上の赤（`primaryText`）の輪
            border: Border.all(color: colors.primaryText, width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                  color: colors.primaryText,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                t.mapShopsUnit,
                style: TextStyle(
                  fontSize: 9,
                  height: 1.1,
                  color: colors.textSub,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 店舗限定の品のチップ（写真 ＋ 品名 ＋ 店の数）。**角は丸めた四角**（ユーザーの
/// 指定。丸い端のピルにしない）。選ばれていなければ面色の地に罫線、選ばれたら
/// 地の上の赤（`primaryText`）で文字と枠、地はその 6% を面色に重ねる。
///
/// 店の数は**終売の店も含めた数**で、終売があれば「（終売: X件）」を添える
/// （ユーザーの指定。[LimitedMenu] の `shops` は売り切れの店も含むので、
/// 合計は `shops` ＋ `ended_shops`、終売は売り切れ ＋ `ended_shops`。
/// 画面では売り切れも終売と呼ぶ。`LimitedAvailability`）。
class MenuChip extends ConsumerWidget {
  const MenuChip({
    required this.menu,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final LimitedMenu menu;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final t = ref.watch(messagesProvider);
    final line = colors.primaryText;
    final image = menu.thumbnailUrl ?? menu.imageUrl ?? '';
    final total = menu.shops.length + menu.endedShops.length;
    final ended = menu.soldOutShops.length + menu.endedShops.length;
    final radius = BorderRadius.circular(8);

    return Semantics(
      toggled: selected,
      button: true,
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: selected ? line.withValues(alpha: 0.6) : colors.border,
          ),
        ),
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        child: Ink(
          color: selected ? line.withValues(alpha: 0.06) : null,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: CdnImage(url: image, width: 34, height: 34),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          menu.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.2,
                            color: selected ? line : colors.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          t.mapMenuShops(total, ended),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.2,
                            color: colors.textSub,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IncludeInactive extends StatelessWidget {
  const _IncludeInactive({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;

  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return MergeSemantics(
      child: InkWell(
        onTap: () => onChanged(!value),
        // 押す場所の上下の余白（印を 18 に詰めたぶんをここで持つ）
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // **印の左端をチップの左端（段の余白 16）に揃える。** Checkbox は
              // 18 の印の周りに押す場所の余白を持つので、印の大きさに詰めて置く
              SizedBox.square(
                dimension: 18,
                child: Checkbox(
                  value: value,
                  onChanged: (v) => onChanged(v ?? false),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  // 印は地の上に置くので `primaryText`（テーマの `colorScheme.primary` と同じ）
                  activeColor: colors.primaryText,
                  checkColor: colors.isDark ? colors.bg : colors.onPrimary,
                  side: BorderSide(color: colors.textSub, width: 1.5),
                ),
              ),
              const SizedBox(width: 8),
              // **字面を印の中心に揃える**（行の中央に置くだけだと字が沈んで見える。
              // ユーザーの指摘）。OpticalCenter だけでは、12pt の Klee One で
              // 印より 0.5pt 低いまま残った（iPhone 17 Pro の実測。印と
              // 「終売の店も含める」の字面の縦の中心の差）ので、その分を足す
              Flexible(
                child: Transform.translate(
                  offset: const Offset(0, -0.5),
                  child: OpticalCenter(
                    fontSize: 12,
                    child: Text(
                      label,
                      style: TextStyle(fontSize: 12, color: colors.textSub),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
