import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:tonsoku/core/theme/app_colors.dart';
import 'package:tonsoku/core/theme/app_theme.dart';

/// 縮尺のメーター（下の真ん中）。**長さは大きめ、線と字は細く**（ユーザーの
/// 指定。太いと地図より目立った）。**棒を真ん中の目盛りで 2 つに割り、右端の目盛りの真上にその
/// 長さの距離を書く**（ユーザーの指定）。`flutter_map` の `Scalebar` は
/// 距離を棒の上の中央に書くので、「500 m」が棒全体なのか 1 目盛りなのか分から
/// なかった（ユーザーの指摘。短すぎるとも言われた）。
///
/// - 棒の長さは置き場（最大 [maxWidth]）に入る一番長い**切りのよい距離**（1・2・3・5 × 10ⁿ）
/// - 距離は 1000 m 未満なら m、以上なら km
/// - 地図の模様に紛れないよう、線の下に面色の縁を敷く
///
/// **FlutterMap の子として置く**（`MapCamera.of` で倍率が変わるたびに組み直す）。
class MapScaleBar extends StatelessWidget {
  const MapScaleBar({super.key});

  /// 棒の長さの上限（pt）。
  /// 棒の長さの上限（置き場が広い時）。
  static const maxWidth = 180.0;

  /// 距離の字の高さ（12pt・行の高さ 1）。
  static const labelHeight = 12.0;

  /// 置き場の幅の下限（これより狭ければ出さない）。
  static const minWidth = 56.0;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    // **置き場が狭ければ棒を縮める**（狭い端末で左下の著作権表記にかからない
    // よう、呼ぶ側が左右を空けた範囲に収める）
    // 距離の字（最長「1000 km」）も入らないほど狭ければ出さない
    builder: (context, constraints) => constraints.maxWidth < minWidth
        ? const SizedBox.shrink()
        : _bar(context, math.min(maxWidth, constraints.maxWidth)),
  );

  Widget _bar(BuildContext context, double limit) {
    final camera = MapCamera.of(context);
    final colors = context.colors;
    final perPoint = metersPerPoint(camera.center.latitude, camera.zoom);
    final meters = niceDistance(perPoint * math.max(limit, 1));
    final width = meters / perPoint;
    return ExcludeSemantics(
      // **距離は右端の目盛りの真上に、字の中央を合わせて載せる**（ユーザーの
      // 指定。横に並べると幅を取り、右端に字の端を揃えると目盛りとずれて見える）。
      // 字の右半分は棒からはみ出す（置き場の左右の余白に収まる。`_BottomDelegate`）
      child: SizedBox(
        width: width,
        height: labelHeight + 2 + 8,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              bottom: 0,
              child: CustomPaint(
                size: Size(width, 8),
                painter: _BarPainter(ink: colors.text, halo: colors.surface),
              ),
            ),
            Positioned(
              left: width,
              top: 0,
              child: FractionalTranslation(
                translation: const Offset(-0.5, 0),
                child: Text(
                  formatDistance(meters),
                  style: TextStyle(
                    fontSize: 12,
                    height: 1,
                    // 距離の字だけ太く（ユーザーの指定。線は細いまま）
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
              ),
            ),
          ],
        ),
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

/// [max] 以下で一番大きい、切りのよい距離（1・2・3・5 × 10ⁿ m）。**3 を入れる**
/// ―― 1・2・5 だけだと、上限を少し超えただけで棒が半分以下に縮む（1 km が
/// 入らず 500 m になる。短すぎると言われた）。
double niceDistance(double max) {
  if (max <= 0) return 0;
  final exp = math.pow(10, (math.log(max) / math.ln10).floor()).toDouble();
  for (final f in const [5, 3, 2, 1]) {
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
          ..strokeWidth = 3.5
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      )
      ..drawPath(
        path,
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
  }

  @override
  bool shouldRepaint(_BarPainter old) => old.ink != ink || old.halo != halo;
}
