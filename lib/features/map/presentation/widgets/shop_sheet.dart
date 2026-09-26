import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:tonsoku/core/i18n/locale_controller.dart';
import 'package:tonsoku/core/theme/app_colors.dart';
import 'package:tonsoku/features/map/domain/google_maps.dart';
import 'package:tonsoku/features/map/domain/limited_status.dart';
import 'package:tonsoku/features/map/domain/map_format.dart';
import 'package:tonsoku/features/map/domain/shop_filter.dart';
import 'package:tonsoku/features/map/domain/shop_state.dart';
import 'package:tonsoku/features/map/presentation/widgets/shop_marker.dart';
import 'package:tonsoku/shared/models/shop.dart';
import 'package:tonsoku/shared/widgets/cdn_image.dart';

/// 店の詳細（印を押すと下から出る）。
///
/// **牛めしレーダーの `ShopDetailOverlay` より情報を増やしてある**（Issue #8 の
/// ユーザーの指定）: 住所・営業時間・電話・一時閉店・Google マップ。
///
/// 並びは「どこの店か → いま入れるか → 店舗限定 → 行き方」。**店舗限定を
/// 住所より上に置く** ―― マップを開く人の目的は「その品をどこで食べられるか」で、
/// 住所は Google マップへ渡せば済む。
class ShopSheet extends ConsumerWidget {
  const ShopSheet({
    required this.shop,
    required this.state,
    required this.limited,
    required this.onOpenArticle,
    super.key,
  });

  final Shop shop;

  /// 店の状態（開く時点で求めたもの。`shopStateOf`）。
  final ShopState state;

  /// この店の品と状態（`ShopFilter.relevant` を通す前の全部）。**絞り込みに
  /// 関係なく全部出す** ―― 印は選んだ品だけで決めるが、詳細を開いた人には
  /// その店で食べられるものを全部見せたほうが役に立つ。
  final List<ShopLimited> limited;

  final ValueChanged<String> onOpenArticle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final t = ref.watch(messagesProvider);
    final notice = shopNotice(state, t);
    final brands = [
      for (final b in ShopBrand.values)
        if (shop.brands.contains(b.key)) b,
    ];
    // **強い順に並べる**（販売中が先。配信の並びのままだと終売が先頭に来ることがある）
    final items = [...limited]
      ..sort((a, b) => a.availability.index.compareTo(b.availability.index));

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 名前が無い店（英語・中国語で訳もローマ字名も無い）は欄ごと描かない
            if (shopLabel(shop) case final name?)
              Text(
                name,
                style: TextStyle(
                  fontSize: 18,
                  height: 1.4,
                  fontWeight: FontWeight.bold,
                  color: colors.text,
                ),
              ),
            if (brands.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (final b in brands) _Badge(label: brandLabel(b, t)),
                ],
              ),
            ],
            if (notice != null) ...[
              const SizedBox(height: 12),
              _Notice(text: notice),
            ],
            if (items.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                t.homeLimitedHeading,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: colors.textSub,
                ),
              ),
              const SizedBox(height: 6),
              for (final item in items)
                _LimitedRow(
                  item: item,
                  onTap: switch (item.menu.articleSlug) {
                    final slug? => () => onOpenArticle(slug),
                    null => null,
                  },
                ),
            ],
            const SizedBox(height: 12),
            Divider(height: 1, color: colors.border),
            if (shop.address case final address?)
              _InfoRow(
                icon: Icons.place_outlined,
                label: t.mapAddress,
                value: address,
              ),
            if (shop.businessHours case final hours?)
              _InfoRow(
                icon: Icons.schedule_outlined,
                label: t.mapHours,
                // **Navitime の表記をそのまま出す**（形が決まっていない。`Shop`）
                value: hours,
              ),
            if (shop.phone case final phone?)
              _InfoRow(
                icon: Icons.call_outlined,
                label: t.mapPhone,
                value: phone,
                semanticsLabel: t.mapCall(phone),
                // 電話アプリへ渡す。**番号の区切り（-）は付けたまま渡してよい**
                // （`tel:` は区切りを読み飛ばす）
                onTap: () => launchUrl(Uri(scheme: 'tel', path: phone)),
              ),
            const SizedBox(height: 12),
            _GoogleMapsButton(
              label: t.mapOpenInGoogleMaps,
              onTap: () => launchUrl(
                googleMapsUri(shop),
                // **Google マップのアプリへ渡す**（入っていなければブラウザ）。
                // アプリ内のブラウザで開くと、経路案内に進めない
                mode: LaunchMode.externalApplication,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // タグのチップと同じ中立の地（`LabelChip.tag`）。併設は色を持たない
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.chipNeutral,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          height: 1.5,
          fontWeight: FontWeight.w500,
          color: colors.textSub,
        ),
      ),
    );
  }
}

/// 一時閉店・開店前などの一文。**淡い赤の面（ひとことの箱と同じ `primarySoft`）
/// に主テキスト**で出す。赤い文字にしない（警告ではなく状態なので）。
class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.primarySoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, height: 1.5, color: colors.text),
      ),
    );
  }
}

/// 店舗限定の 1 行（写真・品名・状態）。記事があれば押すと記事へ。
class _LimitedRow extends ConsumerWidget {
  const _LimitedRow({required this.item, required this.onTap});

  final ShopLimited item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final t = ref.watch(messagesProvider);
    final image = item.menu.imageUrl ?? item.menu.thumbnailUrl ?? '';
    final label = availabilityLabel(item, t);
    final a = item.availability;
    // **販売中だけ赤で出す**（地の上の赤なので `primaryText`）。それ以外は
    // 副テキスト —— 印と同じ強弱にそろえる
    final labelColor = a == LimitedAvailability.selling
        ? colors.primaryText
        : colors.textSub;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Opacity(
                // 終売は写真も沈める（印と同じ）
                opacity: a.isActive ? 1 : 0.55,
                child: CdnImage(url: image, width: 56, height: 42),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    // 品名が null の品は届かない（`MapRepository.isShown`）
                    item.menu.name ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.bold,
                      color: colors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      LimitedMark(availability: a, size: 16),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            color: labelColor,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right, size: 20, color: colors.textSub),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.semanticsLabel,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? semanticsLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colors.textSub),
          const SizedBox(width: 10),
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: colors.textSub,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                // 押せる行（電話）は地の上の赤で示す
                color: onTap == null ? colors.text : colors.primaryText,
              ),
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return row;
    return Semantics(
      button: true,
      label: semanticsLabel,
      excludeSemantics: semanticsLabel != null,
      child: InkWell(onTap: onTap, child: row),
    );
  }
}

/// 「Google マップで開く」。**ホームの「過去の記事を見る」と同じ形**
/// （面色の丸いボタンに罫線）。
class _GoogleMapsButton extends StatelessWidget {
  const _GoogleMapsButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      shape: StadiumBorder(side: BorderSide(color: colors.border)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        highlightColor: colors.hover,
        splashColor: colors.hover,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 下タブのマップと同じアイコン（ユーザーの指定）
              Icon(Icons.location_on_outlined, size: 18, color: colors.text),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
