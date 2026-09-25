import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tonsoku/core/i18n/locale_controller.dart';
import 'package:tonsoku/core/theme/app_colors.dart';

/// ロゴのヘッダー。web の `CoHeader` を移したもの。
///
/// - 地は生成り（`bg`）、下に罫 1 本（web の `bg-brand-bg border-b`）
/// - ロゴ 32px ＋ サイト名 ＋ 縦罫 ＋ タグライン（`とん速 | 松のや速報`）
/// - **SP のヘッダーには操作を置かない**（移動もテーマ・言語も下タブに集約。web と同じ）
///
/// **スクロールに 1:1 で追従して退避する**（gyumesy-frontend-app の
/// `GyumesyAppBar` と同じ作り。`SliverAppBar(floating:)` を使わない理由はあちらに
/// ある）。退避量は [hidden] で受け取り、動かすのは一覧側が持つ。
class TonsokuAppBar extends ConsumerWidget {
  const TonsokuAppBar({required this.hidden, super.key});

  /// ロゴバーを何 px 退避させているか（0 〜 [height]）。
  final double hidden;

  /// web の `--spacing-header`（3.5rem）。
  static const height = 56.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final t = ref.watch(messagesProvider);
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
            // ステータスバーの下は常に地色で埋める（ロゴバーが退避しても透けない）
            SizedBox(height: statusBar),
            // **上へスライドしながら消える。** 高さを縮めつつ中身を下端に
            // 貼り付けることで、切り取られるのではなく動いて見える
            SizedBox(
              height: (height - hidden).clamp(0.0, height),
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.bottomCenter,
                  minHeight: height,
                  maxHeight: height,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        // **SVG を使う。** 元の PNG は背景が白で、紙面の上に
                        // 白い四角が出る（web と同じ）
                        SvgPicture.asset(
                          'assets/brand/logo.svg',
                          width: 32,
                          height: 32,
                        ),
                        const SizedBox(width: 8),
                        // サイト名と説明を**1 行に続ける**。間は縦罫で仕切る
                        // （空白だけだと 1 つの語に見える。web と同じ）
                        Text(
                          t.appName,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1,
                            letterSpacing: 16 * 0.08,
                            fontWeight: FontWeight.bold,
                            color: colors.text,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(width: 1, height: 14, color: colors.border),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            t.tagline,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1,
                              color: colors.textSub,
                            ),
                          ),
                        ),
                      ],
                    ),
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
