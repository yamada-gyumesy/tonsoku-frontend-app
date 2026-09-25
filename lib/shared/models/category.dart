import 'package:freezed_annotation/freezed_annotation.dart';

part 'category.freezed.dart';
part 'category.g.dart';

/// 記事カテゴリ。`categories.json` の各要素。
///
/// **表示名は配信データが多言語化済みで届く**ので、受け取った `label` を
/// そのまま出す。アプリ側で訳を持たない。
@freezed
abstract class Category with _$Category {
  const factory Category({
    required String slug,
    required String label,
    @Default('') String description,
  }) = _Category;

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);
}
