import 'package:freezed_annotation/freezed_annotation.dart';

part 'tag.freezed.dart';
part 'tag.g.dart';

/// 記事タグ。`tags.json` の各要素。
///
/// カテゴリと同じく**表示名は配信データが多言語化済みで届く**ので、`label` を
/// そのまま出す。アプリ側で訳を持たない。
@freezed
abstract class Tag with _$Tag {
  const factory Tag({required String slug, required String label}) = _Tag;

  factory Tag.fromJson(Map<String, dynamic> json) => _$TagFromJson(json);
}
