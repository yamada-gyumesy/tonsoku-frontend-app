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
        final theme = buildMapTheme(colors, locale);
        expect([for (final l in theme.layers) l.id], ids);
        expect(theme.tileSources, {mapTileSource});
      });
    }
  }

  test('テーマの id は配色と言語で変わる（描いたタイルの取り違えを防ぐ）', () {
    final a = buildMapTheme(AppColors.light, AppLocale.ja).id;
    final b = buildMapTheme(AppColors.dark, AppLocale.ja).id;
    final c = buildMapTheme(AppColors.light, AppLocale.en).id;
    expect({a, b, c}, hasLength(3));
  });
}
