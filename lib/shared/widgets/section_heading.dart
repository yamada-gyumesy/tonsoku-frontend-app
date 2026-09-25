import 'package:flutter/material.dart';

import 'package:tonsoku/core/theme/app_colors.dart';

/// 節の見出し。**他のページの節見出しと同じ形**（web の
/// `text-[1.25rem] font-bold pb-2 border-b-2 border-brand-primary-text`）。
///
/// 下線は構造を示す境界なので、**地の上に置く赤（`primaryText`）**を使う
/// （塗りの `primary` はダークで 3:1 に届かない）。
///
/// [lead] は見出しの横に並べる説明（web の店舗限定の節）。**ベースライン揃えで
/// 字の足をそろえる**（web の `items-baseline`）。
class SectionHeading extends StatelessWidget {
  const SectionHeading({
    required this.label,
    this.lead,
    this.trailing,
    super.key,
  });

  final String label;
  final String? lead;

  /// 右端に置く導線（web の「クーポン一覧 >」）。
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final lead = this.lead;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.primaryText, width: 2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Semantics(
            header: true,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 20,
                height: 1.4,
                fontWeight: FontWeight.bold,
                color: colors.text,
              ),
            ),
          ),
          if (lead != null) ...[
            // web の `gap-3`
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                lead,
                style: TextStyle(fontSize: 12, color: colors.textSub),
              ),
            ),
          ],
          if (trailing != null) ...[const Spacer(), trailing!],
        ],
      ),
    );
  }
}
