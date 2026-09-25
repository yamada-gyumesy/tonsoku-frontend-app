import 'package:flutter_test/flutter_test.dart';
import 'package:tonsoku/features/map/presentation/widgets/map_scale_bar.dart';

/// 縮尺のメーター。**棒全体が書いた距離**になる（目盛りで割らない）。
void main() {
  test('切りのよい距離（1・2・3・5 × 10ⁿ）で上限を超えない', () {
    expect(niceDistance(730), 500);
    expect(niceDistance(1999), 1000);
    expect(niceDistance(2000), 2000);
    expect(niceDistance(4999), 3000);
    expect(niceDistance(9), 5);
    expect(niceDistance(350), 300);
  });

  test('1000 m からは km', () {
    expect(formatDistance(500), '500 m');
    expect(formatDistance(1000), '1 km');
    expect(formatDistance(2000), '2 km');
  });

  test('赤道の z0 は 1 pt ≒ 156 km、緯度 60 度で半分', () {
    expect(metersPerPoint(0, 0), closeTo(156543, 1));
    expect(metersPerPoint(60, 0), closeTo(156543 / 2, 1));
    expect(metersPerPoint(0, 1), closeTo(156543 / 2, 1));
  });
}
