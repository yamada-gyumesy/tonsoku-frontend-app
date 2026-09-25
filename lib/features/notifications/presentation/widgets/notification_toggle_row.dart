import 'package:flutter/material.dart';

import 'package:tonsoku/core/theme/app_colors.dart';
import 'package:tonsoku/shared/widgets/brand_toggle.dart';

/// トグル 1 行。
///
/// **web の `CoToggleRow` とは別物にした。** web は 1 行ずつ枠で囲むが、
/// アプリの一覧はメニュー（`MenuListRow`）と同じ**罫線区切りの素の行**で
/// 揃える。囲みを重ねると、行数ぶんの角丸と枠線が並んで一覧が読みにくい。
///
/// **通知全体の行とカテゴリの行は、間の余白で分ける。** 地色や太字で差を
/// つけると、そこだけ無効に見える。
///
/// **行全体を押せる。** web はトグル本体しか押せないが、指で触る前提では
/// 的が小さすぎる。
class NotificationToggleRow extends StatelessWidget {
  const NotificationToggleRow({
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String label;

  /// 配信データ側の説明。**無い場合がある**ので空なら行ごと出さない。
  final String description;
  final bool value;

  /// **`null` なら触らせない。** 通知全体が切れている間のカテゴリ行がこれ。
  /// **値は残したまま**にする —— オフにしてしまうと、入れ直した時に前の選択が
  /// 消える。薄く見せるのは呼び出し側（まとめて 1 枚で薄くする）。
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      // **入り切りの状態と、触れるかどうかを読み上げに渡す。**
      // `Switch` をやめたので、これが無いと「ボタン」としか読まれない
      toggled: value,
      enabled: onChanged != null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onChanged == null ? null : () => onChanged!(!value),
          child: Padding(
            // **縦を web（`p-3` = 12）より広げる。** 枠が無くなったぶん、
            // 行の高さそのものが区切りを担う
            // **左右は本文と同じ 16。** 端まで伸びるのは罫線だけで、
            // 中身まで引っ張られると読みにくく、トグルが画面の縁に当たる
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        // web の `text-[0.9375rem] font-medium`
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: colors.text,
                        ),
                      ),
                      if (description.isNotEmpty)
                        Padding(
                          // web の `mt-0.5`
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            description,
                            // web の `text-[0.8125rem]`
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.textSub,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // web の `mr-3`
                const SizedBox(width: 12),
                BrandToggle(value: value),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// まとまりの見出し。**行より小さく、副テキスト色で置く。**
/// 行そのものと同じ濃さで書くと、見出しが 1 行目に見える。
class NotificationSectionLabel extends StatelessWidget {
  const NotificationSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: context.colors.textSub,
      ),
    ),
  );
}

/// 行をまとめる。**罫線で区切るだけで囲まない。**
///
/// **上下どちらにも線を引く**（メニューと同じ）。片方だけだと、まとまりの
/// 始まりか終わりのどちらかが宙に浮いて見える。
class NotificationRowGroup extends StatelessWidget {
  const NotificationRowGroup({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final line = Divider(height: 1, thickness: 1, color: colors.border);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        line,
        for (final child in children) ...[child, line],
      ],
    );
  }
}
