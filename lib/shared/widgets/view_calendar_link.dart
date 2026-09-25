import 'package:flutter/material.dart';

import 'package:tonsoku/core/theme/app_colors.dart';
import 'package:tonsoku/shared/widgets/optical_center.dart';

/// 「カレンダーをみる」の導線。web の `coupon.astro` のスケジュールの見出しに
/// 置いてある形（アイコン 16px ＋ 下線つきの文字 ＋ 山形）。gyumesy-frontend-app の
/// `ViewCalendarLink` を写した。
///
/// **共有部品に置く。** web は同じ形をホームの「最近の予定」
/// （`CoCalendarSection`）にも持っていて、アプリにその節を入れる時にもう 1 つ
/// 生やさずに済ませる（gyumesy がホームとクーポンで共用している理由と同じ）。
///
/// ## gyumesy との違い
///
/// - **小さい版（`prominent: false`）を持たない**（使うのはクーポンの見出しと
///   記事詳細の「この記事の前後の予定」で、どちらも大きい版。ホームの節を
///   入れる時に web の `CoCalendarSection` の寸法で足すこと）
/// - **山形は web と同じ `arrow_back_ios` の向きを返したもの**（10px。gyumesy は
///   `chevron_right`）
class ViewCalendarLink extends StatelessWidget {
  const ViewCalendarLink({required this.label, required this.onTap, super.key});

  final String label;
  final VoidCallback onTap;

  /// web の `text-sm`。
  static const fontSize = 14.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      link: true,
      child: GestureDetector(
        onTap: onTap,
        // 文字の隙間でも押せるように（web もリンク全体が当たる）
        behavior: HitTestBehavior.opaque,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // web の `calendar_month`（`text-[16px]`）
            Icon(Icons.calendar_month, size: 16, color: colors.textSub),
            // web の `gap-1`
            const SizedBox(width: 4),
            OpticalCenter(
              fontSize: fontSize,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  color: colors.textSub,
                  decoration: TextDecoration.underline,
                  decorationColor: colors.textSub,
                ),
              ),
            ),
            const SizedBox(width: 4),
            // web の `arrow_back_ios` を `rotate-180`（`text-[10px]`）
            Icon(Icons.arrow_forward_ios, size: 10, color: colors.textSub),
          ],
        ),
      ),
    );
  }
}
