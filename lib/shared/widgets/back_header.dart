import 'package:flutter/material.dart';

import 'package:tonsoku/core/theme/app_colors.dart';
import 'package:tonsoku/shared/widgets/back_leading.dart';

/// 積んだ画面のヘッダー。**「＜ 戻る」だけ**を置く（web の `CoHeader` が
/// ロゴを「＜ 戻る」に差し替えるのと同じ）。
///
/// - 地は生成り（`bg`）、下に罫 1 本（ホームのヘッダーと同じ面）
/// - **題は出さない**（題は本文の見出しが担う。gyumesy と同じ）
///
/// **[hidden] ぶん上へ退く**（記事詳細はスクロールに追随して退く。web と同じ）。
/// 状態バーの下は常に地色で埋め、下の行だけを縮める（gyumesy の記事ヘッダーと
/// 同じ作り。`AppBar` を丸ごとずらすと状態バーの帯ごと動く）。
class BackHeader extends StatelessWidget {
  const BackHeader({required this.onBack, this.hidden = 0, super.key});

  final VoidCallback onBack;

  /// 何 px 退避させているか（0 〜 [height]）。
  final double hidden;

  /// web の `--spacing-header`（3.5rem）。
  static const height = 56.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final statusBar = MediaQuery.paddingOf(context).top;

    return Material(
      color: colors.bg,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: statusBar),
            SizedBox(
              height: (height - hidden).clamp(0.0, height),
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.bottomLeft,
                  minHeight: height,
                  maxHeight: height,
                  child: SizedBox(
                    width: BackLeading.width,
                    child: BackLeading(onPressed: onBack),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
