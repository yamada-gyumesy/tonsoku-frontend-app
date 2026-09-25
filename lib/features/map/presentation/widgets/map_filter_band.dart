import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tonsoku/core/i18n/locale_controller.dart';
import 'package:tonsoku/core/theme/app_colors.dart';
import 'package:tonsoku/features/home/presentation/article_list_page.dart';
import 'package:tonsoku/features/map/domain/map_format.dart';
import 'package:tonsoku/features/map/domain/shop_filter.dart';
import 'package:tonsoku/shared/models/limited_menu.dart';
import 'package:tonsoku/shared/widgets/cdn_image.dart';

/// マップの上に貼る絞り込みの帯。**記事一覧の絞り込み（web の `.sticky-band`）と
/// 同じ見た目**: 面色の地に、横に流すチップの段を重ねる。
///
/// - 上の段 … **店舗限定の品**（写真つき。複数選べる）。品が 1 つも無い週は段ごと出さない
/// - 下の段 … **併設**（記事一覧のタグと同じトグル）と、出している店の数
/// - 品を選んだ時だけ … **「売り切れ・終売の店も含める」**（品を選んでいない時は
///   意味を持たないので出さない）
class MapFilterBand extends ConsumerWidget {
  const MapFilterBand({
    required this.filter,
    required this.menus,
    required this.shownCount,
    required this.onChanged,
    super.key,
  });

  final ShopFilter filter;

  /// 選べる品（`app/limited.json` の並び）。
  final List<LimitedMenu> menus;

  /// いま地図に出している店の数。
  final int? shownCount;
  final ValueChanged<ShopFilter> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final t = ref.watch(messagesProvider);

    Set<T> toggle<T>(Set<T> set, T value) =>
        set.contains(value) ? ({...set}..remove(value)) : {...set, value};

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (menus.isNotEmpty) ...[
              _Row(
                children: [
                  for (final menu in menus)
                    MenuChip(
                      menu: menu,
                      selected: filter.menuIds.contains(menu.campaignId),
                      onTap: () => onChanged(
                        filter.copyWith(
                          menuIds: toggle(filter.menuIds, menu.campaignId),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Expanded(
                  child: _Row(
                    children: [
                      for (final brand in ShopBrand.values)
                        TagToggleChip(
                          label: brandLabel(brand, t),
                          selected: filter.brands.contains(brand),
                          onTap: () => onChanged(
                            filter.copyWith(
                              brands: toggle(filter.brands, brand),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (shownCount case final n?)
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Text(
                      t.homeLimitedShops(n),
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSub,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
              ],
            ),
            if (filter.menuIds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 4, right: 16, top: 2),
                child: _IncludeInactive(
                  label: t.mapIncludeInactive,
                  value: filter.includeInactive,
                  onChanged: (v) =>
                      onChanged(filter.copyWith(includeInactive: v)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 横に流す 1 段（記事一覧の `_Row` と同じ。左右の余白は段が持つ）。
class _Row extends StatelessWidget {
  const _Row({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      children: [
        for (final (i, child) in children.indexed) ...[
          if (i > 0) const SizedBox(width: 6),
          child,
        ],
      ],
    ),
  );
}

/// 店舗限定の品のチップ（写真 ＋ 品名）。**見た目は記事一覧のカテゴリのチップ
/// （`FilterChipButton`）に揃える**: 選ばれていなければ枠と副テキスト、選ばれたら
/// 地の上の赤（`primaryText`。「メニュー」カテゴリの色と同じ）で文字と枠、地は
/// その 6%。
class MenuChip extends StatelessWidget {
  const MenuChip({
    required this.menu,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final LimitedMenu menu;
  final bool selected;
  final VoidCallback onTap;

  /// 品名が長い（「たっぷりねぎと味噌ダレの超厚切りリブロースかつ定食」）ので、
  /// チップの幅に上限を付けて省略する。
  static const maxLabelWidth = 180.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final line = colors.primaryText;
    final image = menu.thumbnailUrl ?? menu.imageUrl ?? '';

    return Semantics(
      toggled: selected,
      button: true,
      child: Material(
        color: selected ? line.withValues(alpha: 0.06) : Colors.transparent,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? line.withValues(alpha: 0.35) : colors.border,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(3, 3, 10, 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipOval(child: CdnImage(url: image, width: 24, height: 24)),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: maxLabelWidth),
                  child: Text(
                    menu.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1,
                      color: selected ? line : colors.textSub,
                    ),
                  ),
                ),
              ],
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              // 印は地の上に置くので `primaryText`（テーマの `colorScheme.primary` と同じ）
              activeColor: colors.primaryText,
              checkColor: colors.isDark ? colors.bg : colors.onPrimary,
              side: BorderSide(color: colors.textSub, width: 1.5),
            ),
            Flexible(
              child: Text(
                label,
                style: TextStyle(fontSize: 12, color: colors.textSub),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
