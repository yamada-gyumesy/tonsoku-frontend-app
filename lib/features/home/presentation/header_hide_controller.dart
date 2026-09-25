import 'package:flutter/widgets.dart';

/// ロゴバーの退避量（0 〜 [maxHidden]）を持つ。
///
/// **スクロールの向きと量に 1:1 で追従させる。** `SliverAppBar(floating:)` を
/// `NestedScrollView` に置くと内側の一覧が先端に戻るまで動かず、`snap` を足すと
/// 独自のアニメーションで遅れて出入りする（gyumesy-frontend-app の
/// `GyumesyAppBar` に経緯。そちらからの写し）。
///
/// 判定をここに置いているのは、画面を丸ごと組まないと確かめられない状態を
/// 避けるため。**同じ判定をテスト側に書き写すと、本体を直してもテストは通り続ける。**
class HeaderHideController extends ValueNotifier<double> {
  HeaderHideController({required this.maxHidden}) : super(0);

  /// 退避しきった時の量（ロゴバーの高さ）。
  final double maxHidden;

  /// [NotificationListener] にそのまま渡す。
  bool handleScroll(ScrollUpdateNotification notification) {
    final metrics = notification.metrics;

    // **横スクロールにヘッダーを関与させない。** 横に払う人は店舗限定や
    // クーポンのカードを見たいのであって、ヘッダーを出したいわけではない
    // （gyumesy がタブ列を横に送るたびにヘッダーが飛び出すのを実機で踏んでいる）
    if (metrics.axis == Axis.horizontal) return false;

    // 先端では必ず出しきる（行き過ぎて戻した時に中途半端に残らない）
    if (metrics.pixels <= 0) {
      value = 0;
      return false;
    }

    value = (value + (notification.scrollDelta ?? 0)).clamp(0.0, maxHidden);
    return false;
  }
}
