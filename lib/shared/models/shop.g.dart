// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shop.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Shop _$ShopFromJson(Map<String, dynamic> json) => _Shop(
  code: json['code'] as String,
  name: json['name'] as String?,
  nameRoman: json['name_roman'] as String?,
  lat: (json['lat'] as num).toDouble(),
  lon: (json['lon'] as num).toDouble(),
  closingDate: json['closing_date'] as String?,
  openingDate: json['opening_date'] as String?,
  brands:
      (json['brands'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  address: json['address'] as String?,
  businessHours: json['business_hours'] as String?,
  phone: json['phone'] as String?,
  tempClosed: json['temp_closed'] == null
      ? null
      : TempClosed.fromJson(json['temp_closed'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ShopToJson(_Shop instance) => <String, dynamic>{
  'code': instance.code,
  'name': instance.name,
  'name_roman': instance.nameRoman,
  'lat': instance.lat,
  'lon': instance.lon,
  'closing_date': instance.closingDate,
  'opening_date': instance.openingDate,
  'brands': instance.brands,
  'address': instance.address,
  'business_hours': instance.businessHours,
  'phone': instance.phone,
  'temp_closed': instance.tempClosed,
};

_TempClosed _$TempClosedFromJson(Map<String, dynamic> json) => _TempClosed(
  startDate: json['start_date'] as String,
  endDate: json['end_date'] as String?,
);

Map<String, dynamic> _$TempClosedToJson(_TempClosed instance) =>
    <String, dynamic>{
      'start_date': instance.startDate,
      'end_date': instance.endDate,
    };
