import 'package:flutter/material.dart';

import 'package:tonsoku/core/theme/app_colors.dart';

/// 記事一覧の読み込み中に出す骨組み。web の `CoArticleCardSkeleton` と同じ形。
///
/// **`ArticleCard` と同じ寸法で置くこと。** 骨組みと実物で高さが違うと、
/// 読み込みが終わった瞬間に一覧が飛ぶ。
class ArticleCardSkeleton extends StatefulWidget {
  const ArticleCardSkeleton({this.count = 5, super.key});

  /// 記事カード 1 行ぶんの高さ。**`ArticleCard` と一致させること。**
  /// 上下 padding 16 + 中身 96 + 下罫線 1（web の `py-4` に合わせた値）。
  ///
  /// アクティブ復帰の取り直しでは一覧を同じ件数の骨組みに差し替えるので、
  /// ここがずれると `maxScrollExtent` が変わってスクロール位置を失う。
  static const rowHeight = 129.0;

  final int count;

  @override
  State<ArticleCardSkeleton> createState() => _ArticleCardSkeletonState();
}

class _ArticleCardSkeletonState extends State<ArticleCardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return FadeTransition(
      // web の animate-pulse に相当。**明滅させすぎない**——一覧全体が
      // 点滅すると、読み込み中であること以上に落ち着かなさが目立つ
      opacity: Tween<double>(
        begin: 1,
        end: 0.4,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: Column(
        // 中身ぶんの高さに留める（重ねて出す時に器へ引き伸ばされないように）
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          widget.count,
          (_) => _SkeletonRow(colors: colors),
        ),
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow({required this.colors});

  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final block = colors.border.withValues(alpha: 0.7);
    Widget bar(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: block,
        borderRadius: BorderRadius.circular(4),
      ),
    );

    // **罫は左右の余白の内側に引く**（`ArticleCard` と同じ組み。web の
    // `CoArticleCard` は余白をリンクが持ち、線を内側の箱が持つ）
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.border)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            bar(128, 96),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 96,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // タイトル 2 行ぶん（web の骨組みも 2 本）
                    bar(double.infinity, 20),
                    const SizedBox(height: 8),
                    FractionallySizedBox(
                      widthFactor: 0.75,
                      child: bar(double.infinity, 20),
                    ),
                    const Spacer(),
                    // 日付と分類。実物のチップと同じ高さ（16px）にする
                    Row(
                      children: [
                        bar(48, 16),
                        const SizedBox(width: 6),
                        bar(56, 16),
                        const SizedBox(width: 6),
                        bar(48, 16),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
