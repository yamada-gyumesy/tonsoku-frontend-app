// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'article_meta.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ArticleMeta _$ArticleMetaFromJson(Map<String, dynamic> json) => _ArticleMeta(
  slug: json['slug'] as String,
  title: json['title'] as String,
  categories:
      (json['categories'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  published: json['published'] as bool? ?? true,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
  description: json['description'] as String? ?? '',
  editorComment: json['editor_comment'] as String? ?? '',
  expression: json['expression'] as String?,
  thumbnail: json['thumbnail'] as String? ?? '',
  thumbnailSm: json['thumbnail_sm'] as String? ?? '',
  thumbnailSource: json['thumbnail_source'] as String? ?? '',
  sourceUrl: json['source_url'] as String? ?? '',
  triggerType: json['trigger_type'] as String? ?? '',
  relatedArticles:
      (json['related_articles'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  seriesKey: json['series_key'] as String?,
  successorSlug: json['successor_slug'] as String?,
);

Map<String, dynamic> _$ArticleMetaToJson(_ArticleMeta instance) =>
    <String, dynamic>{
      'slug': instance.slug,
      'title': instance.title,
      'categories': instance.categories,
      'tags': instance.tags,
      'published': instance.published,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'description': instance.description,
      'editor_comment': instance.editorComment,
      'expression': instance.expression,
      'thumbnail': instance.thumbnail,
      'thumbnail_sm': instance.thumbnailSm,
      'thumbnail_source': instance.thumbnailSource,
      'source_url': instance.sourceUrl,
      'trigger_type': instance.triggerType,
      'related_articles': instance.relatedArticles,
      'series_key': instance.seriesKey,
      'successor_slug': instance.successorSlug,
    };
