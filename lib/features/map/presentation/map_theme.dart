import 'dart:convert';

import 'package:flutter/painting.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart' as vtr;

import 'package:tonsoku/core/i18n/app_locale.dart';
import 'package:tonsoku/core/theme/app_colors.dart';
import 'package:tonsoku/core/theme/app_theme.dart';
import 'package:tonsoku/features/map/data/pmtiles.dart';

/// 背景地図のタイルの出どころの名前（テーマの `source` と `TileProviders` の鍵）。
const mapTileSource = 'protomaps';

/// 背景地図の描き方（Mapbox GL のスタイルの形。`vector_tile_renderer` が読む）。
///
/// **層と属性は同梱の地図に合わせてある**（Protomaps basemap v4 の形から絞ったもの。
/// `tool/build_map.sh`）。地図を作り直して層や属性を変えたら、ここも直すこと
/// ―― 名前がずれても例外にはならず、**その層が黙って描かれなくなる**。
///
/// 色は [MapPalette]（`app_colors.dart`）から引く。**ここに色を書かない。**
///
/// ## 地名の書体
///
/// **アプリの本文と同じ書体で描く**（日本語は Klee One、英語・中国語は Noto Sans JP。
/// [AppTheme.fontFamilyFor]）。`text-font` の先頭が Flutter の `fontFamily` として
/// そのまま使われる（`vector_tile_renderer` の `ThemeReader`）ので、同梱の書体の
/// 名前を渡せば足りる。
///
/// ## 地名の言語
///
/// 日本語は `name:ja`、英語は `name:en`。**中国語は `name`（日本語の表記）**
/// ―― 地図に中国語名は入れていない（容量を増やしてまで入れる価値が薄い。
/// 地名の漢字は中国語の話者にもおおむね読める）。無ければどれも `name` に落とす。
///
/// ## 版（`metadata.version`）
///
/// **描き方と地図の版を入れる。** `vector_map_tiles` は描いたタイルを一時領域に
/// `'{id}-v{version}-z-x-y.png'` で 30 日残す（9.0.0-beta.13 の
/// `raster/storage_image_cache.dart`）。版を入れないと常に `none` になり、配色を
/// 変えた版や地図を作り直した版を出しても、**前に見た区画だけが古いまま出る**。
/// 描き方の版はこの JSON 自体のハッシュ（色・層を変えれば自動で変わる）、
/// 地図の版は [dataVersion]（`BundledTileProvider.dataVersion`）。
vtr.Theme buildMapTheme(
  AppColors colors,
  AppLocale locale, {
  required String dataVersion,
}) {
  final p = MapPalette.of(colors);
  final font = [AppTheme.fontFamilyFor(locale)];
  final name = switch (locale) {
    AppLocale.ja => [
      'coalesce',
      ['get', 'name:ja'],
      ['get', 'name'],
    ],
    AppLocale.en => [
      'coalesce',
      ['get', 'name:en'],
      ['get', 'name'],
    ],
    AppLocale.zh => ['get', 'name'],
  };

  String hex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  /// ズームに比例して太る線（[z] で [w] px）。
  List<Object> width(List<(num, num)> stops) => [
    'interpolate',
    ['exponential', 1.6],
    ['zoom'],
    for (final (z, w) in stops) ...[z, w],
  ];

  Map<String, Object> label({
    required String id,
    required List<Object> filter,
    required num minzoom,
    num? maxzoom,
    required List<Object> size,
  }) => {
    'id': id,
    'type': 'symbol',
    'source': mapTileSource,
    'source-layer': 'places',
    'minzoom': minzoom,
    'maxzoom': ?maxzoom,
    'filter': filter,
    'layout': {
      'text-field': name,
      'text-font': font,
      'text-size': size,
      'text-anchor': 'center',
      'text-max-width': 8,
    },
    'paint': {
      'text-color': hex(p.label),
      'text-halo-color': hex(p.labelHalo),
      'text-halo-width': 1.5,
    },
  };

  final json = <String, Object>{
    // **テーマの id を配色と言語ごとに変える。** `vector_map_tiles` は描いた
    // タイルを id で覚えていて、同じ id のままテーマを差し替えると、
    // 切り替える前の色のタイルが残る
    'id': 'tonsoku-${colors.isDark ? 'dark' : 'light'}-${locale.code}',
    'version': 8,
    'sources': {
      mapTileSource: {'type': 'vector'},
    },
    'layers': [
      // 海は陸の外側（同梱の地図に海の面は無い。`tool/build_map.sh`）
      {
        'id': 'background',
        'type': 'background',
        'paint': {'background-color': hex(p.water)},
      },
      {
        'id': 'earth',
        'type': 'fill',
        'source': mapTileSource,
        'source-layer': 'earth',
        'paint': {'fill-color': hex(p.land)},
      },
      {
        'id': 'water',
        'type': 'fill',
        'source': mapTileSource,
        'source-layer': 'water',
        'paint': {'fill-color': hex(p.water)},
      },
      // 市区町村の境（都道府県・国より内側の区切り）。近寄った時だけ
      {
        'id': 'boundaries-locality',
        'type': 'line',
        'source': mapTileSource,
        'source-layer': 'boundaries',
        'minzoom': 9,
        'filter': ['!in', 'kind', 'country', 'region'],
        'paint': {
          'line-color': hex(p.boundaryRegion),
          'line-width': 0.6,
          'line-dasharray': [3, 2],
        },
      },
      {
        'id': 'boundaries-region',
        'type': 'line',
        'source': mapTileSource,
        'source-layer': 'boundaries',
        'filter': ['==', 'kind', 'region'],
        'paint': {
          'line-color': hex(p.boundaryRegion),
          'line-width': width([(5, 0.6), (12, 1.6)]),
          'line-dasharray': [4, 2],
        },
      },
      {
        'id': 'boundaries-country',
        'type': 'line',
        'source': mapTileSource,
        'source-layer': 'boundaries',
        'filter': ['==', 'kind', 'country'],
        'paint': {
          'line-color': hex(p.boundaryCountry),
          'line-width': width([(3, 0.8), (10, 2)]),
        },
      },
      {
        'id': 'roads-major',
        'type': 'line',
        'source': mapTileSource,
        'source-layer': 'roads',
        'minzoom': 9,
        'filter': ['==', 'kind', 'major_road'],
        'paint': {
          'line-color': hex(p.majorRoad),
          'line-width': width([(9, 0.6), (13, 2.5), (17, 8)]),
        },
      },
      {
        'id': 'roads-highway',
        'type': 'line',
        'source': mapTileSource,
        'source-layer': 'roads',
        'minzoom': 6,
        'filter': ['==', 'kind', 'highway'],
        'paint': {
          'line-color': hex(p.highway),
          'line-width': width([(6, 0.6), (12, 2.5), (17, 10)]),
        },
      },
      // **鉄道は破線で道路と分ける**（色だけだと細い線どうしで見分けにくい）
      {
        'id': 'rail',
        'type': 'line',
        'source': mapTileSource,
        'source-layer': 'roads',
        'minzoom': 8,
        'filter': ['==', 'kind', 'rail'],
        'paint': {
          'line-color': hex(p.rail),
          'line-width': width([(8, 0.6), (13, 1.2), (17, 2.2)]),
          'line-dasharray': [4, 3],
        },
      },
      // 地名。**引いた時は大きな市だけ、寄るほど細かく**出す。
      //
      // **都道府県の名前は地図に入っていない**（Protomaps の `places` の
      // `region` は日本では出ない。2026-09-25 に同梱の地図で確かめた。
      // 東京都も `locality` の `city` として入っている）。引いた時の手がかりは
      // 大きな市の名前で足りる。どこまで出すかは Protomaps が付けた
      // `min_zoom`（その地名を出してよい倍率の目安）で決める
      label(
        id: 'places-major',
        filter: [
          'all',
          ['==', 'kind', 'locality'],
          ['<=', 'min_zoom', 6],
        ],
        minzoom: 5,
        maxzoom: 8,
        size: [
          'interpolate',
          ['linear'],
          ['zoom'],
          5,
          11,
          8,
          13,
        ],
      ),
      label(
        id: 'places-city',
        filter: [
          'all',
          ['==', 'kind', 'locality'],
          ['==', 'kind_detail', 'city'],
        ],
        minzoom: 8,
        size: [
          'interpolate',
          ['linear'],
          ['zoom'],
          8,
          11,
          13,
          14,
        ],
      ),
      label(
        id: 'places-town',
        filter: [
          'all',
          ['==', 'kind', 'locality'],
          ['in', 'kind_detail', 'town', 'village'],
        ],
        minzoom: 10,
        size: [
          'interpolate',
          ['linear'],
          ['zoom'],
          10,
          10,
          14,
          12,
        ],
      ),
    ],
  };
  final style = fnv1a(utf8.encode(jsonEncode(json)));
  json['metadata'] = {'version': '$style-$dataVersion'};
  return vtr.ThemeReader().read(json);
}
