import 'package:flutter/services.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';

import 'package:tonsoku/features/map/data/pmtiles.dart';

/// 同梱の背景地図（`assets/map/japan.pmtiles`）からタイルを出す。
///
/// 中身は Protomaps（OpenStreetMap 由来）の日本の範囲を、**陸・水域・境界・
/// 主な道路と鉄道・地名**だけに絞ったもの（作り方は `tool/build_map.sh`）。
///
/// **最大ズームは 11**（それ以上は容量が倍々に増える。`tool/build_map.sh`）。
/// 店の周りを見る倍率（〜17）では `vector_map_tiles` が z11 のタイルを
/// 切り出して引き伸ばす（線の地図なので崩れない）。
class BundledTileProvider extends VectorTileProvider {
  BundledTileProvider(this._archive);

  static const asset = 'assets/map/japan.pmtiles';

  /// 同梱の地図を読み込む。**マップを初めて開いた時に 1 回だけ**（30MB を
  /// メモリに置く。理由は [PmTiles]）。
  static Future<BundledTileProvider> load(AssetBundle bundle) async {
    final data = await bundle.load(asset);
    return BundledTileProvider(PmTiles(Uint8List.sublistView(data)));
  }

  final PmTiles _archive;

  /// 地図の版（[PmTiles.fingerprint]）。描いたタイルの置き場の鍵に入れる
  /// （`buildMapTheme` の `dataVersion`）。
  String get dataVersion => _archive.fingerprint;

  @override
  int get maximumZoom => _archive.header.maxZoom;

  @override
  int get minimumZoom => _archive.header.minZoom;

  @override
  TileOffset get tileOffset => TileOffset.DEFAULT;

  @override
  Future<Uint8List> provide(TileIdentity tile) async {
    // 範囲の外（経度を回り込んだ区画など）は番号にできないので、無いものとして返す
    final bytes = tile.isValid() ? _archive.tile(tile.z, tile.x, tile.y) : null;
    if (bytes == null) {
      // **海だけの区画・範囲の外は書き出されていない。** 404 として返すと
      // `vector_map_tiles` は空のタイルとして扱い、下地（海の色）だけが出る
      throw ProviderException(
        message: 'no tile ${tile.key()}',
        statusCode: 404,
        retryable: Retryable.none,
      );
    }
    return bytes;
  }
}
