// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'limited_menu.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LimitedMenu _$LimitedMenuFromJson(Map<String, dynamic> json) => _LimitedMenu(
  campaignId: json['campaign_id'] as String,
  name: json['name'] as String,
  startDate: json['start_date'] as String?,
  shops:
      (json['shops'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  soldOutShops:
      (json['sold_out_shops'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  endedShops:
      (json['ended_shops'] as List<dynamic>?)
          ?.map((e) => EndedShop.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <EndedShop>[],
  endedAt: json['ended_at'] as String?,
  articleSlug: json['article_slug'] as String?,
  thumbnailUrl: json['thumbnail_url'] as String?,
  imageUrl: json['image_url'] as String?,
);

Map<String, dynamic> _$LimitedMenuToJson(_LimitedMenu instance) =>
    <String, dynamic>{
      'campaign_id': instance.campaignId,
      'name': instance.name,
      'start_date': instance.startDate,
      'shops': instance.shops,
      'sold_out_shops': instance.soldOutShops,
      'ended_shops': instance.endedShops,
      'ended_at': instance.endedAt,
      'article_slug': instance.articleSlug,
      'thumbnail_url': instance.thumbnailUrl,
      'image_url': instance.imageUrl,
    };

_EndedShop _$EndedShopFromJson(Map<String, dynamic> json) => _EndedShop(
  code: json['code'] as String,
  endedAt: json['ended_at'] as String,
);

Map<String, dynamic> _$EndedShopToJson(_EndedShop instance) =>
    <String, dynamic>{'code': instance.code, 'ended_at': instance.endedAt};
