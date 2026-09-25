import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tonsoku/features/map/data/stations.dart';

void main() {
  test('同梱の駅を読める', () {
    final stations = decodeStations(
      File('assets/map/stations.json').readAsStringSync(),
    );
    // 8,740 駅のうち、同じ名前で近いもの（路線・事業者ごとの重複）をまとめて 8,616
    expect(stations, hasLength(8616));
    expect(stations.where((s) => s.name == '東京'), hasLength(1));
    final shinjuku = stations.firstWhere((s) => s.name == '新宿');
    expect(shinjuku.nameEn, 'Shinjuku');
    expect(shinjuku.lat, closeTo(35.69, 0.01));
    expect(shinjuku.lon, closeTo(139.70, 0.01));
  });

  test('列の並びは fields に従う', () {
    final stations = decodeStations(
      '{"fields":["lat","lon","name_en","name"],"stations":[[35.1,139.2,"A","あ"]]}',
    );
    expect(stations.single.name, 'あ');
    expect(stations.single.nameEn, 'A');
    expect(stations.single.lat, 35.1);
    expect(stations.single.lon, 139.2);
  });

  test('英語名の列が無くても読める', () {
    final stations = decodeStations(
      '{"fields":["name","lat","lon"],"stations":[["あ",35,139]]}',
    );
    expect(stations.single.nameEn, '');
  });

  test('同じ名前で近い駅は 1 つにまとめ、遠い同名の駅は残す', () {
    final merged = mergeSameName(const [
      Station(name: '神田', nameEn: 'Kanda', lat: 35.6918, lon: 139.7709),
      Station(name: '神田', nameEn: 'Kanda', lat: 35.6937, lon: 139.7709),
      Station(name: '神田', nameEn: 'Kouda', lat: 33.2614, lon: 129.6713),
      Station(name: '東京', nameEn: 'Tokyo', lat: 35.681, lon: 139.768),
    ]);
    expect(merged, hasLength(3));
    final tokyoKanda = merged.firstWhere((s) => s.nameEn == 'Kanda');
    expect(tokyoKanda.lat, closeTo(35.69275, 1e-6));
  });
}
