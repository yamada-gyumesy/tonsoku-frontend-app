// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CalendarEvent _$CalendarEventFromJson(Map<String, dynamic> json) =>
    _CalendarEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      startDate: json['start_date'] as String,
      endDate: json['end_date'] as String?,
      ongoing: json['ongoing'] as bool? ?? false,
      preview: json['preview'] as bool? ?? false,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const <String>[],
      articleSlug: json['article_slug'] as String?,
      sourceUrl: json['source_url'] as String?,
      sourceLabel: json['source_label'] as String?,
    );

Map<String, dynamic> _$CalendarEventToJson(_CalendarEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'category': instance.category,
      'start_date': instance.startDate,
      'end_date': instance.endDate,
      'ongoing': instance.ongoing,
      'preview': instance.preview,
      'tags': instance.tags,
      'article_slug': instance.articleSlug,
      'source_url': instance.sourceUrl,
      'source_label': instance.sourceLabel,
    };

_CalendarPayload _$CalendarPayloadFromJson(Map<String, dynamic> json) =>
    _CalendarPayload(
      generatedAt: json['generated_at'] as String? ?? '',
      events:
          (json['events'] as List<dynamic>?)
              ?.map((e) => CalendarEvent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <CalendarEvent>[],
    );

Map<String, dynamic> _$CalendarPayloadToJson(_CalendarPayload instance) =>
    <String, dynamic>{
      'generated_at': instance.generatedAt,
      'events': instance.events,
    };
