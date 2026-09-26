import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tonsoku/core/i18n/app_locale.dart';
import 'package:tonsoku/features/map/data/stations.dart';

void main() {
  test('同梱の駅を読める', () {
    final stations = decodeStations(
      File('assets/map/stations.json').readAsStringSync(),
    );
    // 8,740 駅のうち、同じ名前で近いもの（路線・事業者ごとの重複）をまとめて 8,616
    expect(stations, hasLength(8616));
    final tokyo = stations.where((s) => s.name == '東京');
    expect(tokyo, hasLength(1));
    expect(tokyo.single.nameZh, '东京');
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
    expect(stations.single.nameZh, '');
  });

  test('中国語名の列を fields に従って読む', () {
    final stations = decodeStations(
      '{"fields":["name_zh","name","name_en","lat","lon"],'
      '"stations":[["东京","東京","Tokyo",35.68,139.77]]}',
    );
    expect(stations.single.nameZh, '东京');
    expect(stations.single.nameEn, 'Tokyo');
  });

  test('同梱の駅の英語名・中国語名に仮名が残っていない', () {
    final stations = decodeStations(
      File('assets/map/stations.json').readAsStringSync(),
    );
    final kana = RegExp(r'[\u3040-\u30ff\uff65-\uff9f]');
    expect([for (final s in stations) s.nameEn].where(kana.hasMatch), isEmpty);
    expect([for (final s in stations) s.nameZh].where(kana.hasMatch), isEmpty);
  });

  // **中国語名の無い駅の補い方はユーザーの決定**（`tool/build_map_names.py`）:
  // 日本語名が仮名を含まなければ、それを簡体字にしたもの。仮名を含めば英語名
  test('同梱の駅の中国語名は簡体字に揃っていて、ほぼ全駅に在る', () {
    final stations = decodeStations(
      File('assets/map/stations.json').readAsStringSync(),
    );
    String zh(String name) => stations.firstWhere((s) => s.name == name).nameZh;
    expect(zh('新宿'), '新宿');
    expect(zh('渋谷'), '涩谷');
    expect(zh('代々木'), '代代木');
    // 「ケ」「ヶ」「ノ」は仮名なので英語名
    expect(zh('霞ケ関'), 'Kasumigaseki');
    // OpenStreetMap の中国語名に付いている「站」は落とす（日本語名に「駅」は無い）
    expect(zh('王子神谷'), '王子神谷');
    final names = [for (final s in stations) s.nameZh];
    expect(names.where((n) => n.isEmpty).length, lessThan(50));
    expect(names.where(RegExp('[澤沢區國縣県會長東鐵鉄關関島廣広渋澁條々]').hasMatch), isEmpty);
    // 端末の書体に無いことが多い字（基本多言語面の外・拡張 A）を出さない
    expect(
      names.where(
        (n) => n.runes.any((r) => r > 0xffff || (r >= 0x3400 && r <= 0x4dbf)),
      ),
      isEmpty,
    );
  });

  group('言語ごとの駅名（英語・中国語の画面に日本語を出さない。Issue #35）', () {
    const both = Station(
      name: '東京',
      nameEn: 'Tokyo',
      nameZh: '东京',
      lat: 35.68,
      lon: 139.77,
    );
    const jaOnly = Station(name: '下ノ江', nameEn: '', lat: 33.1, lon: 131.7);

    test('それぞれの言語の名前を出す', () {
      expect(both.labelFor(AppLocale.ja), '東京');
      expect(both.labelFor(AppLocale.en), 'Tokyo');
      expect(both.labelFor(AppLocale.zh), '东京');
    });

    test('訳が無ければ null（日本語に落とさず、描かない）', () {
      expect(jaOnly.labelFor(AppLocale.ja), '下ノ江');
      expect(jaOnly.labelFor(AppLocale.en), isNull);
      expect(jaOnly.labelFor(AppLocale.zh), isNull);
    });
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

  test('まとめた駅の英語名・中国語名は、名前を持つ最初の点から採る', () {
    final merged = mergeSameName(const [
      Station(name: '大手町', nameEn: '', lat: 35.686, lon: 139.765),
      Station(
        name: '大手町',
        nameEn: 'Otemachi',
        nameZh: '大手町',
        lat: 35.687,
        lon: 139.766,
      ),
    ]);
    expect(merged.single.nameEn, 'Otemachi');
    expect(merged.single.nameZh, '大手町');
  });
}
