import 'package:flutter/foundation.dart';

/// 同梱の地図データ（`assets/map/japan.pmtiles` / `stations.json`）の帰属を
/// [LicenseRegistry] へ登録する（メニューのライセンス一覧に出る）。
///
/// どちらも OpenStreetMap 由来で、ライセンスは ODbL。**地図の上の帰属表記
/// （`MapAttribution`。地図の右下の「© OpenStreetMap」）が本体で、こちらは補い。**
///
/// **本文は英語だけで書く。** ライセンス一覧は言語を切り替えても同じ本文を
/// 出すので、日本語を混ぜると英語・中国語の画面に日本語が出る（英語・中国語の
/// 画面に日本語を出さないのはユーザーの決定。Issue #35）。
void registerMapDataLicense() {
  LicenseRegistry.addLicense(() async* {
    yield const LicenseEntryWithLineBreaks(
      ['OpenStreetMap'],
      'Map data © OpenStreetMap contributors\n'
      '\n'
      'Map data is available under the Open Database License (ODbL).\n'
      'https://www.openstreetmap.org/copyright\n'
      '\n'
      'The bundled map tiles are an extract of the Protomaps basemap '
      '(https://protomaps.com), built from OpenStreetMap data.',
    );
  });
}
