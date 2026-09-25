import 'package:flutter/material.dart';

/// 配色トークン。**web（`tonsoku-frontend-web`）の `src/assets/styles/main.css` の
/// `--color-brand-*` を移植した。** 値と各コントラスト比の実測、選んだ理由は
/// あちらのコメントが正で、ここには判断に要るものだけを写してある。
///
/// **セマンティック名で参照させること**（`page` / `surface` / `text` …）。画面から
/// 生の色を書くとテーマ切替に追従しなくなる。web 側でトークンを変えた時は
/// ここも合わせて変える。
///
/// ## 守る基準（web と同じ）
///
/// **文字は載る地に対して 4.5:1。** 意味を持つ非テキスト（アイコン、構造を示す境界）は
/// 3:1。純粋な装飾（罫線）は対象外。
///
/// ## 松屋の意匠を持ち込まない
///
/// **gyumesy-frontend-app の `AppColors` を写したが、色は全部入れ替えてある。**
/// あちらのピンク（`pink` / `pinkStrong`）や Twitter「Dim」系のダークは
/// 松屋（ギュメシー）の配色で、とん速の見た目に持ち込まない。
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bg,
    required this.surface,
    required this.hover,
    required this.text,
    required this.textSub,
    required this.border,
    required this.primary,
    required this.onPrimary,
    required this.primaryText,
    required this.primarySoft,
    required this.fill,
    required this.onFill,
    required this.portrait,
    required this.codePlate,
    required this.brown,
    required this.green,
    required this.chipNeutral,
    required this.toggleThumb,
    required this.toggleThumbText,
  });

  /// 地（生成り）。**紙面の外側**（web では左右に見える帯）と、引用・コード・
  /// 表の縞、サムネイルの器、**下タブとヘッダーの地**に敷く。
  final Color bg;

  /// 紙面と、その上に置く面。**ページの大半はこの色**（web は地の上に白いコラムが
  /// 1 本通る作り。アプリは画面幅がそのままコラムなので、本文の地はこれになる）。
  final Color surface;

  /// 押下・hover の地。副テキストが 4.5:1 を保てる範囲の濃さ。
  final Color hover;

  /// 主テキスト。松のや公式ロゴの墨色の実測値（真っ黒ではなくわずかに赤みがある）。
  final Color text;

  /// 副テキスト。**地・面・hover・淡赤面の 4 種類の全てで 4.5:1 を満たす値。**
  final Color textSub;

  /// 罫線・仕切り。装飾なのでコントラスト要件は無い。
  final Color border;

  /// プライマリ（塗り）。とん速のロゴの赤。上に載るのは常に [onPrimary]（白）。
  ///
  /// **このトークンを、地の上に直接置くものに使わないこと。罫線もアイコンも文字も。**
  /// ダークでは面に対して 2.75:1 しか出ず、非テキストの 3:1 にも届かない。
  /// **ライトでは同じ使い方で 7.20:1 出るので、ライトだけ見ていると気づけない**
  /// （web がグローバルナビの現在地で踏んでいる）。地の上に置く赤は [primaryText]。
  final Color primary;
  final Color onPrimary;

  /// 地の上に直接置く赤（文字・アイコン・現在地）。ライトはロゴの赤のまま、
  /// ダークは色相をわずかに暖色へ振って明度を上げてある。
  ///
  /// **[primary] と 1 つにまとめないこと。** まとめると「ボタンが暗地に沈む」か
  /// 「文字が読めない」のどちらかになる。
  final Color primaryText;

  /// 淡い赤の面（ひとことの箱）。**チップの地ではない。**
  final Color primarySoft;

  /// 反転ボタンの地（ライトは黒、ダークは白に入れ替わる）。
  final Color fill;
  final Color onFill;

  /// 人物（のや子）を載せる白地。**ダークでも明るいまま**（線画は赤単色で、
  /// 暗地に置くとほぼ見えない）。
  final Color portrait;

  /// コードの絵（クーポンの 2 次元コード）を敷く地。**ダークでは敷かない**（透明）。
  final Color codePlate;

  /// 茶（本文の h3 の左罫などの差し色）。
  final Color brown;

  /// 緑。**差し色に留め、主色にしない**（松のや公式でも面積 2%）。
  final Color green;

  /// タグのチップの地（タグは色を持たないので中立の 1 色）。
  final Color chipNeutral;

  /// 切替つまみ（テーマ切替の選択中の丸）と、その上に載る文字。
  /// **ライトの反転ではない**（ダークで同じにするとつまみが溝に沈む）。
  final Color toggleThumb;
  final Color toggleThumbText;

  /// **本文（ページ）の地。** web の紙面（`brand-surface`）に相当する。
  Color get page => surface;

  /// ダークかどうか。テーマごとの分岐をここに集約する。
  bool get isDark => bg.computeLuminance() < 0.5;

  static const light = AppColors(
    bg: Color(0xFFFAF7F3),
    surface: Color(0xFFFFFFFF),
    hover: Color(0xFFF2EDE6),
    text: Color(0xFF231815), // 面 17.31:1 / 地 16.21:1
    textSub: Color(0xFF6E625B), // 面 5.90:1 / 地 5.52:1 / hover 5.06:1
    border: Color(0xFFE7DFD5),
    primary: Color(0xFFA7232A), // 白文字 7.20:1
    onPrimary: Color(0xFFFFFFFF),
    primaryText: Color(0xFFA7232A), // 面 7.20:1 / 地 6.74:1
    primarySoft: Color(0xFFFBEFEF),
    fill: Color(0xFF1A1A1A),
    onFill: Color(0xFFFFFFFF),
    portrait: Color(0xFFFFFFFF),
    codePlate: Color(0xFFFFFFFF),
    brown: Color(0xFF6B4A34),
    green: Color(0xFF046240),
    chipNeutral: Color(0xFFF3F2F2),
    toggleThumb: Color(0xFFA7232A),
    toggleThumbText: Color(0xFFFFFFFF),
  );

  /// ダーク。**ライトの反転ではなく、暗地で読める値を組み直したもの**（web と同じ値）。
  /// 地と面は無彩色の黒ではなく茶に寄せた黒にして、ライトの生成りと同じ温度を保つ。
  static const dark = AppColors(
    // **`pubspec.yaml` の `flutter_native_splash.color_dark` を入れる時は
    // これと揃える**（リリース整備の Issue）。起動画面の地色が違うと、
    // ダークで起動するたびに地色が切り替わる
    bg: Color(0xFF16110F),
    surface: Color(0xFF211A17),
    hover: Color(0xFF2A221E),
    text: Color(0xFFF5EFE9), // 面 15.03:1 / 地 16.42:1
    textSub: Color(0xFFA79A92), // 面 6.27:1 / 地 6.85:1 / hover 5.71:1
    border: Color(0xFF392F2A),
    primary: Color(0xFFB62A31), // 白文字 6.24:1
    onPrimary: Color(0xFFFFFFFF),
    primaryText: Color(0xFFDA6E62), // 面 5.22:1 / 地 5.70:1
    primarySoft: Color(0xFF33211F),
    fill: Color(0xFFF5EFE9),
    onFill: Color(0xFF16110F),
    portrait: Color(0xFFF5EFE9),
    codePlate: Color(0x00000000),
    brown: Color(0xFFC9A57E),
    green: Color(0xFF4FBF8B),
    chipNeutral: Color(0xFF2C2421),
    toggleThumb: Color(0xFFDA6E62),
    toggleThumbText: Color(0xFF16110F),
  );

  @override
  AppColors copyWith({
    Color? bg,
    Color? surface,
    Color? hover,
    Color? text,
    Color? textSub,
    Color? border,
    Color? primary,
    Color? onPrimary,
    Color? primaryText,
    Color? primarySoft,
    Color? fill,
    Color? onFill,
    Color? portrait,
    Color? codePlate,
    Color? brown,
    Color? green,
    Color? chipNeutral,
    Color? toggleThumb,
    Color? toggleThumbText,
  }) => AppColors(
    bg: bg ?? this.bg,
    surface: surface ?? this.surface,
    hover: hover ?? this.hover,
    text: text ?? this.text,
    textSub: textSub ?? this.textSub,
    border: border ?? this.border,
    primary: primary ?? this.primary,
    onPrimary: onPrimary ?? this.onPrimary,
    primaryText: primaryText ?? this.primaryText,
    primarySoft: primarySoft ?? this.primarySoft,
    fill: fill ?? this.fill,
    onFill: onFill ?? this.onFill,
    portrait: portrait ?? this.portrait,
    codePlate: codePlate ?? this.codePlate,
    brown: brown ?? this.brown,
    green: green ?? this.green,
    chipNeutral: chipNeutral ?? this.chipNeutral,
    toggleThumb: toggleThumb ?? this.toggleThumb,
    toggleThumbText: toggleThumbText ?? this.toggleThumbText,
  );

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      bg: mix(bg, other.bg),
      surface: mix(surface, other.surface),
      hover: mix(hover, other.hover),
      text: mix(text, other.text),
      textSub: mix(textSub, other.textSub),
      border: mix(border, other.border),
      primary: mix(primary, other.primary),
      onPrimary: mix(onPrimary, other.onPrimary),
      primaryText: mix(primaryText, other.primaryText),
      primarySoft: mix(primarySoft, other.primarySoft),
      fill: mix(fill, other.fill),
      onFill: mix(onFill, other.onFill),
      portrait: mix(portrait, other.portrait),
      codePlate: mix(codePlate, other.codePlate),
      brown: mix(brown, other.brown),
      green: mix(green, other.green),
      chipNeutral: mix(chipNeutral, other.chipNeutral),
      toggleThumb: mix(toggleThumb, other.toggleThumb),
      toggleThumbText: mix(toggleThumbText, other.toggleThumbText),
    );
  }
}

extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
