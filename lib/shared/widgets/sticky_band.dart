import 'package:flutter/material.dart';

import 'package:tonsoku/core/theme/app_colors.dart';

/// ヘッダー直下に隙間なく貼り付く帯。web の `.sticky-band`（`main.css`）。
///
/// 記事一覧の絞り込みと、ランキングの期間タブが使う（web も同じ帯を共有している）。
///
/// - 地は面色。**枠・角丸・影は付けない**（gyumesy の浮いたカードとは違う。
///   web のユーザー指定）
/// - **貼り付いた時だけ下に区切り線を 1 本出す。** 線は紙面の端から端まで
///   （[stuck] は置く側が番兵で判定して渡す）
///
/// **高さは測ってから貼る**（gyumesy の `MeasuredStickyToolbar` と同じ作り）。
/// 中身の段数や端末の文字サイズで変わるので、決め打ちにできない。
class StickyBand extends StatefulWidget {
  const StickyBand({required this.stuck, required this.child, super.key});

  /// 貼り付いたか。
  final ValueNotifier<bool> stuck;

  final Widget child;

  @override
  State<StickyBand> createState() => _StickyBandState();
}

class _StickyBandState extends State<StickyBand> {
  final _key = GlobalKey();
  double? _height;

  void _measure() {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || _height == box.size.height) return;
    if (mounted) setState(() => _height = box.size.height);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    final colors = context.colors;

    return SliverPersistentHeader(
      pinned: true,
      delegate: _BandDelegate(
        stuck: widget.stuck,
        surface: colors.surface,
        border: colors.border,
        // 測れるまでは 1px で置き、次のフレームで確定させる
        height: _height ?? 1,
        // **中身は常にこの 1 か所に置く**（測る前後で置き場所を変えると
        // `GlobalKey` が同じフレームで 2 か所に現れて中身ごと消える。gyumesy）
        child: KeyedSubtree(key: _key, child: widget.child),
      ),
    );
  }
}

class _BandDelegate extends SliverPersistentHeaderDelegate {
  _BandDelegate({
    required this.stuck,
    required this.surface,
    required this.border,
    required this.height,
    required this.child,
  });

  final ValueNotifier<bool> stuck;
  final Color surface;
  final Color border;
  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => ValueListenableBuilder<bool>(
    valueListenable: stuck,
    builder: (context, isStuck, child) => DecoratedBox(
      decoration: BoxDecoration(
        color: surface,
        // **線は外側に描く**（web は `box-shadow: 0 1px 0`。`border` だと帯の
        // 高さが 1px 変わり、貼り付く瞬間に下が跳ねる）
        boxShadow: isStuck
            ? [BoxShadow(color: border, offset: const Offset(0, 1))]
            : null,
      ),
      child: child,
    ),
    child: OverflowBox(
      alignment: Alignment.topCenter,
      maxHeight: double.infinity,
      child: child,
    ),
  );

  @override
  bool shouldRebuild(_BandDelegate oldDelegate) =>
      oldDelegate.height != height ||
      oldDelegate.surface != surface ||
      oldDelegate.border != border ||
      oldDelegate.stuck != stuck ||
      // **中身も比べる**（比べないと貼り付いた側が古い選択のまま残る。
      // gyumesy の `StickyToolbar` が実機で踏んでいる）
      oldDelegate.child != child;
}
