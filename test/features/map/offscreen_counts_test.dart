import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tonsoku/features/map/presentation/widgets/offscreen_counts.dart';

/// 画面の外の店を方角ごとにまとめる。**画面の座標で分ける**（地図の回転は
/// `toScreen` の側に入っている）。
void main() {
  const size = Size(400, 600);

  // 緯度経度を、そのまま画面の座標として使う（lon → x、lat → y）
  Offset toScreen(LatLng p) => Offset(p.longitude, p.latitude);
  LatLng at(double x, double y) => LatLng(y, x);

  test('画面の中の店は数えない', () {
    expect(
      groupOffscreen(
        [at(200, 300), at(10, 10)],
        size: size,
        toScreen: toScreen,
      ),
      isEmpty,
    );
  });

  test('8 つの方角にまとめ、一番近い店を覚える', () {
    final groups = groupOffscreen(
      [
        at(200, -50), // 上
        at(210, -500), // 上（遠い）
        at(600, 300), // 右
        at(-100, 900), // 左下
      ],
      size: size,
      toScreen: toScreen,
    );
    final bySector = {for (final g in groups) g.sector: g};
    expect(bySector.keys.toSet(), {0, 2, 5});
    expect(bySector[0]!.count, 2);
    expect(bySector[0]!.nearest, at(200, -50));
    expect(bySector[2]!.count, 1);
    expect(bySector[5]!.count, 1);
  });

  test('方角の境目（45 度ずつ）', () {
    expect(sectorOf(const Offset(0, -1)), 0); // 上
    expect(sectorOf(const Offset(1, -1)), 1); // 右上
    expect(sectorOf(const Offset(1, 0)), 2); // 右
    expect(sectorOf(const Offset(0, 1)), 4); // 下
    expect(sectorOf(const Offset(-1, 0)), 6); // 左
    expect(sectorOf(const Offset(-1, -1)), 7); // 左上
  });

  test('札は縁に置く（上は上辺の中央、右上は角）', () {
    const area = Rect.fromLTWH(0, 0, 400, 600);
    expect(edgePoint(area, 0), const Offset(200, 0));
    expect(edgePoint(area, 2), const Offset(400, 300));
    final ne = edgePoint(area, 1);
    // 右上は右辺か上辺に当たる（幅が狭いので右辺）
    expect(ne.dx, closeTo(400, 1e-6));
  });
}
