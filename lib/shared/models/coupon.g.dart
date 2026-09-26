// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coupon.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Coupon _$CouponFromJson(Map<String, dynamic> json) => _Coupon(
  generatedAt: json['generated_at'] as String,
  ranks:
      (json['ranks'] as List<dynamic>?)
          ?.map((e) => CouponRank.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <CouponRank>[],
  offers:
      (json['offers'] as List<dynamic>?)
          ?.map((e) => CouponOffer.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <CouponOffer>[],
  upcoming:
      (json['upcoming'] as List<dynamic>?)
          ?.map((e) => CouponOffer.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <CouponOffer>[],
  bestDeal: json['best_deal'] == null
      ? null
      : CouponBestDeal.fromJson(json['best_deal'] as Map<String, dynamic>),
);

Map<String, dynamic> _$CouponToJson(_Coupon instance) => <String, dynamic>{
  'generated_at': instance.generatedAt,
  'ranks': instance.ranks,
  'offers': instance.offers,
  'upcoming': instance.upcoming,
  'best_deal': instance.bestDeal,
};

_CouponRank _$CouponRankFromJson(Map<String, dynamic> json) => _CouponRank(
  id: json['id'] as String,
  order: (json['order'] as num).toInt(),
  rates:
      (json['rates'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ) ??
      const <String, double>{},
);

Map<String, dynamic> _$CouponRankToJson(_CouponRank instance) =>
    <String, dynamic>{
      'id': instance.id,
      'order': instance.order,
      'rates': instance.rates,
    };

_CouponOffer _$CouponOfferFromJson(Map<String, dynamic> json) => _CouponOffer(
  id: json['id'] as String,
  brand: json['brand'] as String?,
  title: json['title'] as String?,
  ratePercent: (json['rate_percent'] as num?)?.toDouble(),
  rateMultiplier: (json['rate_multiplier'] as num?)?.toDouble(),
  pointAmount: (json['point_amount'] as num?)?.toInt(),
  discountYen: (json['discount_yen'] as num?)?.toInt(),
  discountMaxYen: (json['discount_max_yen'] as num?)?.toInt(),
  capYen: (json['cap_yen'] as num?)?.toInt(),
  minSpendYen: (json['min_spend_yen'] as num?)?.toInt(),
  tiers:
      (json['tiers'] as List<dynamic>?)
          ?.map((e) => CouponTier.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <CouponTier>[],
  requiresEntry: json['requires_entry'] as bool? ?? false,
  benefitType: json['benefit_type'] as String?,
  channels:
      (json['channels'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  howToGet: json['how_to_get'] as String?,
  startDate: json['start_date'] as String,
  endDate: json['end_date'] as String?,
  endAt: json['end_at'] as String?,
  timeWindow: json['time_window'] as String?,
  links:
      (json['links'] as List<dynamic>?)
          ?.map((e) => CouponLink.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <CouponLink>[],
  imageUrl: json['image_url'] as String?,
  qrImageUrl: json['qr_image_url'] as String?,
  sourceUrl: json['source_url'] as String?,
  sourceLabel: json['source_label'] as String?,
  notes:
      (json['notes'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  articleSlug: json['article_slug'] as String?,
);

Map<String, dynamic> _$CouponOfferToJson(_CouponOffer instance) =>
    <String, dynamic>{
      'id': instance.id,
      'brand': instance.brand,
      'title': instance.title,
      'rate_percent': instance.ratePercent,
      'rate_multiplier': instance.rateMultiplier,
      'point_amount': instance.pointAmount,
      'discount_yen': instance.discountYen,
      'discount_max_yen': instance.discountMaxYen,
      'cap_yen': instance.capYen,
      'min_spend_yen': instance.minSpendYen,
      'tiers': instance.tiers,
      'requires_entry': instance.requiresEntry,
      'benefit_type': instance.benefitType,
      'channels': instance.channels,
      'how_to_get': instance.howToGet,
      'start_date': instance.startDate,
      'end_date': instance.endDate,
      'end_at': instance.endAt,
      'time_window': instance.timeWindow,
      'links': instance.links,
      'image_url': instance.imageUrl,
      'qr_image_url': instance.qrImageUrl,
      'source_url': instance.sourceUrl,
      'source_label': instance.sourceLabel,
      'notes': instance.notes,
      'article_slug': instance.articleSlug,
    };

_CouponTier _$CouponTierFromJson(Map<String, dynamic> json) => _CouponTier(
  ratePercent: (json['rate_percent'] as num).toDouble(),
  minSpendYen: (json['min_spend_yen'] as num).toInt(),
);

Map<String, dynamic> _$CouponTierToJson(_CouponTier instance) =>
    <String, dynamic>{
      'rate_percent': instance.ratePercent,
      'min_spend_yen': instance.minSpendYen,
    };

_CouponLink _$CouponLinkFromJson(Map<String, dynamic> json) => _CouponLink(
  url: json['url'] as String,
  kind: json['kind'] as String,
  ratePercent: (json['rate_percent'] as num?)?.toDouble(),
);

Map<String, dynamic> _$CouponLinkToJson(_CouponLink instance) =>
    <String, dynamic>{
      'url': instance.url,
      'kind': instance.kind,
      'rate_percent': instance.ratePercent,
    };

_CouponBestDeal _$CouponBestDealFromJson(Map<String, dynamic> json) =>
    _CouponBestDeal(
      channel: json['channel'] as String,
      rank: json['rank'] as String,
      parts:
          (json['parts'] as List<dynamic>?)
              ?.map(
                (e) => CouponBestDealPart.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <CouponBestDealPart>[],
      totalPercent: (json['total_percent'] as num).toDouble(),
      capYen: (json['cap_yen'] as num?)?.toInt(),
      targetSpendYen: (json['target_spend_yen'] as num?)?.toInt(),
      patterns:
          (json['patterns'] as List<dynamic>?)
              ?.map((e) => CouponPattern.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <CouponPattern>[],
    );

Map<String, dynamic> _$CouponBestDealToJson(_CouponBestDeal instance) =>
    <String, dynamic>{
      'channel': instance.channel,
      'rank': instance.rank,
      'parts': instance.parts,
      'total_percent': instance.totalPercent,
      'cap_yen': instance.capYen,
      'target_spend_yen': instance.targetSpendYen,
      'patterns': instance.patterns,
    };

_CouponBestDealPart _$CouponBestDealPartFromJson(Map<String, dynamic> json) =>
    _CouponBestDealPart(
      offerId: json['offer_id'] as String?,
      brand: json['brand'] as String?,
      percent: (json['percent'] as num).toDouble(),
    );

Map<String, dynamic> _$CouponBestDealPartToJson(_CouponBestDealPart instance) =>
    <String, dynamic>{
      'offer_id': instance.offerId,
      'brand': instance.brand,
      'percent': instance.percent,
    };

_CouponPattern _$CouponPatternFromJson(Map<String, dynamic> json) =>
    _CouponPattern(
      items:
          (json['items'] as List<dynamic>?)
              ?.map(
                (e) => CouponPatternItem.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <CouponPatternItem>[],
      totalYen: (json['total_yen'] as num).toInt(),
      backYen: (json['back_yen'] as num?)?.toInt(),
      netYen: (json['net_yen'] as num?)?.toInt(),
    );

Map<String, dynamic> _$CouponPatternToJson(_CouponPattern instance) =>
    <String, dynamic>{
      'items': instance.items,
      'total_yen': instance.totalYen,
      'back_yen': instance.backYen,
      'net_yen': instance.netYen,
    };

_CouponPatternItem _$CouponPatternItemFromJson(Map<String, dynamic> json) =>
    _CouponPatternItem(
      name: json['name'] as String?,
      priceYen: (json['price_yen'] as num?)?.toInt(),
      articleSlug: json['article_slug'] as String?,
      thumbnail: json['thumbnail'] as String? ?? '',
    );

Map<String, dynamic> _$CouponPatternItemToJson(_CouponPatternItem instance) =>
    <String, dynamic>{
      'name': instance.name,
      'price_yen': instance.priceYen,
      'article_slug': instance.articleSlug,
      'thumbnail': instance.thumbnail,
    };
