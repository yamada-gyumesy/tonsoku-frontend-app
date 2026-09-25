import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tonsoku/features/map/data/stations.dart';

void main() {
  test('同梱の駅を読める', () {
    final stations = decodeStations(
      File('assets/map/stations.json').readAsStringSync(),
    );
    expect(stations, hasLength(8740));
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
}
