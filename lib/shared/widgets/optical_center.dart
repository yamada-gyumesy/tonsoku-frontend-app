import 'package:flutter/material.dart';

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

  /// web の `-0.04em`。
  static const ratio = -0.04;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, fontSize * ratio),
      child: child,
    );
  }
}
