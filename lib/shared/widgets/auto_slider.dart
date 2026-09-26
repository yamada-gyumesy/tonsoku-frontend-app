import 'dart:async';

import 'package:flutter/material.dart';

/// 一定間隔で送る横並びのスライダー。web の `CmAutoSlider`
/// （gyumesy-frontend-app の `AutoSlider` を写した。色を持たない）。
///
/// **gyumesy と違い、画像ではなくウィジェットを並べる。** 唯一の使い手の
/// 通知の見本を、字を焼き込んだ絵からウィジェットに替えたため
/// （`NotificationSample`。英語・中国語の画面に日本語の絵が出ていた）。
/// 角の丸めと読み上げは並べるもの自身が持つ。
///
/// **端で止まらず巡回する。** web はクローンを前後に足して実現しているが、
/// ここは `PageView` の index を余りで畳んで同じ見え方にする。
///
/// **`visibleCount` は web と同じく画面幅で切り替える**（`md` = 768px 未満は
/// [visibleCountSp]）。端末では常に SP 側になるが、iPad では web の PC 表示と
/// 同じ見え方になる。
class AutoSlider extends StatefulWidget {
  const AutoSlider({
    required this.items,
    required this.aspectRatio,
    this.visibleCount = 1,
    double? visibleCountSp,
    this.gap = 8,
    this.interval = const Duration(seconds: 3),
    super.key,
  }) : visibleCountSp = visibleCountSp ?? visibleCount;

  /// 並べるもの。
  final List<Widget> items;

  /// 1 枚の縦横比。**呼び出し側が渡す。**
  /// web は `w-full` の `img` なので画像自身が高さを決めるが、こちらは
  /// 先に高さを決めないと `PageView` が縦に潰れる。
  final double aspectRatio;

  final double visibleCount;
  final double visibleCountSp;
  final double gap;
  final Duration interval;

  /// web の `md` ブレークポイント。
  static const _md = 768.0;

  /// 送りの尺。web の `duration-500 ease-in-out`。
  static const _slide = Duration(milliseconds: 500);

  @override
  State<AutoSlider> createState() => _AutoSliderState();
}

class _AutoSliderState extends State<AutoSlider> {
  /// **真ん中から始める。** 前へも送れるようにするため（0 始まりだと
  /// 左へ送れない）。
  static const _origin = 10000;

  PageController? _controller;
  Timer? _timer;
  double? _fraction;

  /// 自分で送っている最中か。**`onPageChanged` は指で送っても自動で送っても
  /// 同じように呼ばれる**ので、これが無いと自動送りのたびに間隔を取り直して
  /// しまい、実際の間隔が `interval` + 送りの尺になる。
  bool _advancing = false;

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  void _restartTimer() {
    _timer?.cancel();
    if (widget.items.length <= 1) return;
    _timer = Timer.periodic(widget.interval, (_) async {
      final controller = _controller;
      if (controller == null || !controller.hasClients) return;
      _advancing = true;
      try {
        await controller.nextPage(
          duration: AutoSlider._slide,
          curve: Curves.easeInOut,
        );
      } finally {
        _advancing = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // **動きを減らす設定では送らない。** 勝手に動き続ける UI は
    // この設定が最も効いてほしいもの
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final active = width < AutoSlider._md
            ? widget.visibleCountSp
            : widget.visibleCount;
        // web の `measure()` と同じ式
        final itemWidth = (width - (active - 1) * widget.gap) / active;
        final step = itemWidth + widget.gap;
        final fraction = (step / width).clamp(0.01, 1.0);

        // 幅が変わったら作り直す。`viewportFraction` は後から変えられない
        if (_fraction != fraction) {
          _fraction = fraction;
          // **このフレームの描画が終わってから捨てる。** build の途中で捨てると
          // まだ `PageView` に繋がっている状態で使われて落ちる
          final old = _controller;
          if (old != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
          }
          _controller = PageController(
            initialPage: _origin,
            viewportFraction: fraction,
          );
          if (!reduceMotion) {
            // build 中に Timer を作らない（初回フレームの前に発火しうる）
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _restartTimer(),
            );
          }
        }
        if (reduceMotion) _timer?.cancel();

        return SizedBox(
          // **1 枚ぶんの幅から高さを決める。** 並ぶ枚数と隙間で見え方の幅は
          // 変わるが、1 枚そのものの比率は変わらない
          height: itemWidth / widget.aspectRatio,
          child: PageView.builder(
            controller: _controller,
            // **指で送った時だけ間隔を取り直す**（web の `resetTimer`）
            onPageChanged: (_) {
              if (!reduceMotion && !_advancing) _restartTimer();
            },
            itemBuilder: (context, index) {
              final i = index % widget.items.length;
              return Padding(
                // **右にだけ空ける。** 先頭を左端に揃えたいので
                // 左右均等にしない（web の `gap` と同じ位置関係）
                padding: EdgeInsets.only(right: widget.gap),
                child: widget.items[i],
              );
            },
          ),
        );
      },
    );
  }
}
