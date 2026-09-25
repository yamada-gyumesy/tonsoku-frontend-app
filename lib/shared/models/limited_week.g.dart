// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'limited_week.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LimitedWeeks _$LimitedWeeksFromJson(Map<String, dynamic> json) =>
    _LimitedWeeks(
      weeks:
          (json['weeks'] as List<dynamic>?)
              ?.map((e) => LimitedWeek.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <LimitedWeek>[],
    );

Map<String, dynamic> _$LimitedWeeksToJson(_LimitedWeeks instance) =>
    <String, dynamic>{'weeks': instance.weeks};

_LimitedWeek _$LimitedWeekFromJson(Map<String, dynamic> json) => _LimitedWeek(
  weekStart: json['week_start'] as String,
  weekEnd: json['week_end'] as String,
  status: json['status'] as String,
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => LimitedWeekItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <LimitedWeekItem>[],
);

Map<String, dynamic> _$LimitedWeekToJson(_LimitedWeek instance) =>
    <String, dynamic>{
      'week_start': instance.weekStart,
      'week_end': instance.weekEnd,
      'status': instance.status,
      'items': instance.items,
    };

_LimitedWeekItem _$LimitedWeekItemFromJson(Map<String, dynamic> json) =>
    _LimitedWeekItem(
      cmsId: json['cms_id'] as String,
      name: json['name'] as String,
      imageUrl: json['image_url'] as String? ?? '',
      articleSlug: json['article_slug'] as String?,
      shopCount: (json['shop_count'] as num?)?.toInt() ?? 0,
      shopsLive: (json['shops_live'] as num?)?.toInt() ?? 0,
      shopsEnded: (json['shops_ended'] as num?)?.toInt() ?? 0,
      endedAt: json['ended_at'] as String?,
    );

Map<String, dynamic> _$LimitedWeekItemToJson(_LimitedWeekItem instance) =>
    <String, dynamic>{
      'cms_id': instance.cmsId,
      'name': instance.name,
      'image_url': instance.imageUrl,
      'article_slug': instance.articleSlug,
      'shop_count': instance.shopCount,
      'shops_live': instance.shopsLive,
      'shops_ended': instance.shopsEnded,
      'ended_at': instance.endedAt,
    };
