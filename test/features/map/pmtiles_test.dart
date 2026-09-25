import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tonsoku/features/map/data/pmtiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

/// 同梱の背景地図の読み手（自前の PMTiles v3。`pmtiles.dart`）。
void main() {
  test('タイル ID は仕様の参照実装と同じ', () {
    // PMTiles の仕様書のテスト値（z0 → 0、z1 はヒルベルト曲線の順）
    expect(zxyToTileId(0, 0, 0), 0);
    expect(zxyToTileId(1, 0, 0), 1);
    expect(zxyToTileId(1, 0, 1), 2);
    expect(zxyToTileId(1, 1, 1), 3);
    expect(zxyToTileId(1, 1, 0), 4);
    expect(zxyToTileId(2, 0, 0), 5);
    expect(zxyToTileId(20, 0, 0), 366503875925);
  });

  test('ディレクトリの位置は「0 なら直前の続き」', () {
    // 3 項目: ID 1,2,5（差分 1,1,3）/ 連続 1,1,1 / 長さ 10,20,30 / 位置 1(=0),0(続き),0(続き)
    final entries = decodeDirectory(
      Uint8List.fromList([3, 1, 1, 3, 1, 1, 1, 10, 20, 30, 1, 0, 0]),
    );
    expect([for (final e in entries) e.tileId], [1, 2, 5]);
    expect([for (final e in entries) e.offset], [0, 10, 30]);
    expect(findEntry(entries, 5)?.length, 30);
    expect(findEntry(entries, 3), isNull); // ID 2 の連続は 1 つだけ
    expect(findEntry(entries, 0), isNull);
  });

  group('同梱の地図', () {
    final archive = PmTiles(File('assets/map/japan.pmtiles').readAsBytesSync());

    (int, int) tileOf(double lat, double lon, int z) {
      final n = 1 << z;
      final x = ((lon + 180) / 360 * n).floor();
      final r = lat * math.pi / 180;
      final y =
          ((1 - math.log(math.tan(r) + 1 / math.cos(r)) / math.pi) / 2 * n)
              .floor();
      return (x, y);
    }

    test('ヘッダー（z0〜11・gzip）', () {
      expect(archive.header.minZoom, 0);
      expect(archive.header.maxZoom, 11);
      expect(archive.header.tileCompression, 2);
    });

    test('新宿の z11 のタイルに地名と陸がある（ID の計算が合っている）', () {
      final (x, y) = tileOf(35.6938, 139.7034, 11);
      final bytes = archive.tile(11, x, y);
      expect(bytes, isNotNull);
      final tile = VectorTileReader().read(bytes!);
      final layers = {for (final l in tile.layers) l.name};
      expect(layers, containsAll(['earth', 'places', 'roads']));
      // 地名の値は UTF-8 のままタイルに入っている。**別の区画を引いていたら
      // 新宿の名前は入っていない**（ID の計算違いはここで分かる）
      expect(_contains(bytes, utf8.encode('新宿')), isTrue);
    });

    test('札幌・那覇も引ける（葉のディレクトリを辿れる）', () {
      for (final (lat, lon) in const [
        (43.0686, 141.3508),
        (26.2124, 127.6809),
      ]) {
        final (x, y) = tileOf(lat, lon, 11);
        expect(archive.tile(11, x, y), isNotNull, reason: '$lat,$lon');
      }
    });

    test('範囲の外は null', () {
      // 太平洋の真ん中（範囲の外）
      final (x, y) = tileOf(0, -150, 8);
      expect(archive.tile(8, x, y), isNull);
    });
  });
}

bool _contains(Uint8List haystack, List<int> needle) {
  outer:
  for (var i = 0; i <= haystack.length - needle.length; i++) {
    for (var j = 0; j < needle.length; j++) {
      if (haystack[i + j] != needle[j]) continue outer;
    }
    return true;
  }
  return false;
}
