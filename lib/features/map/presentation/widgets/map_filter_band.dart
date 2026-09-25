import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tonsoku/core/i18n/locale_controller.dart';
import 'package:tonsoku/core/theme/app_colors.dart';
import 'package:tonsoku/features/map/domain/limited_status.dart';
import 'package:tonsoku/features/map/domain/map_format.dart';
import 'package:tonsoku/features/map/domain/jst.dart';
import 'package:tonsoku/features/map/domain/shop_filter.dart';
import 'package:tonsoku/features/map/presentation/widgets/shop_marker.dart';
import 'package:tonsoku/shared/models/limited_menu.dart';
import 'package:tonsoku/shared/widgets/cdn_image.dart';
import 'package:tonsoku/shared/widgets/optical_center.dart';

/// 地図の上、検索バーの直下に置く絞り込み（ユーザーの指定）。上から:
///
/// 1. **松のや専門店と併設**（横並び。[_BrandChip]）。**畳んでおき、検索バーの右の
///    フィルタのボタン（[MapFilterButton]）で開く**（ユーザーの指定。邪魔なので）
/// 2. **店舗限定の品**（縦並び。[MenuChip]。複数選べる）。品が 1 つも無い週は出さない。
///    **店舗限定の表示を閉じている間は、代わりに動画の案内（[MapUnlockNotice]）を 1 つ**
/// 3. 品を選んだ時だけ **「売り切れ・終売の店も含める」**（選んでいない時は意味を持たない）
///
/// 地図の上に浮かせるので、どの部品も面色の地に影を付ける（地が地図の模様に
/// なるため）。角は丸めた四角（ユーザーの指定。丸い端のピルにしない）。
class MapFilters extends ConsumerWidget {
  const MapFilters({
    required this.filter,
    required this.menus,
    required this.onChanged,
    this.showBrands = false,
    this.notice,
    super.key,
  });

  final ShopFilter filter;

  /// 松のや専門店・併設の段を出すか。**既定は畳む**（ユーザーの指定。地図を
  /// 塞ぐので、検索バーの右のフィルタのボタン（[MapFilterButton]）で開く）。
  final bool showBrands;

  /// 選べる品（`app/limited.json` の並び）。
  final List<LimitedMenu> menus;
  final ValueChanged<ShopFilter> onChanged;

