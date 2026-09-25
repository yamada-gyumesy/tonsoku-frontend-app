// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shop.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Shop {

 String get code;/// 「松のや 西新宿店」のように**ブランド名から始まる**正式名。
 String get name;/// 店名のローマ字（`NISHISHINJUKU`）。**大文字だけで読みにくい**ので画面には
/// 出さない（牛めしレーダーは検索の照合に使っている）
@JsonKey(name: 'name_roman') String? get nameRoman; double get lat; double get lon;/// 閉店する（した）時刻。**意味は [openingDate] との前後で変わる**
/// （`lib/features/map/domain/shop_state.dart`）
@JsonKey(name: 'closing_date') String? get closingDate;/// 開店する（した）時刻。
@JsonKey(name: 'opening_date') String? get openingDate;/// 併設しているブランド（`matsuya` / `mycurry`）。**松のや自身
/// （`matsunoya`）が入ることもある**ので、併設として数えるのは
/// `lib/features/map/domain/shop_filter.dart` の [ShopBrand] に載っているものだけ
 List<String> get brands;/// 住所（Navitime）。
 String? get address;/// 営業時間。**Navitime の表記そのまま**（「月から土：5時から翌2時、…」）で、
/// 形が決まっていないので**組み替えずにそのまま出す**。
@JsonKey(name: 'business_hours') String? get businessHours; String? get phone;/// 一時閉店中、またはこれから一時閉店する期間。**カレンダーの「一時閉店」と
/// 同じ答え**。無ければ null
@JsonKey(name: 'temp_closed') TempClosed? get tempClosed;
/// Create a copy of Shop
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShopCopyWith<Shop> get copyWith => _$ShopCopyWithImpl<Shop>(this as Shop, _$identity);

  /// Serializes this Shop to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Shop&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.nameRoman, nameRoman) || other.nameRoman == nameRoman)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lon, lon) || other.lon == lon)&&(identical(other.closingDate, closingDate) || other.closingDate == closingDate)&&(identical(other.openingDate, openingDate) || other.openingDate == openingDate)&&const DeepCollectionEquality().equals(other.brands, brands)&&(identical(other.address, address) || other.address == address)&&(identical(other.businessHours, businessHours) || other.businessHours == businessHours)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.tempClosed, tempClosed) || other.tempClosed == tempClosed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,name,nameRoman,lat,lon,closingDate,openingDate,const DeepCollectionEquality().hash(brands),address,businessHours,phone,tempClosed);

@override
String toString() {
  return 'Shop(code: $code, name: $name, nameRoman: $nameRoman, lat: $lat, lon: $lon, closingDate: $closingDate, openingDate: $openingDate, brands: $brands, address: $address, businessHours: $businessHours, phone: $phone, tempClosed: $tempClosed)';
}


}

/// @nodoc
abstract mixin class $ShopCopyWith<$Res>  {
  factory $ShopCopyWith(Shop value, $Res Function(Shop) _then) = _$ShopCopyWithImpl;
@useResult
$Res call({
 String code, String name,@JsonKey(name: 'name_roman') String? nameRoman, double lat, double lon,@JsonKey(name: 'closing_date') String? closingDate,@JsonKey(name: 'opening_date') String? openingDate, List<String> brands, String? address,@JsonKey(name: 'business_hours') String? businessHours, String? phone,@JsonKey(name: 'temp_closed') TempClosed? tempClosed
});


$TempClosedCopyWith<$Res>? get tempClosed;

}
/// @nodoc
class _$ShopCopyWithImpl<$Res>
    implements $ShopCopyWith<$Res> {
  _$ShopCopyWithImpl(this._self, this._then);

  final Shop _self;
  final $Res Function(Shop) _then;

/// Create a copy of Shop
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? name = null,Object? nameRoman = freezed,Object? lat = null,Object? lon = null,Object? closingDate = freezed,Object? openingDate = freezed,Object? brands = null,Object? address = freezed,Object? businessHours = freezed,Object? phone = freezed,Object? tempClosed = freezed,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nameRoman: freezed == nameRoman ? _self.nameRoman : nameRoman // ignore: cast_nullable_to_non_nullable
as String?,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lon: null == lon ? _self.lon : lon // ignore: cast_nullable_to_non_nullable
as double,closingDate: freezed == closingDate ? _self.closingDate : closingDate // ignore: cast_nullable_to_non_nullable
as String?,openingDate: freezed == openingDate ? _self.openingDate : openingDate // ignore: cast_nullable_to_non_nullable
as String?,brands: null == brands ? _self.brands : brands // ignore: cast_nullable_to_non_nullable
as List<String>,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,businessHours: freezed == businessHours ? _self.businessHours : businessHours // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,tempClosed: freezed == tempClosed ? _self.tempClosed : tempClosed // ignore: cast_nullable_to_non_nullable
as TempClosed?,
  ));
}
/// Create a copy of Shop
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TempClosedCopyWith<$Res>? get tempClosed {
    if (_self.tempClosed == null) {
    return null;
  }

  return $TempClosedCopyWith<$Res>(_self.tempClosed!, (value) {
    return _then(_self.copyWith(tempClosed: value));
  });
}
}


