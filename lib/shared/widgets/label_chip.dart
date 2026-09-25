import 'package:flutter/material.dart';

import 'package:tonsoku/core/theme/app_colors.dart';

/// カテゴリ・タグのチップ。web の `CaChip`。
///
/// - **カテゴリ**は `CategoryPalette` の `ink` を文字に、`tint` を地に使う
/// - **タグは色を持たない**（web の `models/tag.ts`）。地は `chipNeutral`、文字は
///   副テキスト（実測 ライト 5.28:1 / ダーク 5.56:1）。大分類のチップだけが色を
///   持つことで、並んだ時にどれがカテゴリなのかが読める
///
/// **gyumesy の `LabelChip`（色を不透明度で薄めて地にする）を写さないこと。**
/// とん速の地は焼いた不透明の値で、文字と対で決まっている。
class LabelChip extends StatelessWidget {
  const LabelChip._({required this.label, required this.categorySlug});

  /// カテゴリのチップ。
  const LabelChip.category({required String label, required String slug})
    : this._(label: label, categorySlug: slug);

  /// タグのチップ。
  const LabelChip.tag({required String label})
    : this._(label: label, categorySlug: null);

  final String label;

  /// null ならタグ。
  final String? categorySlug;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final slug = categorySlug;
    final category = slug == null ? null : CategoryPalette.of(slug, colors);

    return Container(
      // web の `px-1.5 py-0.5 rounded`
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: category?.tint ?? colors.chipNeutral,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        style: TextStyle(
          // web は 10px / font-medium（500）。太字にすると小さな面で潰れる
          fontSize: 10,
          height: 1.5,
          fontWeight: FontWeight.w500,
          color: category?.ink ?? colors.textSub,
        ),
      ),
    );
  }
}
