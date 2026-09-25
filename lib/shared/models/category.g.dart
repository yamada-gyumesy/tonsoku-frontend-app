// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Category _$CategoryFromJson(Map<String, dynamic> json) => _Category(
  slug: json['slug'] as String,
  label: json['label'] as String,
  description: json['description'] as String? ?? '',
);

Map<String, dynamic> _$CategoryToJson(_Category instance) => <String, dynamic>{
  'slug': instance.slug,
  'label': instance.label,
  'description': instance.description,
};