/// Adds pattern-matching-related methods to [Shop].
extension ShopPatterns on Shop {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Shop value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Shop() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Shop value)  $default,){
final _that = this;
switch (_that) {
case _Shop():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Shop value)?  $default,){
final _that = this;
switch (_that) {
case _Shop() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  String name, @JsonKey(name: 'name_roman')  String? nameRoman,  double lat,  double lon, @JsonKey(name: 'closing_date')  String? closingDate, @JsonKey(name: 'opening_date')  String? openingDate,  List<String> brands,  String? address, @JsonKey(name: 'business_hours')  String? businessHours,  String? phone, @JsonKey(name: 'temp_closed')  TempClosed? tempClosed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Shop() when $default != null:
return $default(_that.code,_that.name,_that.nameRoman,_that.lat,_that.lon,_that.closingDate,_that.openingDate,_that.brands,_that.address,_that.businessHours,_that.phone,_that.tempClosed);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  String name, @JsonKey(name: 'name_roman')  String? nameRoman,  double lat,  double lon, @JsonKey(name: 'closing_date')  String? closingDate, @JsonKey(name: 'opening_date')  String? openingDate,  List<String> brands,  String? address, @JsonKey(name: 'business_hours')  String? businessHours,  String? phone, @JsonKey(name: 'temp_closed')  TempClosed? tempClosed)  $default,) {final _that = this;
switch (_that) {
case _Shop():
return $default(_that.code,_that.name,_that.nameRoman,_that.lat,_that.lon,_that.closingDate,_that.openingDate,_that.brands,_that.address,_that.businessHours,_that.phone,_that.tempClosed);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  String name, @JsonKey(name: 'name_roman')  String? nameRoman,  double lat,  double lon, @JsonKey(name: 'closing_date')  String? closingDate, @JsonKey(name: 'opening_date')  String? openingDate,  List<String> brands,  String? address, @JsonKey(name: 'business_hours')  String? businessHours,  String? phone, @JsonKey(name: 'temp_closed')  TempClosed? tempClosed)?  $default,) {final _that = this;
switch (_that) {
case _Shop() when $default != null:
return $default(_that.code,_that.name,_that.nameRoman,_that.lat,_that.lon,_that.closingDate,_that.openingDate,_that.brands,_that.address,_that.businessHours,_that.phone,_that.tempClosed);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Shop implements Shop {
  const _Shop({required this.code, required this.name, @JsonKey(name: 'name_roman') this.nameRoman, required this.lat, required this.lon, @JsonKey(name: 'closing_date') this.closingDate, @JsonKey(name: 'opening_date') this.openingDate, final  List<String> brands = const <String>[], this.address, @JsonKey(name: 'business_hours') this.businessHours, this.phone, @JsonKey(name: 'temp_closed') this.tempClosed}): _brands = brands;
  factory _Shop.fromJson(Map<String, dynamic> json) => _$ShopFromJson(json);

@override final  String code;
/// 「松のや 西新宿店」のように**ブランド名から始まる**正式名。
@override final  String name;
/// 店名のローマ字（`NISHISHINJUKU`）。**大文字だけで読みにくい**ので画面には
/// 出さない（牛めしレーダーは検索の照合に使っている）
@override@JsonKey(name: 'name_roman') final  String? nameRoman;
@override final  double lat;
@override final  double lon;
/// 閉店する（した）時刻。**意味は [openingDate] との前後で変わる**
/// （`lib/features/map/domain/shop_state.dart`）
@override@JsonKey(name: 'closing_date') final  String? closingDate;
/// 開店する（した）時刻。
@override@JsonKey(name: 'opening_date') final  String? openingDate;
/// 併設しているブランド（`matsuya` / `mycurry`）。**松のや自身
/// （`matsunoya`）が入ることもある**ので、併設として数えるのは
/// `lib/features/map/domain/shop_filter.dart` の [ShopBrand] に載っているものだけ
 final  List<String> _brands;
/// 併設しているブランド（`matsuya` / `mycurry`）。**松のや自身
/// （`matsunoya`）が入ることもある**ので、併設として数えるのは
/// `lib/features/map/domain/shop_filter.dart` の [ShopBrand] に載っているものだけ
@override@JsonKey() List<String> get brands {
  if (_brands is EqualUnmodifiableListView) return _brands;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_brands);
}

/// 住所（Navitime）。
@override final  String? address;
/// 営業時間。**Navitime の表記そのまま**（「月から土：5時から翌2時、…」）で、
/// 形が決まっていないので**組み替えずにそのまま出す**。
@override@JsonKey(name: 'business_hours') final  String? businessHours;
@override final  String? phone;
/// 一時閉店中、またはこれから一時閉店する期間。**カレンダーの「一時閉店」と
/// 同じ答え**。無ければ null
@override@JsonKey(name: 'temp_closed') final  TempClosed? tempClosed;

/// Create a copy of Shop
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShopCopyWith<_Shop> get copyWith => __$ShopCopyWithImpl<_Shop>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShopToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Shop&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.nameRoman, nameRoman) || other.nameRoman == nameRoman)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lon, lon) || other.lon == lon)&&(identical(other.closingDate, closingDate) || other.closingDate == closingDate)&&(identical(other.openingDate, openingDate) || other.openingDate == openingDate)&&const DeepCollectionEquality().equals(other._brands, _brands)&&(identical(other.address, address) || other.address == address)&&(identical(other.businessHours, businessHours) || other.businessHours == businessHours)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.tempClosed, tempClosed) || other.tempClosed == tempClosed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,name,nameRoman,lat,lon,closingDate,openingDate,const DeepCollectionEquality().hash(_brands),address,businessHours,phone,tempClosed);

