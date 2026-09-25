import 'package:flutter/material.dart';

import 'package:tonsoku/core/theme/app_theme.dart';

/// 字面（インク）の中心を器の中心に寄せる。web の `optical-center`（とん速の web も同じ値。gyumesy-frontend-app から写した）
/// （`main.css` の `@utility optical-center { translate: 0 -0.04em }`）。
///
/// **アイコンと横に並べた文字だけが沈んで見えるのを直す。** フォントの
/// ascent / descent は非対称なので、行ボックスの中央に揃えても字面はわずかに
/// 下に沈む（web の実測で Noto Sans JP・15px で 0.58px、欧文の大文字中心で
/// 見ると 1.2px ほど）。単体では気づかないが、**字面が中央ちょうどに来る
/// アイコンと横に並べると文字だけ下がって見える**。
///
/// **行の高さを変えても直らない。** 半レディングは上下対称に入るので、器の
/// 高さが変わっても字面と中心の差は一定。ずらす以外に手が無い。
///
/// **レイアウトは動かさない**（`Transform` は描画だけずらす）ので、行の高さや
/// 当たり判定は変わらない。
class OpticalCenter extends StatelessWidget {
  const OpticalCenter({required this.fontSize, required this.child, super.key});

  /// 中身の文字サイズ。ずらす量はこれに比例する（web と同じ `em` 指定）。
  final double fontSize;

  final Widget child;

  /// web の `-0.04em`（Noto Sans JP で測った値。英語・中国語はこれ）。
  static const ratio = -0.04;

  /// **日本語（Klee One）の量。** Klee One は Noto Sans JP より字面が沈む
  /// （行ボックスの中の字の位置が低い）ので、`-0.04em` では足りない。
  ///
  /// 実測（iPhone 17 Pro、15px、メニューの行。字面と記号の縦の中心の差）:
  ///
  /// | 量 | 「利用規約」と外へ出る記号 | 「とん速とは」と外へ出る記号 |
  /// |---|---|---|
  /// | `-0.04em` | 文字が 0.5pt 低い（記号が浮いて見えた。ユーザーの指摘） | ― |
  /// | `-0.08em` | ― | 文字が 0.33pt 高い（行き過ぎ） |
  /// | `-0.06em` | 0.17pt | 0.17pt |
  ///
  /// **字面の中心は字で揺れる**（かなと漢字で違う）ので、1 行だけで決めないこと。
  /// web は書体によらず `-0.04em` だが、**あちらの記号はアイコンの書体の字**で
  /// 文字と同じ行の中に座るので、この差が表に出ない。
  static const kleeRatio = -0.06;

  @override
  Widget build(BuildContext context) {
    // 効いている書体で量を変える（言語で書体が替わる。`AppTheme.fontFamilyFor`）
    final family =
        DefaultTextStyle.of(context).style.fontFamily ??
        Theme.of(context).textTheme.bodyMedium?.fontFamily;
    final r = family == AppTheme.jaFontFamily ? kleeRatio : ratio;
    return Transform.translate(offset: Offset(0, fontSize * r), child: child);
  }
}
