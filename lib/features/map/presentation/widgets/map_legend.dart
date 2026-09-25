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
///
/// - 販売中の印は**「店舗限定」**と書く（ユーザーの判断。この印が何の印かを言う）
/// - **普通の店の点は並べない**（ユーザーの判断。見れば店だと分かる）
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
              LimitedAvailability.selling => t.homeLimitedHeading,
              LimitedAvailability.upcoming => t.mapUpcoming,
              LimitedAvailability.soldOut => t.mapSoldOut,
              LimitedAvailability.ended => t.homeLimitedEnded,
            },
          ),
    ];
    // 店舗限定の印が 1 つも無い（絞り込みで消えた・品が無い週）なら板ごと出さない
    if (entries.isEmpty) return const SizedBox.shrink();

    return Semantics(
      container: true,
      label: t.mapLegendLabel,
      child: _Plate(
        // 並びは 1 行（状態は多くて 3 つ）。折り返さないので Wrap にしない
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (i, (mark, label)) in entries.indexed) ...[
              if (i > 0) const SizedBox(width: 8),
              SizedBox(width: 14, height: 14, child: Center(child: mark)),
              const SizedBox(width: 4),
              Text(
                label,
                softWrap: false,
                style: TextStyle(fontSize: 11, color: colors.text),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 地図データの帰属表記。**右下に常に出す「© OpenStreetMap」**（ユーザーの判断）。
/// 押すと著作権のページを開く。
///
/// - **「contributors」は付けない**（ユーザーの判断）。OpenStreetMap 財団の
///   帰属表示の指針（https://osmfoundation.org/wiki/Licence/Attribution_Guidelines ）
///   は「© OpenStreetMap」を著作権のページへつないで出す形を認めている
/// - 地図を塞がないよう、地は薄く（面色の 55%）
/// - メニューのライセンス一覧にも載せてある（`registerMapDataLicense`）
class MapAttribution extends StatelessWidget {
  const MapAttribution({super.key});

  static final copyright = Uri.parse('https://www.openstreetmap.org/copyright');

  /// 固有の表記なので訳さない。
  static const text = '© OpenStreetMap';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      link: true,
      child: GestureDetector(
        onTap: () => launchUrl(copyright, mode: LaunchMode.inAppBrowserView),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            text,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: child,
    );
  }
}
