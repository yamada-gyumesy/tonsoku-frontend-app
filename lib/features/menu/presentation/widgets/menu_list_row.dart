import 'package:flutter/material.dart';

import 'package:tonsoku/core/theme/app_colors.dart';
import 'package:tonsoku/shared/widgets/optical_center.dart';

/// メニューの 1 行。web の `CmListRow` と同じ 3 通りの出し分け。
///
/// - `onTap` あり → 押せる行（右に「>」）
/// - `trailing` あり → 右に部品を置くだけの行（トグル等。行自体は押せない）
/// - `value` は現在値（言語名など）。「>」とはくっつけない（詰まっていると
///   1 つの塊に見える）
///
/// **高さは最小値で持たせる。** 固定にすると端末の文字サイズ設定を上げた時に
/// ラベルが行からはみ出して切れる。
class MenuListRow extends StatelessWidget {
  const MenuListRow({
    required this.label,
    this.icon,
    this.onTap,
    this.value,
    this.trailing,
    this.bold = false,
    this.external = false,
    bool? chevron,
    super.key,
  }) : chevron = chevron ?? (onTap != null && trailing == null);

  /// web の `min-h-14`。
  static const minHeight = 56.0;

  final String label;

  /// 行頭のアイコン。**言語の選択肢には付けない**（web も付けていない。
  /// 3 行とも同じ記号が並ぶだけで、どれを選ぶかの手がかりにならない）。
  final IconData? icon;
  final VoidCallback? onTap;
  final String? value;

  /// 選択中の項目を太字にする（web の言語一覧と同じ）。
  final bool bold;

  /// 右端に「>」を出すか。既定は「押せて、右に部品が無い行」。
  final bool chevron;

  /// アプリの外（web）へ出る行か。**ラベルの直後に外部リンクの記号を添える。**
  /// 「>」だけだと、アプリ内で階層が深くなるのか web へ出るのかが区別できない。
  ///
  /// **「>」は置き換えない。** 押せる行であることは「>」が示していて、外へ出る
  /// かどうかはそれとは別の情報なので、同じ場所で兼ねさせない。
  final bool external;

  /// 行の右に置く部品。押せる行と同時には使わない。
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final value = this.value;

    final content = Padding(
      // 上下の余白は、中身（外観モードの切り替え 36px）を入れても最小高さを
      // 超えない値にする。超えるとその行だけ背が高くなって浮いて見える
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: colors.textSub),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Row(
              // **記号の縦位置を文字の中央に合わせる。** 既定（`center`）でも
              // 行の高さは文字の行送りで決まるので、記号が上に浮いて見える
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  // **字面を器の中央に寄せる**（web も `CmListRow` の
                  // `labelClass` に `optical-center` を当てている）。アイコンと
                  // 横に並べると文字だけ沈んで見えるので、**アイコンを動かす
                  // のではなく文字を上げる**（[OpticalCenter]）
                  child: OpticalCenter(
                    fontSize: 15,
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        color: colors.text,
                        fontWeight: bold ? FontWeight.bold : null,
                      ),
                    ),
                  ),
                ),
                if (external) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.open_in_new,
                    size: 13,
                    color: colors.textSub.withValues(alpha: 0.6),
                  ),
                ],
              ],
            ),
          ),
          if (value != null) ...[
            // 値の側も同じ（web の `valueClass` も `optical-center`）
            OpticalCenter(
              fontSize: 13,
              child: Text(
                value,
                style: TextStyle(fontSize: 13, color: colors.textSub),
              ),
            ),
            const SizedBox(width: 8),
          ],
          ?trailing,
          if (chevron)
            Icon(
              Icons.chevron_right,
              size: 20,
              color: colors.textSub.withValues(alpha: 0.6),
            ),
        ],
      ),
    );

    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: minHeight),
      child: content,
    );

    if (onTap == null) return row;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        // 押した時の手応えは web と同じく地色（`brand-bg`）で出す
        highlightColor: colors.bg,
        splashColor: colors.bg,
        child: row,
      ),
    );
  }
}