@override
String toString() {
  return 'Shop(code: $code, name: $name, nameRoman: $nameRoman, lat: $lat, lon: $lon, closingDate: $closingDate, openingDate: $openingDate, brands: $brands, address: $address, businessHours: $businessHours, phone: $phone, tempClosed: $tempClosed)';
}


}

/// @nodoc
abstract mixin class _$ShopCopyWith<$Res> implements $ShopCopyWith<$Res> {
  factory _$ShopCopyWith(_Shop value, $Res Function(_Shop) _then) = __$ShopCopyWithImpl;
@override @useResult
$Res call({
 String code, String name,@JsonKey(name: 'name_roman') String? nameRoman, double lat, double lon,@JsonKey(name: 'closing_date') String? closingDate,@JsonKey(name: 'opening_date') String? openingDate, List<String> brands, String? address,@JsonKey(name: 'business_hours') String? businessHours, String? phone,@JsonKey(name: 'temp_closed') TempClosed? tempClosed
});


@override $TempClosedCopyWith<$Res>? get tempClosed;

}
/// @nodoc
class __$ShopCopyWithImpl<$Res>
    implements _$ShopCopyWith<$Res> {
  __$ShopCopyWithImpl(this._self, this._then);

  final _Shop _self;
  final $Res Function(_Shop) _then;

/// Create a copy of Shop
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? name = null,Object? nameRoman = freezed,Object? lat = null,Object? lon = null,Object? closingDate = freezed,Object? openingDate = freezed,Object? brands = null,Object? address = freezed,Object? businessHours = freezed,Object? phone = freezed,Object? tempClosed = freezed,}) {
  return _then(_Shop(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nameRoman: freezed == nameRoman ? _self.nameRoman : nameRoman // ignore: cast_nullable_to_non_nullable
as String?,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lon: null == lon ? _self.lon : lon // ignore: cast_nullable_to_non_nullable
as double,closingDate: freezed == closingDate ? _self.closingDate : closingDate // ignore: cast_nullable_to_non_nullable
as String?,openingDate: freezed == openingDate ? _self.openingDate : openingDate // ignore: cast_nullable_to_non_nullable
as String?,brands: null == brands ? _self._brands : brands // ignore: cast_nullable_to_non_nullable
as List<String>,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,businessHours: freezed == businessHours ? _self.businessHours : businessHours // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,tempClosed: freezed == tempClosed ? _self.tempClosed : tempClosed // ignore: cast_nullable_to_non_nullable
as TempClosed?,
  ));
}

