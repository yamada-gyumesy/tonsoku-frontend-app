// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ranking.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RankingPayload _$RankingPayloadFromJson(Map<String, dynamic> json) =>
    _RankingPayload(
      computedAt: json['computed_at'] as String? ?? '',
      windows:
          (json['windows'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
              k,
              RankingWindowData.fromJson(e as Map<String, dynamic>),
            ),
          ) ??
          const <String, RankingWindowData>{},
    );

Map<String, dynamic> _$RankingPayloadToJson(_RankingPayload instance) =>
    <String, dynamic>{
      'computed_at': instance.computedAt,
      'windows': instance.windows,
    };

_RankingWindowData _$RankingWindowDataFromJson(Map<String, dynamic> json) =>
    _RankingWindowData(
      start: json['start'] as String? ?? '',
      end: json['end'] as String? ?? '',
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => RankingItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <RankingItem>[],
    );

Map<String, dynamic> _$RankingWindowDataToJson(_RankingWindowData instance) =>
    <String, dynamic>{
      'start': instance.start,
      'end': instance.end,
      'items': instance.items,
    };

_RankingItem _$RankingItemFromJson(Map<String, dynamic> json) => _RankingItem(
  rank: (json['rank'] as num).toInt(),
  slug: json['slug'] as String,
);

Map<String, dynamic> _$RankingItemToJson(_RankingItem instance) =>
    <String, dynamic>{'rank': instance.rank, 'slug': instance.slug};