  /// 品のチップの代わりに置く案内（店舗限定の表示を閉じている時の
  /// [MapUnlockNotice]）。**渡した時は品のチップを出さない。**
  final Widget? notice;

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
        if (showBrands)
          // 横に流す（画面が狭い端末・英語の長い名前で溢れさせない）
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                _BrandChip(
                  dot: ShopDot.colorsFor(const [], colors),
                  label: t.mapStandalone,
                  selected: filter.standalone,
                  onTap: () => onChanged(
                    filter.copyWith(standalone: !filter.standalone),
                  ),
                ),
                for (final brand in ShopBrand.values) ...[
                  const SizedBox(width: 6),
                  _BrandChip(
                    dot: ShopDot.colorsFor([brand.key], colors),
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
        if (notice case final notice?) ...[
          if (showBrands) const SizedBox(height: 6),
          notice,
        ] else
          for (final (i, menu) in menus.indexed) ...[
            if (showBrands || i > 0) const SizedBox(height: 6),
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
        if (filter.menuIds.isNotEmpty) ...[
          const SizedBox(height: 6),
          Material(
            color: MapPalette.of(colors).panel,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: MapPalette.of(colors).panelBorder),
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

/// 店舗限定の表示を閉じている時に、品のチップの場所に置く案内（ユーザーの指定）。
/// **押すとリワード動画を出す**（見終えると 6 時間開放。`MapUnlockController`）。
///
/// 見た目は品のチップ（[MenuChip]）と同じ角丸の板。文言は状態だけ（開放の長さは
/// 書かない。ユーザーの指定）。読み込み中は鍵の代わりに回る印を出し、押せなくする。
class MapUnlockNotice extends ConsumerWidget {
  const MapUnlockNotice({required this.busy, required this.onTap, super.key});

  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final t = ref.watch(messagesProvider);
    return Semantics(
      button: true,
      child: Material(
        color: MapPalette.of(colors).panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: MapPalette.of(colors).panelBorder),
        ),
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: busy ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
            child: Row(
              children: [
                SizedBox.square(
                  dimension: 20,
                  child: busy
                      ? const Padding(
                          padding: EdgeInsets.all(2),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          Icons.lock_outline,
                          size: 20,
                          color: colors.textSub,
                        ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t.mapUnlockLimited,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.2,
                      color: colors.text,
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

/// 検索バーの右端のフィルタのボタン。押すと松のや専門店・併設の段を開閉する。
/// **選んでいる間は印を付ける**（畳んでいても絞っていることが分かるように）。
class MapFilterButton extends ConsumerWidget {
  const MapFilterButton({
    required this.open,
    required this.active,
    required this.onTap,
    super.key,
  });

  /// 段を開いているか。
  final bool open;

  /// 松のや専門店・併設のどれかを選んでいるか。
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final t = ref.watch(messagesProvider);
    return IconButton(
      onPressed: onTap,
      tooltip: t.mapFilter,
      isSelected: open,
      visualDensity: VisualDensity.compact,
      icon: Badge(
        isLabelVisible: active,
        smallSize: 8,
        // 地の上の赤（`primaryText`）
        backgroundColor: colors.primaryText,
        child: Icon(
          Icons.tune_rounded,
          size: 20,
          color: open || active ? colors.primaryText : colors.textSub,
        ),
      ),
    );
  }
}

/// 松のや専門店・併設のトグル。選ばれた時の見た目は品のチップ（[MenuChip]）に
/// 揃える。地図の上に浮かせるので、選ばれていない時も面色の地を敷く。
class _BrandChip extends StatelessWidget {
  const _BrandChip({
    required this.dot,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  /// 地図の点と同じ塗り分け（[ShopDot]。ユーザーの指定）。
  final List<Color> dot;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // 選んだ時は品のチップ（[MenuChip]）と同じ: 地の上の赤（`primaryText`）の
    // 枠と文字、地はその 6%（ユーザーの指定。文字色で塗ると黒くなって浮いた）
    final line = colors.primaryText;
    return Semantics(
      toggled: selected,
      button: true,
      child: Material(
        color: MapPalette.of(colors).panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: selected
                ? line.withValues(alpha: 0.6)
                : MapPalette.of(colors).panelBorder,
          ),
        ),
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        child: Ink(
          color: selected ? line.withValues(alpha: 0.06) : null,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShopDot(colors: dot, size: 10),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.2,
                      color: selected ? line : colors.textSub,
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

/// 店舗限定の品のチップ（写真 ＋ 品名 ＋ 店の数）。**角は丸めた四角**（ユーザーの
/// 指定。丸い端のピルにしない）。選ばれていなければ面色の地に罫線、選ばれたら
/// 地の上の赤（`primaryText`）で文字と枠、地はその 6% を面色に重ねる。
///
/// 2 行目に**店の数（売り切れ・終売も含めた合計）と、状態ごとの内訳**を地図と
/// 同じ印で並べる（ユーザーの指定）。**これが凡例を兼ねる**（地図に凡例は
/// 置かない）。[LimitedMenu] の `shops` は売り切れの店も含むので、合計は
/// `shops` ＋ `ended_shops`。
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
    // 内訳。`shops` は売り切れの店も含む。発売前の品は、売り切れていない
    // 取扱店が全部発売前
    final total = menu.shops.length + menu.endedShops.length;
    final ended = menu.endedShops.length;
    final soldOut = menu.soldOutShops.length;
    final start = parseJst(menu.startDate);
    final notYet = start != null && start.isAfter(clock.now());
    final active = menu.shops.length - soldOut;
    final upcoming = notYet ? active : 0;
    final selling = notYet ? 0 : active;
    final radius = BorderRadius.circular(8);

    return Semantics(
      toggled: selected,
      button: true,
      child: Material(
        color: MapPalette.of(colors).panel,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: selected
                ? line.withValues(alpha: 0.6)
                : MapPalette.of(colors).panelBorder,
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
                        const SizedBox(height: 3),
                        // 店の数と内訳（ユーザーの指定。**凡例を兼ねる** ――
                        // 地図と同じ印で状態を名指しする）。文ではなく印と数を
                        // 並べる（括弧・スラッシュで幅を取らない。同）
                        Wrap(
                          spacing: 8,
                          runSpacing: 2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              t.homeLimitedShops(total),
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.2,
                                color: colors.textSub,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            for (final (a, n) in [
                              (LimitedAvailability.selling, selling),
                              if (upcoming > 0)
                                (LimitedAvailability.upcoming, upcoming),
                              (LimitedAvailability.soldOut, soldOut),
                              (LimitedAvailability.ended, ended),
                            ])
                              _Breakdown(
                                availability: a,
                                label: availabilityName(a, t),
                                count: n,
                              ),
                          ],
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

/// 品のチップの内訳 1 つ（印・状態の名前・数）。
class _Breakdown extends StatelessWidget {
  const _Breakdown({
    required this.availability,
    required this.label,
    required this.count,
  });

  final LimitedAvailability availability;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LimitedMark(availability: availability, size: 13),
        const SizedBox(width: 3),
        Text(
          '$label $count',
          style: TextStyle(
            fontSize: 11,
            height: 1.2,
            color: colors.textSub,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
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
