import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:tonsoku/core/i18n/locale_controller.dart';
import 'package:tonsoku/core/theme/app_colors.dart';
import 'package:tonsoku/core/theme/app_theme.dart';
import 'package:tonsoku/features/map/domain/limited_status.dart';
import 'package:tonsoku/features/map/presentation/widgets/shop_marker.dart';

/// 印の凡例。**地図の左下に常に出す**（押して開く形にすると見られない。
/// web の店舗限定の説明を「？」に隠さなかったのと同じ判断）。
///
/// 並べるのは**いま地図にある状態だけ**（[present]）。発売前の品はほとんど
/// 無いので、常に並べると使われない行が 1 つ増える。
class MapLegend extends ConsumerWidget {
  const MapLegend({required this.present, super.key});

  final Set<LimitedAvailability> present;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final t = ref.watch(messagesProvider);
    final entries = <(Widget, String)>[
      for (final a in LimitedAvailability.values)
        if (present.contains(a))
          (
            LimitedMark(availability: a, size: 14),
            switch (a) {
              LimitedAvailability.selling => t.mapSelling,
              LimitedAvailability.upcoming => t.mapUpcoming,
              LimitedAvailability.soldOut => t.mapSoldOut,
              LimitedAvailability.ended => t.homeLimitedEnded,
            },
          ),
      (const ShopMarker(small: true), t.mapLegendShop),
    ];

    return Semantics(
      container: true,
      label: t.mapLegendLabel,
      child: _Plate(
        child: Wrap(
          spacing: 10,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final (mark, label) in entries)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: 14, height: 14, child: Center(child: mark)),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: TextStyle(fontSize: 11, color: colors.text),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// 地図データの帰属表記。**ODbL（OpenStreetMap のライセンス）が地図の上に
/// 見える形で出すことを求めている**ので、隠さない・畳まない。押すと著作権の
/// ページを開く。
class MapAttribution extends StatelessWidget {
  const MapAttribution({super.key});

  static final copyright = Uri.parse('https://www.openstreetmap.org/copyright');

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      link: true,
      child: GestureDetector(
        onTap: () => launchUrl(copyright, mode: LaunchMode.inAppBrowserView),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          color: colors.surface.withValues(alpha: 0.8),
          child: Text(
            // 固有の表記なので訳さない（OpenStreetMap の指定の文言）
            '© OpenStreetMap contributors',
            style: TextStyle(
              fontSize: 10,
              color: colors.textSub,
              // 欧文の表記なので欧文の書体で（日本語の画面でも Klee One にしない）
              fontFamily: AppTheme.defaultFontFamily,
            ),
          ),
        ),
      ),
    );
  }
}

/// 地図の上に浮かせる板（面色・角丸・薄い影）。
class _Plate extends StatelessWidget {
  const _Plate({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: child,
    );
  }
}
