import 'package:tonsoku/features/map/data/pmtiles.dart';
import 'package:tonsoku/features/map/data/bundled_tile_provider.dart';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonsoku/core/i18n/app_locale.dart';
import 'package:tonsoku/core/theme/app_colors.dart';
import 'package:tonsoku/features/map/presentation/map_theme.dart';

/// 背景地図の描き方。**`ThemeReader` は読めない層を黙って捨てる**ので、
/// 書いた層が全部残っていることを見る（式の書き間違いは例外にならず、
/// その層が地図から消えるだけ）。
void main() {
  const ids = [
    'background',
    'earth',
    'water',
    'boundaries-locality',
    'boundaries-region',
    'boundaries-country',
    'roads-major',
    'roads-highway',
    'rail',
    'places-major',
    'places-city',
    'places-town',
  ];

  for (final colors in [AppColors.light, AppColors.dark]) {
    for (final locale in AppLocale.values) {
      test('${colors.isDark ? 'ダーク' : 'ライト'} / ${locale.code}: 層が全部読める', () {
        final theme = buildMapTheme(colors, locale, dataVersion: 'd1');
        expect([for (final l in theme.layers) l.id], ids);
        expect(theme.tileSources, {mapTileSource});
      });
    }
  }

  test('テーマの id は配色と言語で変わる（描いたタイルの取り違えを防ぐ）', () {
    final a = buildMapTheme(
      AppColors.light,
      AppLocale.ja,
      dataVersion: 'd1',
    ).id;
    final b = buildMapTheme(AppColors.dark, AppLocale.ja, dataVersion: 'd1').id;
    final c = buildMapTheme(
      AppColors.light,
      AppLocale.en,
      dataVersion: 'd1',
    ).id;
    expect({a, b, c}, hasLength(3));
  });

  test('版は描き方と地図の版で変わる（描いたタイルの置き場の鍵。古い色を出さない）', () {
    String v(AppColors c, String data) =>
        buildMapTheme(c, AppLocale.ja, dataVersion: data).version;
    final base = v(AppColors.light, 'd1');
    expect(base, isNot('none'));
    // 同じ描き方・同じ地図なら同じ（毎回描き直さない）
    expect(v(AppColors.light, 'd1'), base);
    // 地図を作り直したら変わる
    expect(v(AppColors.light, 'd2'), isNot(base));
    // 描き方（色）が変わったら変わる
    expect(
      v(AppColors.dark, 'd1').split('-').first,
      isNot(base.split('-').first),
    );
  });

  test('同梱の地図の指紋は読むたびに同じ', () {
    final bytes = File(BundledTileProvider.asset).readAsBytesSync();
    expect(PmTiles(bytes).fingerprint, PmTiles(bytes).fingerprint);
  });
}
