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

/// カテゴリの色。**チップとタブと線は同じカテゴリから色を引く**（web の
/// `--color-brand-cat-*` / `--color-brand-tab-*` と `models/category.ts`）。
///
/// - [ink] … チップの文字・カレンダーの線と丸ポチ（地の上に置く文字用。
///   ダークでは明るい値になる）
/// - [tint] … チップの地（[ink] を面に 8% 混ぜて焼いたもの。`color-mix` で
///   その場で作らない理由は web の `main.css`）
/// - [tab] … タブの塗り（白文字を載せる）
///
/// **[ink] を塗りに使わないこと。** ダークで白文字が 2.4〜3.3:1 まで落ちる
/// （web が実際に踏んでいる）。だから塗りは [tab] で別に持つ。
///
/// 実測コントラスト（web の実測）: チップの文字と地 ライト 4.56〜8.85 /
/// ダーク 4.91〜6.53、タブの白文字 ライト 5.05〜15.57 / ダーク 4.72〜10.94。
/// **色を変えたら両テーマで計算し直すこと。**
@immutable
class CategoryColor {
  const CategoryColor({
    required this.ink,
    required this.tint,
    required this.tab,
  });

  final Color ink;
  final Color tint;
  final Color tab;
}

/// カテゴリ slug ごとの色。**名前は slug に対応させる**（web が index 割り当てを
/// やめた理由: どの色がどのカテゴリかが追えず、色を足した時に対応が黙ってずれる）。
///
/// **松のやの色だけで組む**（墨・赤・灰・緑・黄土）。青系を入れない。
///
/// **ラベルは配信の `categories.json` が正で、色だけがこちらの責任。**
abstract final class CategoryPalette {
  static const _light = <String, CategoryColor>{
    'menu': CategoryColor(
      ink: Color(0xFFA7232A),
      tint: Color(0xFFF8EDEE),
      tab: Color(0xFFA7232A),
    ),
    'official': CategoryColor(
      ink: Color(0xFF4A403A),
      tint: Color(0xFFF1F0EF),
      tab: Color(0xFF7A6A60),
    ),
    'store': CategoryColor(
      ink: Color(0xFF046240),
      tint: Color(0xFFEBF2F0),
      tab: Color(0xFF046240),
    ),
    'campaign': CategoryColor(
      ink: Color(0xFF8A6A1F),
      tint: Color(0xFFF6F3ED),
      tab: Color(0xFF8A6A1F),
    ),
  };

  static const _dark = <String, CategoryColor>{
    'menu': CategoryColor(
      ink: Color(0xFFDA6E62),
      tint: Color(0xFF311B19),
      tab: Color(0xFFB62A31),
    ),
    'official': CategoryColor(
      ink: Color(0xFFB0A69E),
      tint: Color(0xFF272320),
      tab: Color(0xFF7E7168),
    ),
    'store': CategoryColor(
      ink: Color(0xFF4FB58C),
      tint: Color(0xFF1E231C),
      tab: Color(0xFF067A50),
    ),
    'campaign': CategoryColor(
      ink: Color(0xFFC7A44E),
      tint: Color(0xFF2E2418),
      tab: Color(0xFF8A6A1F),
    ),
  };

  /// 先頭の「フィード」タブと、色の決まっていない slug のタブの塗り
  /// （web の `--color-brand-tab-feed`）。
  static const _feedTabLight = Color(0xFF2E211A);
  static const _feedTabDark = Color(0xFF4A3930);

  /// **`categories.json` に載っているが色を知らない slug も出す。** 地は中立色
  /// （web と同じ。落とすと、配信されているのにどこからも辿れないカテゴリができる）。
  ///
  /// - チップ … **`official` と同じ組**（web の `FALLBACK_COLOR`。新しい色を増やさない）
  /// - タブ … フィードと同じ塗り（web の `TAB_FILL_FALLBACK`）
  static CategoryColor of(String slug, AppColors colors) {
    final dark = colors.isDark;
    final known = (dark ? _dark : _light)[slug];
    if (known != null) return known;
    final fallback = (dark ? _dark : _light)['official']!;
    return CategoryColor(
      ink: fallback.ink,
      tint: fallback.tint,
      tab: dark ? _feedTabDark : _feedTabLight,
    );
  }

  /// カレンダーの線・絞り込みの丸ポチの色。**チップの [CategoryColor.ink] と同じ色**
  /// （同じカテゴリが 2 つの色を持たないように）。**知らない slug は副テキストの色**
  /// （web の `CATEGORY_LINE_FALLBACK`。チップの中立色とは別）。
  static Color lineOf(String slug, AppColors colors) =>
      (colors.isDark ? _dark : _light)[slug]?.ink ?? colors.textSub;
}

