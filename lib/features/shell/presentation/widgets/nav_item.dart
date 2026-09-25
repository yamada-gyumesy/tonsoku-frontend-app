import 'package:flutter/material.dart';

import 'package:tonsoku/core/theme/app_colors.dart';

/// グローバルナビの 1 タブ。
///
/// **`AppShell` から出して公開している。** private のままだと、読み上げの挙動を
/// 「同じ組み方を再現したテスト」でしか確かめられず、実物を変えてもテストが
/// 通り続ける（実際にこの PR で 3 回同じ形の取りこぼしをした）。
class NavItem extends StatelessWidget {
  const NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // **`NavigationBar` をやめた分、読み上げは自前で張る。**
    // ラベルだけでは「ボタンであること」も「どれが選択中か」も伝わらない
    // （web も `aria-current="page"` を持っている）。10px のラベルの
    // コントラストを上げるところまで気を配っているので、ここも落とさない。
    //
    // **`excludeSemantics: true` を使わないこと。** 子孫の semantics を丸ごと
    // 捨てるので、`GestureDetector` が登録している `SemanticsAction.tap` まで
    // 消える。読み上げでは「ホーム、選択中、ボタン」と正しく読まれるのに
    // ダブルタップで何も起きず、**読み上げ利用者はタブを移動できなくなる**。
    // 1 ノードにまとめるのは `MergeSemantics` の役目。
    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: isActive,
        inMutuallyExclusiveGroup: true,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 22,
                // **現在地は `primaryText`。塗りの `primary` を使わない**
                // （ダークで面に対して 3:1 に届かない。web がここで踏んでいる）
                color: isActive ? colors.primaryText : colors.textSub,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  height: 1,
                  fontWeight: isActive ? FontWeight.bold : null,
                  // 文字もアイコンと同じ `primaryText`（地に対して
                  // ライト 6.74:1 / ダーク 5.70:1）
                  color: isActive ? colors.primaryText : colors.textSub,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