/// Create a copy of Shop
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TempClosedCopyWith<$Res>? get tempClosed {
    if (_self.tempClosed == null) {
    return null;
  }

  return $TempClosedCopyWith<$Res>(_self.tempClosed!, (value) {
    return _then(_self.copyWith(tempClosed: value));
  });
}
}


/// @nodoc
mixin _$TempClosed {

@JsonKey(name: 'start_date') String get startDate;/// 再開日。**告知されていなければ null**（「再開日未定」）
@JsonKey(name: 'end_date') String? get endDate;
/// Create a copy of TempClosed
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TempClosedCopyWith<TempClosed> get copyWith => _$TempClosedCopyWithImpl<TempClosed>(this as TempClosed, _$identity);

  /// Serializes this TempClosed to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TempClosed&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,startDate,endDate);

@override
String toString() {
  return 'TempClosed(startDate: $startDate, endDate: $endDate)';
}


}

/// @nodoc
abstract mixin class $TempClosedCopyWith<$Res>  {
  factory $TempClosedCopyWith(TempClosed value, $Res Function(TempClosed) _then) = _$TempClosedCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'start_date') String startDate,@JsonKey(name: 'end_date') String? endDate
});




}
/// @nodoc
class _$TempClosedCopyWithImpl<$Res>
    implements $TempClosedCopyWith<$Res> {
  _$TempClosedCopyWithImpl(this._self, this._then);

  final TempClosed _self;
  final $Res Function(TempClosed) _then;

/// Create a copy of TempClosed
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? startDate = null,Object? endDate = freezed,}) {
  return _then(_self.copyWith(
startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as String,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TempClosed].
extension TempClosedPatterns on TempClosed {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TempClosed value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TempClosed() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TempClosed value)  $default,){
final _that = this;
switch (_that) {
case _TempClosed():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TempClosed value)?  $default,){
final _that = this;
switch (_that) {
case _TempClosed() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'start_date')  String startDate, @JsonKey(name: 'end_date')  String? endDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TempClosed() when $default != null:
return $default(_that.startDate,_that.endDate);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'start_date')  String startDate, @JsonKey(name: 'end_date')  String? endDate)  $default,) {final _that = this;
switch (_that) {
case _TempClosed():
return $default(_that.startDate,_that.endDate);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'start_date')  String startDate, @JsonKey(name: 'end_date')  String? endDate)?  $default,) {final _that = this;
switch (_that) {
case _TempClosed() when $default != null:
return $default(_that.startDate,_that.endDate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TempClosed implements TempClosed {
  const _TempClosed({@JsonKey(name: 'start_date') required this.startDate, @JsonKey(name: 'end_date') this.endDate});
  factory _TempClosed.fromJson(Map<String, dynamic> json) => _$TempClosedFromJson(json);

@override@JsonKey(name: 'start_date') final  String startDate;
/// 再開日。**告知されていなければ null**（「再開日未定」）
@override@JsonKey(name: 'end_date') final  String? endDate;

/// Create a copy of TempClosed
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TempClosedCopyWith<_TempClosed> get copyWith => __$TempClosedCopyWithImpl<_TempClosed>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TempClosedToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TempClosed&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,startDate,endDate);

@override
String toString() {
  return 'TempClosed(startDate: $startDate, endDate: $endDate)';
}


}

/// @nodoc
abstract mixin class _$TempClosedCopyWith<$Res> implements $TempClosedCopyWith<$Res> {
  factory _$TempClosedCopyWith(_TempClosed value, $Res Function(_TempClosed) _then) = __$TempClosedCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'start_date') String startDate,@JsonKey(name: 'end_date') String? endDate
});




}
/// @nodoc
class __$TempClosedCopyWithImpl<$Res>
    implements _$TempClosedCopyWith<$Res> {
  __$TempClosedCopyWithImpl(this._self, this._then);

  final _TempClosed _self;
  final $Res Function(_TempClosed) _then;

/// Create a copy of TempClosed
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? startDate = null,Object? endDate = freezed,}) {
  return _then(_TempClosed(
startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as String,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
