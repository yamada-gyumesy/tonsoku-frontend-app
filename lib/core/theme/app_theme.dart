import 'package:flutter/material.dart';

import 'package:tonsoku/core/i18n/app_locale.dart';
import 'package:tonsoku/core/theme/app_colors.dart';

/// ライト / ダークの `ThemeData` を組み立てる。
///
/// ## 書体はロケールで切り替える（web と同じ）
///
/// **日本語は Klee One**（本文・見出し・ナビ・数字まで全部）、**英語・中国語は
/// Noto Sans JP**。とん速の"色"を書体で出すという web の判断で、経緯は
/// web の `src/assets/styles/main.css` の `html[data-locale='ja']` にある。
///
/// **Klee One は SemiBold（600）1 つだけを同梱する**（web も画面は 600 だけで描く。
/// Regular は細すぎて本文が読めなかった）。`FontWeight.w400` を指定しても
/// 600 で描かれる。
///
/// 同梱の範囲と作り方は `tool/build_fonts.py`。
abstract final class AppTheme {
  /// 日本語の書体。
  static const jaFontFamily = 'Klee One';

  /// 英語・中国語の書体。
  static const defaultFontFamily = 'Noto Sans JP';

  static String fontFamilyFor(AppLocale locale) =>
      locale == AppLocale.ja ? jaFontFamily : defaultFontFamily;

  static ThemeData light(AppLocale locale) =>
      _build(Brightness.light, AppColors.light, fontFamilyFor(locale));
  static ThemeData dark(AppLocale locale) =>
      _build(Brightness.dark, AppColors.dark, fontFamilyFor(locale));

  static ThemeData _build(
    Brightness brightness,
    AppColors colors,
    String fontFamily,
  ) {
    // **面の色は自前のトークンで塗り潰す。** `fromSeed` は種の赤から
    // surfaceContainer 系まで色を派生させるので、そのままだとボトムシートや
    // ダイアログの地がほんのり赤くなり、web の面と食い違う
    final scheme =
        ColorScheme.fromSeed(
          seedColor: colors.primary,
          brightness: brightness,
        ).copyWith(
          // **ブランド色は種として渡すだけでは表に出ない。** `fromSeed` は
          // M3 のトーン表に落とすので、種がロゴの赤でも `primary` は別の色に
          // なる（gyumesy のピンクはライトで #8B4A62 になった）。読み込みの輪や
          // 文字選択など `colorScheme` の既定に落ちる部品はその派生色で描かれる。
          //
          // **地の上に置かれる部品が多いので `primaryText` を渡す。** 塗りの
          // `primary` はダークで地に対して 3:1 に届かない（[AppColors.primary]）
          primary: colors.primaryText,
          onPrimary: colors.isDark ? colors.bg : colors.onPrimary,
          surface: colors.surface,
          onSurface: colors.text,
          surfaceContainerLowest: colors.surface,
          surfaceContainerLow: colors.surface,
          surfaceContainer: colors.surface,
          surfaceContainerHigh: colors.surface,
          surfaceContainerHighest: colors.surface,
          surfaceDim: colors.bg,
          surfaceBright: colors.surface,
          outline: colors.border,
          outlineVariant: colors.border,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: fontFamily,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.page,
      dividerColor: colors.border,
      // **読み込みの輪はロゴの赤（地の上に置く方）で回す**（理由は上の `primary`）
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primaryText,
        circularTrackColor: Colors.transparent,
        refreshBackgroundColor: colors.surface,
      ),
      extensions: [colors],
      // **ヘッダーの地は生成り**（web の `CoHeader` は `bg-brand-bg`）
      appBarTheme: AppBarTheme(
        backgroundColor: colors.bg,
        foregroundColor: colors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: colors.border,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
