import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 駅 1 つ。
class Station {
  const Station({
    required this.name,
    required this.nameEn,
    required this.lat,
    required this.lon,
  });

  final String name;

  /// 英語名。**無い駅は空文字**（OpenStreetMap に `name:en` が無い）。
  final String nameEn;
  final double lat;
  final double lon;
}

/// 同梱の駅（`assets/map/stations.json`）。
///
/// **背景地図とは別に持つ。** Protomaps の地図には主要駅しか入っておらず、
/// しかも多くは z13〜15 にしか現れない（同梱の地図は z11 まで。理由は
/// `tool/build_map.sh`）。店の最寄り駅が出ないと場所の見当が付かないので、
/// OpenStreetMap の駅を名前と座標だけにして印として描く。
///
/// 形は `{"fields": ["name","name_en","lat","lon"], "stations": [[…], …]}`。
/// **列の並びは `fields` に従って読む**（並びを決め打ちにすると、作り直して
/// 列を足した時に黙ってずれる）。
List<Station> decodeStations(String body) {
  final json = jsonDecode(body) as Map<String, dynamic>;
  final fields = (json['fields'] as List<dynamic>).cast<String>();
  final name = fields.indexOf('name');
  final nameEn = fields.indexOf('name_en');
  final lat = fields.indexOf('lat');
  final lon = fields.indexOf('lon');
  if (name < 0 || lat < 0 || lon < 0) {
    throw const FormatException('stations.json の列が足りない');
  }
  final all = [
    for (final row in json['stations'] as List<dynamic>)
      if (row case final List<dynamic> r)
        Station(
          name: r[name] as String,
          nameEn: nameEn < 0 ? '' : (r[nameEn] as String? ?? ''),
          lat: (r[lat] as num).toDouble(),
          lon: (r[lon] as num).toDouble(),
        ),
  ];
  return mergeSameName(all);
}

/// **同じ名前で近い駅を 1 つにまとめる。** OpenStreetMap は路線・事業者ごとに
/// 駅を別に持つので、そのまま描くと「東京」「霞ケ関」が 2〜3 個ずつ並ぶ。
///
/// 近いとみなすのは [mergeWithin]（度。緯度で約 1km）以内。遠い同名の駅
/// （長崎の「神田」と東京の「神田」）はまとめない。まとめた駅の位置は平均、
/// 英語名は最初の駅のもの。
List<Station> mergeSameName(List<Station> stations) {
  final groups = <String, List<List<Station>>>{};
  for (final st in stations) {
    final clusters = groups.putIfAbsent(st.name, () => []);
    final near = clusters.where(
      (c) =>
          (c.first.lat - st.lat).abs() < mergeWithin &&
          (c.first.lon - st.lon).abs() < mergeWithin,
    );
    if (near.isEmpty) {
      clusters.add([st]);
    } else {
      near.first.add(st);
    }
  }
  return [
    for (final clusters in groups.values)
      for (final c in clusters)
        Station(
          name: c.first.name,
          nameEn: c.first.nameEn,
          lat: c.map((s) => s.lat).reduce((a, b) => a + b) / c.length,
          lon: c.map((s) => s.lon).reduce((a, b) => a + b) / c.length,
        ),
  ];
}

/// [mergeSameName] で同じ駅とみなす距離（度）。
const mergeWithin = 0.01;

/// 駅の一覧。**マップを初めて開いた時に 1 回だけ読む**（390KB・8,700 駅）。
final stationsProvider = FutureProvider<List<Station>>((ref) async {
  final body = await rootBundle.loadString('assets/map/stations.json');
  return decodeStations(body);
});
