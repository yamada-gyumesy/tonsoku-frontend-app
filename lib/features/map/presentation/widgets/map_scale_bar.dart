import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:tonsoku/core/theme/app_colors.dart';
import 'package:tonsoku/core/theme/app_theme.dart';

/// 縮尺のメーター（左下、凡例の横）。**棒を真ん中の目盛りで 2 つに割り、棒の
/// 右端にその長さの距離を書く**（ユーザーの指定）。`flutter_map` の `Scalebar` は
/// 距離を棒の上の中央に書くので、「500 m」が棒全体なのか 1 目盛りなのか分から
/// なかった（ユーザーの指摘。短すぎるとも言われた）。
///
/// - 棒の長さは [maxWidth] 以下で一番長くなる**切りのよい距離**（1・2・5 × 10ⁿ）
/// - 距離は 1000 m 未満なら m、以上なら km
/// - 地図の模様に紛れないよう、線の下に面色の縁を敷く
///
/// **FlutterMap の子として置く**（`MapCamera.of` で倍率が変わるたびに組み直す）。
class MapScaleBar extends StatelessWidget {
  const MapScaleBar({super.key});

  /// 棒の長さの上限（pt）。
  /// **凡例と右下の著作権表記の間に収める**（長いと「© OpenStreetMap」に重なる）。
  static const maxWidth = 110.0;

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    final colors = context.colors;
    final perPoint = metersPerPoint(camera.center.latitude, camera.zoom);
    final meters = niceDistance(perPoint * maxWidth);
    final width = meters / perPoint;
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CustomPaint(
            size: Size(width, 8),
            painter: _BarPainter(ink: colors.text, halo: colors.surface),
          ),
          const SizedBox(width: 4),
          // 距離は棒の右端に（ユーザーの指定。棒の終わりがその距離だと読める）
          Text(
            formatDistance(meters),
            style: TextStyle(
              fontSize: 11,
              height: 1,
              fontWeight: FontWeight.w700,
              color: colors.text,
              fontFamily: AppTheme.defaultFontFamily,
              shadows: [
                for (final o in const [
                  Offset(1, 0),
                  Offset(-1, 0),
                  Offset(0, 1),
                  Offset(0, -1),
                ])
                  Shadow(color: colors.surface, offset: o),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 地図の 1 pt あたりの距離（m）。Web メルカトル（`flutter_map` の既定。
/// 1 タイル 256 pt）で、その緯度の縮みを入れる。
double metersPerPoint(double latitude, double zoom) =>
    40075016.686 *
    math.cos(latitude * math.pi / 180) /
    (256 * math.pow(2, zoom));

/// [max] 以下で一番大きい、切りのよい距離（1・2・5 × 10ⁿ m）。
double niceDistance(double max) {
  if (max <= 0) return 0;
  final exp = math.pow(10, (math.log(max) / math.ln10).floor()).toDouble();
  for (final f in const [5, 2, 1]) {
    if (f * exp <= max) return f * exp;
  }
  return exp;
}

/// 「500 m」「2 km」。
String formatDistance(double meters) => meters >= 1000
    ? '${(meters / 1000).toStringAsFixed(meters % 1000 == 0 ? 0 : 1)} km'
    : '${meters.round()} m';

/// 棒（下端の横線と、上へ立つ両端と真ん中の目盛り。真ん中は短い）。線の下に面色の縁を敷いて、地図の
/// 上で読めるようにする。
class _BarPainter extends CustomPainter {
  const _BarPainter({required this.ink, required this.halo});

  final Color ink;
  final Color halo;

  @override
  void paint(Canvas canvas, Size size) {
    // 下端の横線と、両端・真ん中から上へ立つ目盛り（真ん中は短い）
    final path = Path()
      ..moveTo(1, 0)
      ..lineTo(1, size.height - 1)
      ..lineTo(size.width - 1, size.height - 1)
      ..lineTo(size.width - 1, 0)
      ..moveTo(size.width / 2, size.height * 0.4)
      ..lineTo(size.width / 2, size.height - 1);
    canvas
      ..drawPath(
        path,
        Paint()
          ..color = halo
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      )
      ..drawPath(
        path,
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
  }

  @override
  bool shouldRepaint(_BarPainter old) => old.ink != ink || old.halo != halo;
}