/// マップの背景地図の色。**web に地図は無い**ので、ここだけはアプリで決めた値。
///
/// ## 決め方
///
/// - **陸は紙面の地（`bg` の生成り／ダークは面）に寄せる。** 地図が主役ではなく、
///   上に載る店の印が主役なので、地図は紙面の続きに見えるくらい静かにする
/// - **水は青を使わない。** とん速の配色は松のやの色（墨・赤・灰・緑・黄土）だけで
///   組んでいて、青系を入れない（[CategoryPalette] と同じ方針）。**彩度をほぼ落とした
///   灰緑**にして、陸との差は明るさで付ける
/// - **道路・境界は罫線（`border`）の仲間。** 装飾なのでコントラスト要件は無いが、
///   店の印（非テキスト 3:1）より必ず弱くする
/// - **鉄道だけは一段濃い灰。** 駅名と並べて場所の見当を付ける手がかりなので、
///   道路より目立たせる
/// - **地名の文字は副テキスト（`textSub`）**。縁取りを陸の色で入れるので、道路や
///   境界の上でも 4.5:1 を保つ（地に対して ライト 5.52:1 / ダーク 6.27:1）
///
/// **色を変えたら両テーマで店の印の見え方を確かめること**（印は陸の上に載る）。
@immutable
class MapPalette {
  const MapPalette({
    required this.land,
    required this.water,
    required this.boundaryCountry,
    required this.boundaryRegion,
    required this.highway,
    required this.majorRoad,
    required this.rail,
    required this.label,
    required this.labelHalo,
    required this.shop,
    required this.annexMatsuya,
    required this.me,
  });

  final Color land;

  /// 海（陸の外側）と湖・川。
  final Color water;
  final Color boundaryCountry;

  /// 都道府県の境。
  final Color boundaryRegion;
  final Color highway;
  final Color majorRoad;
  final Color rail;

  /// 地名・駅名の文字。
  final Color label;

  /// 地名・駅名の縁取り（陸と同じ色）。
  final Color labelHalo;

  /// **松のや専門店の点**（店舗限定の印が無い時。併設の店は [annexMatsuya] /
  /// `AppColors.brown`。`ShopDot`）。緑（ユーザーの指定）。
  ///
  /// 茶（`AppColors.brown`）は地図の地・道路と同じ系統の色で馴染みすぎ、
  /// 黄土色も見分けにくかった（どちらもユーザーの指摘）。緑は地図のどの色とも
  /// 系統が違い、店舗限定の赤とも取り違えない。地との比（計算値。図形は 3:1 以上）:
  ///
  /// | | 陸 | 水 |
  /// |---|---|---|
  /// | ライト `#1E8A4C` | 4.10 | 3.37 |
  /// | ダーク `#3DBE7A` | 7.22 | 7.68 |
  final Color shop;

  /// 松屋併設の店の点。黄（ユーザーの指定。専門店は [shop] の緑、マイカリー
  /// 食堂併設は `AppColors.brown` の茶）。
  /// ライトは地との比が 3:1 に届く濃い黄（`#B58500` 陸 3.11。明るい黄は 2.3 で
  /// 地に溶けた）、ダークは `#F2C94C`（10.8）。
  final Color annexMatsuya;

  /// **現在地の印**と向きの扇。地図アプリで定番の青（ユーザーの判断。店の緑・
  /// 店舗限定の赤と取り違えない）。地との比（計算値）: ライト `#1A73E8` 4.22 /
  /// ダーク `#4C8DF6` 5.26。
  final Color me;

  static const light = MapPalette(
    land: Color(0xFFFAF7F3), // bg と同じ
    water: Color(0xFFDDE3E1),
    boundaryCountry: Color(0xFFB5A99F),
    boundaryRegion: Color(0xFFCDC2B6),
    highway: Color(0xFFE2D2C2),
    majorRoad: Color(0xFFEAE1D7),
    rail: Color(0xFFA3968D),
    label: Color(0xFF6E625B), // textSub
    labelHalo: Color(0xFFFAF7F3),
    shop: Color(0xFF1E8A4C),
    annexMatsuya: Color(0xFFB58500),
    me: Color(0xFF1A73E8),
  );

  static const dark = MapPalette(
    land: Color(0xFF211A17), // surface と同じ
    water: Color(0xFF121615),
    boundaryCountry: Color(0xFF5A4E47),
    boundaryRegion: Color(0xFF41362F),
    highway: Color(0xFF41352E),
    majorRoad: Color(0xFF342A25),
    rail: Color(0xFF6B5E56),
    label: Color(0xFFA79A92), // textSub
    labelHalo: Color(0xFF211A17),
    shop: Color(0xFF3DBE7A),
    annexMatsuya: Color(0xFFF2C94C),
    me: Color(0xFF4C8DF6),
  );

  static MapPalette of(AppColors colors) => colors.isDark ? dark : light;
}

extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
