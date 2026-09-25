import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tonsoku/core/i18n/locale_controller.dart';
import 'package:tonsoku/core/theme/app_colors.dart';
import 'package:tonsoku/shared/models/ranking.dart';

/// 順位バッジ。
///
/// **上位はとん速の赤（`primary` の塗り）、4 位以下は黒の透過**（web の `rankBadgeColorClass`）。
/// 4 位以下に色を持たせないのは、上位の赤だけが色として立ち、順位の格の差が
/// 一目で付くようにするため。無彩色なのでサムネイルの色味とも喧嘩しない。
///
/// **数字だけでは順位だと分からない**ので、読み上げには「3位」を渡す。
class RankBadge extends ConsumerWidget {
  const RankBadge({required this.rank, this.small = false, super.key});

  final int rank;

  /// 4 位以下のカードで使う小さいほう。**上位のカードより必ず小さくする**
  /// （同じ大きさだと画像の差だけで順位の重みを表すことになる）。
  final bool small;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(messagesProvider);
    final colors = context.colors;
    // web の上位カード `min-w-9 h-9 px-2 rounded-lg`（36）と、
    // 一覧カード `min-w-6 h-6 px-1.5 rounded-md`（24）
    final size = small ? 24.0 : 36.0;

    return Semantics(
      label: t.rankingRank(rank),
      image: true,
      excludeSemantics: true,
      child: Container(
        constraints: BoxConstraints(minWidth: size),
        height: size,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: small ? 6 : 8),
        decoration: BoxDecoration(
          // web の `rankBadgeColorClass`: 上位は `bg-brand-primary/90`、
          // それ以外は `bg-black/60`。**塗りの `primary` で正しい**（上に白い
          // 数字を載せる塗り。地の上に直接置く赤ではない）
          color: rank <= rankingTopRank
              ? colors.primary.withValues(alpha: 0.9)
              : Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(small ? 6 : 8),
        ),
        child: Text(
          '$rank',
          style: TextStyle(
            // web の `text-xs` / `text-base`
            fontSize: small ? 12 : 16,
            height: 1,
            fontWeight: FontWeight.bold,
            color: colors.onPrimary,
            // 桁が増えても数字が踊らない
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}
