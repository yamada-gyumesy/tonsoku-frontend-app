// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'coupon.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Coupon {

@JsonKey(name: 'generated_at') String get generatedAt; List<CouponRank> get ranks;/// 今使えるぶん。**並びは配信の順をそのまま使う**（並べ替えは配信側の仕事）。
 List<CouponOffer> get offers;/// これから始まるぶん。**契約上 `start_date` 昇順**で届く。
 List<CouponOffer> get upcoming;
/// Create a copy of Coupon
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CouponCopyWith<Coupon> get copyWith => _$CouponCopyWithImpl<Coupon>(this as Coupon, _$identity);

  /// Serializes this Coupon to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Coupon&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt)&&const DeepCollectionEquality().equals(other.ranks, ranks)&&const DeepCollectionEquality().equals(other.offers, offers)&&const DeepCollectionEquality().equals(other.upcoming, upcoming));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,generatedAt,const DeepCollectionEquality().hash(ranks),const DeepCollectionEquality().hash(offers),const DeepCollectionEquality().hash(upcoming));

@override
String toString() {
  return 'Coupon(generatedAt: $generatedAt, ranks: $ranks, offers: $offers, upcoming: $upcoming)';
}


}

/// @nodoc
abstract mixin class $CouponCopyWith<$Res>  {
  factory $CouponCopyWith(Coupon value, $Res Function(Coupon) _then) = _$CouponCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'generated_at') String generatedAt, List<CouponRank> ranks, List<CouponOffer> offers, List<CouponOffer> upcoming
});




}
/// @nodoc
class _$CouponCopyWithImpl<$Res>
    implements $CouponCopyWith<$Res> {
  _$CouponCopyWithImpl(this._self, this._then);

  final Coupon _self;
  final $Res Function(Coupon) _then;

/// Create a copy of Coupon
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? generatedAt = null,Object? ranks = null,Object? offers = null,Object? upcoming = null,}) {
  return _then(_self.copyWith(
generatedAt: null == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as String,ranks: null == ranks ? _self.ranks : ranks // ignore: cast_nullable_to_non_nullable
as List<CouponRank>,offers: null == offers ? _self.offers : offers // ignore: cast_nullable_to_non_nullable
as List<CouponOffer>,upcoming: null == upcoming ? _self.upcoming : upcoming // ignore: cast_nullable_to_non_nullable
as List<CouponOffer>,
  ));
}

}


/// Adds pattern-matching-related methods to [Coupon].
extension CouponPatterns on Coupon {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Coupon value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Coupon() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Coupon value)  $default,){
final _that = this;
switch (_that) {
case _Coupon():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Coupon value)?  $default,){
final _that = this;
switch (_that) {
case _Coupon() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'generated_at')  String generatedAt,  List<CouponRank> ranks,  List<CouponOffer> offers,  List<CouponOffer> upcoming)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Coupon() when $default != null:
return $default(_that.generatedAt,_that.ranks,_that.offers,_that.upcoming);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'generated_at')  String generatedAt,  List<CouponRank> ranks,  List<CouponOffer> offers,  List<CouponOffer> upcoming)  $default,) {final _that = this;
switch (_that) {
case _Coupon():
return $default(_that.generatedAt,_that.ranks,_that.offers,_that.upcoming);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'generated_at')  String generatedAt,  List<CouponRank> ranks,  List<CouponOffer> offers,  List<CouponOffer> upcoming)?  $default,) {final _that = this;
switch (_that) {
case _Coupon() when $default != null:
return $default(_that.generatedAt,_that.ranks,_that.offers,_that.upcoming);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Coupon implements Coupon {
  const _Coupon({@JsonKey(name: 'generated_at') required this.generatedAt, final  List<CouponRank> ranks = const <CouponRank>[], final  List<CouponOffer> offers = const <CouponOffer>[], final  List<CouponOffer> upcoming = const <CouponOffer>[]}): _ranks = ranks,_offers = offers,_upcoming = upcoming;
  factory _Coupon.fromJson(Map<String, dynamic> json) => _$CouponFromJson(json);

@override@JsonKey(name: 'generated_at') final  String generatedAt;
 final  List<CouponRank> _ranks;
@override@JsonKey() List<CouponRank> get ranks {
  if (_ranks is EqualUnmodifiableListView) return _ranks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_ranks);
}

/// 今使えるぶん。**並びは配信の順をそのまま使う**（並べ替えは配信側の仕事）。
 final  List<CouponOffer> _offers;
/// 今使えるぶん。**並びは配信の順をそのまま使う**（並べ替えは配信側の仕事）。
@override@JsonKey() List<CouponOffer> get offers {
  if (_offers is EqualUnmodifiableListView) return _offers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_offers);
}

/// これから始まるぶん。**契約上 `start_date` 昇順**で届く。
 final  List<CouponOffer> _upcoming;
/// これから始まるぶん。**契約上 `start_date` 昇順**で届く。
@override@JsonKey() List<CouponOffer> get upcoming {
  if (_upcoming is EqualUnmodifiableListView) return _upcoming;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_upcoming);
}


/// Create a copy of Coupon
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CouponCopyWith<_Coupon> get copyWith => __$CouponCopyWithImpl<_Coupon>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CouponToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Coupon&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt)&&const DeepCollectionEquality().equals(other._ranks, _ranks)&&const DeepCollectionEquality().equals(other._offers, _offers)&&const DeepCollectionEquality().equals(other._upcoming, _upcoming));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,generatedAt,const DeepCollectionEquality().hash(_ranks),const DeepCollectionEquality().hash(_offers),const DeepCollectionEquality().hash(_upcoming));

@override
String toString() {
  return 'Coupon(generatedAt: $generatedAt, ranks: $ranks, offers: $offers, upcoming: $upcoming)';
}


}

/// @nodoc
abstract mixin class _$CouponCopyWith<$Res> implements $CouponCopyWith<$Res> {
  factory _$CouponCopyWith(_Coupon value, $Res Function(_Coupon) _then) = __$CouponCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'generated_at') String generatedAt, List<CouponRank> ranks, List<CouponOffer> offers, List<CouponOffer> upcoming
});




}
/// @nodoc
class __$CouponCopyWithImpl<$Res>
    implements _$CouponCopyWith<$Res> {
  __$CouponCopyWithImpl(this._self, this._then);

  final _Coupon _self;
  final $Res Function(_Coupon) _then;

/// Create a copy of Coupon
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? generatedAt = null,Object? ranks = null,Object? offers = null,Object? upcoming = null,}) {
  return _then(_Coupon(
generatedAt: null == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as String,ranks: null == ranks ? _self._ranks : ranks // ignore: cast_nullable_to_non_nullable
as List<CouponRank>,offers: null == offers ? _self._offers : offers // ignore: cast_nullable_to_non_nullable
as List<CouponOffer>,upcoming: null == upcoming ? _self._upcoming : upcoming // ignore: cast_nullable_to_non_nullable
as List<CouponOffer>,
  ));
}


}


/// @nodoc
mixin _$CouponRank {

 String get id; int get order;/// 系統ごとの付与率（`matsuben` / `mobile_order`）。**店舗払いは系統が無い**。
 Map<String, double> get rates;
/// Create a copy of CouponRank
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CouponRankCopyWith<CouponRank> get copyWith => _$CouponRankCopyWithImpl<CouponRank>(this as CouponRank, _$identity);

  /// Serializes this CouponRank to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CouponRank&&(identical(other.id, id) || other.id == id)&&(identical(other.order, order) || other.order == order)&&const DeepCollectionEquality().equals(other.rates, rates));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,order,const DeepCollectionEquality().hash(rates));

@override
String toString() {
  return 'CouponRank(id: $id, order: $order, rates: $rates)';
}


}

/// @nodoc
abstract mixin class $CouponRankCopyWith<$Res>  {
  factory $CouponRankCopyWith(CouponRank value, $Res Function(CouponRank) _then) = _$CouponRankCopyWithImpl;
@useResult
$Res call({
 String id, int order, Map<String, double> rates
});




}
/// @nodoc
class _$CouponRankCopyWithImpl<$Res>
    implements $CouponRankCopyWith<$Res> {
  _$CouponRankCopyWithImpl(this._self, this._then);

  final CouponRank _self;
  final $Res Function(CouponRank) _then;

/// Create a copy of CouponRank
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? order = null,Object? rates = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,rates: null == rates ? _self.rates : rates // ignore: cast_nullable_to_non_nullable
as Map<String, double>,
  ));
}

}


/// Adds pattern-matching-related methods to [CouponRank].
extension CouponRankPatterns on CouponRank {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CouponRank value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CouponRank() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CouponRank value)  $default,){
final _that = this;
switch (_that) {
case _CouponRank():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CouponRank value)?  $default,){
final _that = this;
switch (_that) {
case _CouponRank() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int order,  Map<String, double> rates)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CouponRank() when $default != null:
return $default(_that.id,_that.order,_that.rates);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int order,  Map<String, double> rates)  $default,) {final _that = this;
switch (_that) {
case _CouponRank():
return $default(_that.id,_that.order,_that.rates);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int order,  Map<String, double> rates)?  $default,) {final _that = this;
switch (_that) {
case _CouponRank() when $default != null:
return $default(_that.id,_that.order,_that.rates);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CouponRank implements CouponRank {
  const _CouponRank({required this.id, required this.order, final  Map<String, double> rates = const <String, double>{}}): _rates = rates;
  factory _CouponRank.fromJson(Map<String, dynamic> json) => _$CouponRankFromJson(json);

@override final  String id;
@override final  int order;
/// 系統ごとの付与率（`matsuben` / `mobile_order`）。**店舗払いは系統が無い**。
 final  Map<String, double> _rates;
/// 系統ごとの付与率（`matsuben` / `mobile_order`）。**店舗払いは系統が無い**。
@override@JsonKey() Map<String, double> get rates {
  if (_rates is EqualUnmodifiableMapView) return _rates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_rates);
}


/// Create a copy of CouponRank
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CouponRankCopyWith<_CouponRank> get copyWith => __$CouponRankCopyWithImpl<_CouponRank>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CouponRankToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CouponRank&&(identical(other.id, id) || other.id == id)&&(identical(other.order, order) || other.order == order)&&const DeepCollectionEquality().equals(other._rates, _rates));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,order,const DeepCollectionEquality().hash(_rates));

@override
String toString() {
  return 'CouponRank(id: $id, order: $order, rates: $rates)';
}


}

/// @nodoc
abstract mixin class _$CouponRankCopyWith<$Res> implements $CouponRankCopyWith<$Res> {
  factory _$CouponRankCopyWith(_CouponRank value, $Res Function(_CouponRank) _then) = __$CouponRankCopyWithImpl;
@override @useResult
$Res call({
 String id, int order, Map<String, double> rates
});




}
/// @nodoc
class __$CouponRankCopyWithImpl<$Res>
    implements _$CouponRankCopyWith<$Res> {
  __$CouponRankCopyWithImpl(this._self, this._then);

  final _CouponRank _self;
  final $Res Function(_CouponRank) _then;

/// Create a copy of CouponRank
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? order = null,Object? rates = null,}) {
  return _then(_CouponRank(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,rates: null == rates ? _self._rates : rates // ignore: cast_nullable_to_non_nullable
as Map<String, double>,
  ));
}


}


/// @nodoc
mixin _$CouponOffer {

 String get id;/// 決済ブランド（`paypay` 等）。松屋ポイントの施策は `matsuya-point`、
/// ブランドを持たないものは null。
 String? get brand;/// 施策名。**倍率クーポンでは使わない**（`offerName` が組み立てる）。
 String? get title;@JsonKey(name: 'rate_percent') double? get ratePercent;@JsonKey(name: 'rate_multiplier') double? get rateMultiplier;@JsonKey(name: 'point_amount') int? get pointAmount;@JsonKey(name: 'discount_yen') int? get discountYen;@JsonKey(name: 'discount_max_yen') int? get discountMaxYen;@JsonKey(name: 'cap_yen') int? get capYen;@JsonKey(name: 'min_spend_yen') int? get minSpendYen; List<CouponTier> get tiers;@JsonKey(name: 'requires_entry') bool get requiresEntry;@JsonKey(name: 'benefit_type') String? get benefitType; List<String> get channels;/// 取得方法。**配布元（`x` / `tiktok`）の判定はここを見る。** null を取りうる。
@JsonKey(name: 'how_to_get') String? get howToGet;@JsonKey(name: 'start_date') String get startDate;@JsonKey(name: 'end_date') String? get endDate;/// 終了の時刻（ISO 8601）。**決まっているものは時刻まで出す**（日付だけだと、
/// その日の何時までなのかが分からず最終日に取りこぼす。web と同じ）。
@JsonKey(name: 'end_at') String? get endAt;@JsonKey(name: 'time_window') String? get timeWindow; List<CouponLink> get links;/// チラシ（対象商品と値段が載っている元の告知画像を自前へ写したもの）。
@JsonKey(name: 'image_url') String? get imageUrl;/// **券売機にかざす QR コード。** とん速にしか無い鍵（gyumesy は元画像を
/// そのまま出している）。配信側が読み直して作り直したもので、元の投稿には無い。
@JsonKey(name: 'qr_image_url') String? get qrImageUrl;/// 出どころの投稿。チラシの引用元に使う（絵と出所は必ず同じ投稿を指す）。
@JsonKey(name: 'source_url') String? get sourceUrl;/// 出どころの種類（`official_x` / `official_tiktok` / `official_news` …）。
/// **開いた集合**（知らない値はホスト名に落とす）。
@JsonKey(name: 'source_label') String? get sourceLabel; List<String> get notes;@JsonKey(name: 'article_slug') String? get articleSlug;
/// Create a copy of CouponOffer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CouponOfferCopyWith<CouponOffer> get copyWith => _$CouponOfferCopyWithImpl<CouponOffer>(this as CouponOffer, _$identity);

  /// Serializes this CouponOffer to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CouponOffer&&(identical(other.id, id) || other.id == id)&&(identical(other.brand, brand) || other.brand == brand)&&(identical(other.title, title) || other.title == title)&&(identical(other.ratePercent, ratePercent) || other.ratePercent == ratePercent)&&(identical(other.rateMultiplier, rateMultiplier) || other.rateMultiplier == rateMultiplier)&&(identical(other.pointAmount, pointAmount) || other.pointAmount == pointAmount)&&(identical(other.discountYen, discountYen) || other.discountYen == discountYen)&&(identical(other.discountMaxYen, discountMaxYen) || other.discountMaxYen == discountMaxYen)&&(identical(other.capYen, capYen) || other.capYen == capYen)&&(identical(other.minSpendYen, minSpendYen) || other.minSpendYen == minSpendYen)&&const DeepCollectionEquality().equals(other.tiers, tiers)&&(identical(other.requiresEntry, requiresEntry) || other.requiresEntry == requiresEntry)&&(identical(other.benefitType, benefitType) || other.benefitType == benefitType)&&const DeepCollectionEquality().equals(other.channels, channels)&&(identical(other.howToGet, howToGet) || other.howToGet == howToGet)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.endAt, endAt) || other.endAt == endAt)&&(identical(other.timeWindow, timeWindow) || other.timeWindow == timeWindow)&&const DeepCollectionEquality().equals(other.links, links)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.qrImageUrl, qrImageUrl) || other.qrImageUrl == qrImageUrl)&&(identical(other.sourceUrl, sourceUrl) || other.sourceUrl == sourceUrl)&&(identical(other.sourceLabel, sourceLabel) || other.sourceLabel == sourceLabel)&&const DeepCollectionEquality().equals(other.notes, notes)&&(identical(other.articleSlug, articleSlug) || other.articleSlug == articleSlug));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,brand,title,ratePercent,rateMultiplier,pointAmount,discountYen,discountMaxYen,capYen,minSpendYen,const DeepCollectionEquality().hash(tiers),requiresEntry,benefitType,const DeepCollectionEquality().hash(channels),howToGet,startDate,endDate,endAt,timeWindow,const DeepCollectionEquality().hash(links),imageUrl,qrImageUrl,sourceUrl,sourceLabel,const DeepCollectionEquality().hash(notes),articleSlug]);

@override
String toString() {
  return 'CouponOffer(id: $id, brand: $brand, title: $title, ratePercent: $ratePercent, rateMultiplier: $rateMultiplier, pointAmount: $pointAmount, discountYen: $discountYen, discountMaxYen: $discountMaxYen, capYen: $capYen, minSpendYen: $minSpendYen, tiers: $tiers, requiresEntry: $requiresEntry, benefitType: $benefitType, channels: $channels, howToGet: $howToGet, startDate: $startDate, endDate: $endDate, endAt: $endAt, timeWindow: $timeWindow, links: $links, imageUrl: $imageUrl, qrImageUrl: $qrImageUrl, sourceUrl: $sourceUrl, sourceLabel: $sourceLabel, notes: $notes, articleSlug: $articleSlug)';
}


}

/// @nodoc
abstract mixin class $CouponOfferCopyWith<$Res>  {
  factory $CouponOfferCopyWith(CouponOffer value, $Res Function(CouponOffer) _then) = _$CouponOfferCopyWithImpl;
@useResult
$Res call({
 String id, String? brand, String? title,@JsonKey(name: 'rate_percent') double? ratePercent,@JsonKey(name: 'rate_multiplier') double? rateMultiplier,@JsonKey(name: 'point_amount') int? pointAmount,@JsonKey(name: 'discount_yen') int? discountYen,@JsonKey(name: 'discount_max_yen') int? discountMaxYen,@JsonKey(name: 'cap_yen') int? capYen,@JsonKey(name: 'min_spend_yen') int? minSpendYen, List<CouponTier> tiers,@JsonKey(name: 'requires_entry') bool requiresEntry,@JsonKey(name: 'benefit_type') String? benefitType, List<String> channels,@JsonKey(name: 'how_to_get') String? howToGet,@JsonKey(name: 'start_date') String startDate,@JsonKey(name: 'end_date') String? endDate,@JsonKey(name: 'end_at') String? endAt,@JsonKey(name: 'time_window') String? timeWindow, List<CouponLink> links,@JsonKey(name: 'image_url') String? imageUrl,@JsonKey(name: 'qr_image_url') String? qrImageUrl,@JsonKey(name: 'source_url') String? sourceUrl,@JsonKey(name: 'source_label') String? sourceLabel, List<String> notes,@JsonKey(name: 'article_slug') String? articleSlug
});




}
/// @nodoc
class _$CouponOfferCopyWithImpl<$Res>
    implements $CouponOfferCopyWith<$Res> {
  _$CouponOfferCopyWithImpl(this._self, this._then);

  final CouponOffer _self;
  final $Res Function(CouponOffer) _then;

/// Create a copy of CouponOffer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? brand = freezed,Object? title = freezed,Object? ratePercent = freezed,Object? rateMultiplier = freezed,Object? pointAmount = freezed,Object? discountYen = freezed,Object? discountMaxYen = freezed,Object? capYen = freezed,Object? minSpendYen = freezed,Object? tiers = null,Object? requiresEntry = null,Object? benefitType = freezed,Object? channels = null,Object? howToGet = freezed,Object? startDate = null,Object? endDate = freezed,Object? endAt = freezed,Object? timeWindow = freezed,Object? links = null,Object? imageUrl = freezed,Object? qrImageUrl = freezed,Object? sourceUrl = freezed,Object? sourceLabel = freezed,Object? notes = null,Object? articleSlug = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,brand: freezed == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,ratePercent: freezed == ratePercent ? _self.ratePercent : ratePercent // ignore: cast_nullable_to_non_nullable
as double?,rateMultiplier: freezed == rateMultiplier ? _self.rateMultiplier : rateMultiplier // ignore: cast_nullable_to_non_nullable
as double?,pointAmount: freezed == pointAmount ? _self.pointAmount : pointAmount // ignore: cast_nullable_to_non_nullable
as int?,discountYen: freezed == discountYen ? _self.discountYen : discountYen // ignore: cast_nullable_to_non_nullable
as int?,discountMaxYen: freezed == discountMaxYen ? _self.discountMaxYen : discountMaxYen // ignore: cast_nullable_to_non_nullable
as int?,capYen: freezed == capYen ? _self.capYen : capYen // ignore: cast_nullable_to_non_nullable
as int?,minSpendYen: freezed == minSpendYen ? _self.minSpendYen : minSpendYen // ignore: cast_nullable_to_non_nullable
as int?,tiers: null == tiers ? _self.tiers : tiers // ignore: cast_nullable_to_non_nullable
as List<CouponTier>,requiresEntry: null == requiresEntry ? _self.requiresEntry : requiresEntry // ignore: cast_nullable_to_non_nullable
as bool,benefitType: freezed == benefitType ? _self.benefitType : benefitType // ignore: cast_nullable_to_non_nullable
as String?,channels: null == channels ? _self.channels : channels // ignore: cast_nullable_to_non_nullable
as List<String>,howToGet: freezed == howToGet ? _self.howToGet : howToGet // ignore: cast_nullable_to_non_nullable
as String?,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as String,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as String?,endAt: freezed == endAt ? _self.endAt : endAt // ignore: cast_nullable_to_non_nullable
as String?,timeWindow: freezed == timeWindow ? _self.timeWindow : timeWindow // ignore: cast_nullable_to_non_nullable
as String?,links: null == links ? _self.links : links // ignore: cast_nullable_to_non_nullable
as List<CouponLink>,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,qrImageUrl: freezed == qrImageUrl ? _self.qrImageUrl : qrImageUrl // ignore: cast_nullable_to_non_nullable
as String?,sourceUrl: freezed == sourceUrl ? _self.sourceUrl : sourceUrl // ignore: cast_nullable_to_non_nullable
as String?,sourceLabel: freezed == sourceLabel ? _self.sourceLabel : sourceLabel // ignore: cast_nullable_to_non_nullable
as String?,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as List<String>,articleSlug: freezed == articleSlug ? _self.articleSlug : articleSlug // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CouponOffer].
extension CouponOfferPatterns on CouponOffer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CouponOffer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CouponOffer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CouponOffer value)  $default,){
final _that = this;
switch (_that) {
case _CouponOffer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CouponOffer value)?  $default,){
final _that = this;
switch (_that) {
case _CouponOffer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? brand,  String? title, @JsonKey(name: 'rate_percent')  double? ratePercent, @JsonKey(name: 'rate_multiplier')  double? rateMultiplier, @JsonKey(name: 'point_amount')  int? pointAmount, @JsonKey(name: 'discount_yen')  int? discountYen, @JsonKey(name: 'discount_max_yen')  int? discountMaxYen, @JsonKey(name: 'cap_yen')  int? capYen, @JsonKey(name: 'min_spend_yen')  int? minSpendYen,  List<CouponTier> tiers, @JsonKey(name: 'requires_entry')  bool requiresEntry, @JsonKey(name: 'benefit_type')  String? benefitType,  List<String> channels, @JsonKey(name: 'how_to_get')  String? howToGet, @JsonKey(name: 'start_date')  String startDate, @JsonKey(name: 'end_date')  String? endDate, @JsonKey(name: 'end_at')  String? endAt, @JsonKey(name: 'time_window')  String? timeWindow,  List<CouponLink> links, @JsonKey(name: 'image_url')  String? imageUrl, @JsonKey(name: 'qr_image_url')  String? qrImageUrl, @JsonKey(name: 'source_url')  String? sourceUrl, @JsonKey(name: 'source_label')  String? sourceLabel,  List<String> notes, @JsonKey(name: 'article_slug')  String? articleSlug)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CouponOffer() when $default != null:
return $default(_that.id,_that.brand,_that.title,_that.ratePercent,_that.rateMultiplier,_that.pointAmount,_that.discountYen,_that.discountMaxYen,_that.capYen,_that.minSpendYen,_that.tiers,_that.requiresEntry,_that.benefitType,_that.channels,_that.howToGet,_that.startDate,_that.endDate,_that.endAt,_that.timeWindow,_that.links,_that.imageUrl,_that.qrImageUrl,_that.sourceUrl,_that.sourceLabel,_that.notes,_that.articleSlug);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? brand,  String? title, @JsonKey(name: 'rate_percent')  double? ratePercent, @JsonKey(name: 'rate_multiplier')  double? rateMultiplier, @JsonKey(name: 'point_amount')  int? pointAmount, @JsonKey(name: 'discount_yen')  int? discountYen, @JsonKey(name: 'discount_max_yen')  int? discountMaxYen, @JsonKey(name: 'cap_yen')  int? capYen, @JsonKey(name: 'min_spend_yen')  int? minSpendYen,  List<CouponTier> tiers, @JsonKey(name: 'requires_entry')  bool requiresEntry, @JsonKey(name: 'benefit_type')  String? benefitType,  List<String> channels, @JsonKey(name: 'how_to_get')  String? howToGet, @JsonKey(name: 'start_date')  String startDate, @JsonKey(name: 'end_date')  String? endDate, @JsonKey(name: 'end_at')  String? endAt, @JsonKey(name: 'time_window')  String? timeWindow,  List<CouponLink> links, @JsonKey(name: 'image_url')  String? imageUrl, @JsonKey(name: 'qr_image_url')  String? qrImageUrl, @JsonKey(name: 'source_url')  String? sourceUrl, @JsonKey(name: 'source_label')  String? sourceLabel,  List<String> notes, @JsonKey(name: 'article_slug')  String? articleSlug)  $default,) {final _that = this;
switch (_that) {
case _CouponOffer():
return $default(_that.id,_that.brand,_that.title,_that.ratePercent,_that.rateMultiplier,_that.pointAmount,_that.discountYen,_that.discountMaxYen,_that.capYen,_that.minSpendYen,_that.tiers,_that.requiresEntry,_that.benefitType,_that.channels,_that.howToGet,_that.startDate,_that.endDate,_that.endAt,_that.timeWindow,_that.links,_that.imageUrl,_that.qrImageUrl,_that.sourceUrl,_that.sourceLabel,_that.notes,_that.articleSlug);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? brand,  String? title, @JsonKey(name: 'rate_percent')  double? ratePercent, @JsonKey(name: 'rate_multiplier')  double? rateMultiplier, @JsonKey(name: 'point_amount')  int? pointAmount, @JsonKey(name: 'discount_yen')  int? discountYen, @JsonKey(name: 'discount_max_yen')  int? discountMaxYen, @JsonKey(name: 'cap_yen')  int? capYen, @JsonKey(name: 'min_spend_yen')  int? minSpendYen,  List<CouponTier> tiers, @JsonKey(name: 'requires_entry')  bool requiresEntry, @JsonKey(name: 'benefit_type')  String? benefitType,  List<String> channels, @JsonKey(name: 'how_to_get')  String? howToGet, @JsonKey(name: 'start_date')  String startDate, @JsonKey(name: 'end_date')  String? endDate, @JsonKey(name: 'end_at')  String? endAt, @JsonKey(name: 'time_window')  String? timeWindow,  List<CouponLink> links, @JsonKey(name: 'image_url')  String? imageUrl, @JsonKey(name: 'qr_image_url')  String? qrImageUrl, @JsonKey(name: 'source_url')  String? sourceUrl, @JsonKey(name: 'source_label')  String? sourceLabel,  List<String> notes, @JsonKey(name: 'article_slug')  String? articleSlug)?  $default,) {final _that = this;
switch (_that) {
case _CouponOffer() when $default != null:
return $default(_that.id,_that.brand,_that.title,_that.ratePercent,_that.rateMultiplier,_that.pointAmount,_that.discountYen,_that.discountMaxYen,_that.capYen,_that.minSpendYen,_that.tiers,_that.requiresEntry,_that.benefitType,_that.channels,_that.howToGet,_that.startDate,_that.endDate,_that.endAt,_that.timeWindow,_that.links,_that.imageUrl,_that.qrImageUrl,_that.sourceUrl,_that.sourceLabel,_that.notes,_that.articleSlug);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CouponOffer implements CouponOffer {
  const _CouponOffer({required this.id, this.brand, this.title, @JsonKey(name: 'rate_percent') this.ratePercent, @JsonKey(name: 'rate_multiplier') this.rateMultiplier, @JsonKey(name: 'point_amount') this.pointAmount, @JsonKey(name: 'discount_yen') this.discountYen, @JsonKey(name: 'discount_max_yen') this.discountMaxYen, @JsonKey(name: 'cap_yen') this.capYen, @JsonKey(name: 'min_spend_yen') this.minSpendYen, final  List<CouponTier> tiers = const <CouponTier>[], @JsonKey(name: 'requires_entry') this.requiresEntry = false, @JsonKey(name: 'benefit_type') this.benefitType, final  List<String> channels = const <String>[], @JsonKey(name: 'how_to_get') this.howToGet, @JsonKey(name: 'start_date') required this.startDate, @JsonKey(name: 'end_date') this.endDate, @JsonKey(name: 'end_at') this.endAt, @JsonKey(name: 'time_window') this.timeWindow, final  List<CouponLink> links = const <CouponLink>[], @JsonKey(name: 'image_url') this.imageUrl, @JsonKey(name: 'qr_image_url') this.qrImageUrl, @JsonKey(name: 'source_url') this.sourceUrl, @JsonKey(name: 'source_label') this.sourceLabel, final  List<String> notes = const <String>[], @JsonKey(name: 'article_slug') this.articleSlug}): _tiers = tiers,_channels = channels,_links = links,_notes = notes;
  factory _CouponOffer.fromJson(Map<String, dynamic> json) => _$CouponOfferFromJson(json);

@override final  String id;
/// 決済ブランド（`paypay` 等）。松屋ポイントの施策は `matsuya-point`、
/// ブランドを持たないものは null。
@override final  String? brand;
/// 施策名。**倍率クーポンでは使わない**（`offerName` が組み立てる）。
@override final  String? title;
@override@JsonKey(name: 'rate_percent') final  double? ratePercent;
@override@JsonKey(name: 'rate_multiplier') final  double? rateMultiplier;
@override@JsonKey(name: 'point_amount') final  int? pointAmount;
@override@JsonKey(name: 'discount_yen') final  int? discountYen;
@override@JsonKey(name: 'discount_max_yen') final  int? discountMaxYen;
@override@JsonKey(name: 'cap_yen') final  int? capYen;
@override@JsonKey(name: 'min_spend_yen') final  int? minSpendYen;
 final  List<CouponTier> _tiers;
@override@JsonKey() List<CouponTier> get tiers {
  if (_tiers is EqualUnmodifiableListView) return _tiers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tiers);
}

@override@JsonKey(name: 'requires_entry') final  bool requiresEntry;
@override@JsonKey(name: 'benefit_type') final  String? benefitType;
 final  List<String> _channels;
@override@JsonKey() List<String> get channels {
  if (_channels is EqualUnmodifiableListView) return _channels;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_channels);
}

/// 取得方法。**配布元（`x` / `tiktok`）の判定はここを見る。** null を取りうる。
@override@JsonKey(name: 'how_to_get') final  String? howToGet;
@override@JsonKey(name: 'start_date') final  String startDate;
@override@JsonKey(name: 'end_date') final  String? endDate;
/// 終了の時刻（ISO 8601）。**決まっているものは時刻まで出す**（日付だけだと、
/// その日の何時までなのかが分からず最終日に取りこぼす。web と同じ）。
@override@JsonKey(name: 'end_at') final  String? endAt;
@override@JsonKey(name: 'time_window') final  String? timeWindow;
 final  List<CouponLink> _links;
@override@JsonKey() List<CouponLink> get links {
  if (_links is EqualUnmodifiableListView) return _links;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_links);
}

/// チラシ（対象商品と値段が載っている元の告知画像を自前へ写したもの）。
@override@JsonKey(name: 'image_url') final  String? imageUrl;
/// **券売機にかざす QR コード。** とん速にしか無い鍵（gyumesy は元画像を
/// そのまま出している）。配信側が読み直して作り直したもので、元の投稿には無い。
@override@JsonKey(name: 'qr_image_url') final  String? qrImageUrl;
/// 出どころの投稿。チラシの引用元に使う（絵と出所は必ず同じ投稿を指す）。
@override@JsonKey(name: 'source_url') final  String? sourceUrl;
/// 出どころの種類（`official_x` / `official_tiktok` / `official_news` …）。
/// **開いた集合**（知らない値はホスト名に落とす）。
@override@JsonKey(name: 'source_label') final  String? sourceLabel;
 final  List<String> _notes;
@override@JsonKey() List<String> get notes {
  if (_notes is EqualUnmodifiableListView) return _notes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_notes);
}

@override@JsonKey(name: 'article_slug') final  String? articleSlug;

/// Create a copy of CouponOffer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CouponOfferCopyWith<_CouponOffer> get copyWith => __$CouponOfferCopyWithImpl<_CouponOffer>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CouponOfferToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CouponOffer&&(identical(other.id, id) || other.id == id)&&(identical(other.brand, brand) || other.brand == brand)&&(identical(other.title, title) || other.title == title)&&(identical(other.ratePercent, ratePercent) || other.ratePercent == ratePercent)&&(identical(other.rateMultiplier, rateMultiplier) || other.rateMultiplier == rateMultiplier)&&(identical(other.pointAmount, pointAmount) || other.pointAmount == pointAmount)&&(identical(other.discountYen, discountYen) || other.discountYen == discountYen)&&(identical(other.discountMaxYen, discountMaxYen) || other.discountMaxYen == discountMaxYen)&&(identical(other.capYen, capYen) || other.capYen == capYen)&&(identical(other.minSpendYen, minSpendYen) || other.minSpendYen == minSpendYen)&&const DeepCollectionEquality().equals(other._tiers, _tiers)&&(identical(other.requiresEntry, requiresEntry) || other.requiresEntry == requiresEntry)&&(identical(other.benefitType, benefitType) || other.benefitType == benefitType)&&const DeepCollectionEquality().equals(other._channels, _channels)&&(identical(other.howToGet, howToGet) || other.howToGet == howToGet)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.endAt, endAt) || other.endAt == endAt)&&(identical(other.timeWindow, timeWindow) || other.timeWindow == timeWindow)&&const DeepCollectionEquality().equals(other._links, _links)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.qrImageUrl, qrImageUrl) || other.qrImageUrl == qrImageUrl)&&(identical(other.sourceUrl, sourceUrl) || other.sourceUrl == sourceUrl)&&(identical(other.sourceLabel, sourceLabel) || other.sourceLabel == sourceLabel)&&const DeepCollectionEquality().equals(other._notes, _notes)&&(identical(other.articleSlug, articleSlug) || other.articleSlug == articleSlug));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,brand,title,ratePercent,rateMultiplier,pointAmount,discountYen,discountMaxYen,capYen,minSpendYen,const DeepCollectionEquality().hash(_tiers),requiresEntry,benefitType,const DeepCollectionEquality().hash(_channels),howToGet,startDate,endDate,endAt,timeWindow,const DeepCollectionEquality().hash(_links),imageUrl,qrImageUrl,sourceUrl,sourceLabel,const DeepCollectionEquality().hash(_notes),articleSlug]);

@override
String toString() {
  return 'CouponOffer(id: $id, brand: $brand, title: $title, ratePercent: $ratePercent, rateMultiplier: $rateMultiplier, pointAmount: $pointAmount, discountYen: $discountYen, discountMaxYen: $discountMaxYen, capYen: $capYen, minSpendYen: $minSpendYen, tiers: $tiers, requiresEntry: $requiresEntry, benefitType: $benefitType, channels: $channels, howToGet: $howToGet, startDate: $startDate, endDate: $endDate, endAt: $endAt, timeWindow: $timeWindow, links: $links, imageUrl: $imageUrl, qrImageUrl: $qrImageUrl, sourceUrl: $sourceUrl, sourceLabel: $sourceLabel, notes: $notes, articleSlug: $articleSlug)';
}


}

/// @nodoc
abstract mixin class _$CouponOfferCopyWith<$Res> implements $CouponOfferCopyWith<$Res> {
  factory _$CouponOfferCopyWith(_CouponOffer value, $Res Function(_CouponOffer) _then) = __$CouponOfferCopyWithImpl;
@override @useResult
$Res call({
 String id, String? brand, String? title,@JsonKey(name: 'rate_percent') double? ratePercent,@JsonKey(name: 'rate_multiplier') double? rateMultiplier,@JsonKey(name: 'point_amount') int? pointAmount,@JsonKey(name: 'discount_yen') int? discountYen,@JsonKey(name: 'discount_max_yen') int? discountMaxYen,@JsonKey(name: 'cap_yen') int? capYen,@JsonKey(name: 'min_spend_yen') int? minSpendYen, List<CouponTier> tiers,@JsonKey(name: 'requires_entry') bool requiresEntry,@JsonKey(name: 'benefit_type') String? benefitType, List<String> channels,@JsonKey(name: 'how_to_get') String? howToGet,@JsonKey(name: 'start_date') String startDate,@JsonKey(name: 'end_date') String? endDate,@JsonKey(name: 'end_at') String? endAt,@JsonKey(name: 'time_window') String? timeWindow, List<CouponLink> links,@JsonKey(name: 'image_url') String? imageUrl,@JsonKey(name: 'qr_image_url') String? qrImageUrl,@JsonKey(name: 'source_url') String? sourceUrl,@JsonKey(name: 'source_label') String? sourceLabel, List<String> notes,@JsonKey(name: 'article_slug') String? articleSlug
});




}
/// @nodoc
class __$CouponOfferCopyWithImpl<$Res>
    implements _$CouponOfferCopyWith<$Res> {
  __$CouponOfferCopyWithImpl(this._self, this._then);

  final _CouponOffer _self;
  final $Res Function(_CouponOffer) _then;

/// Create a copy of CouponOffer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? brand = freezed,Object? title = freezed,Object? ratePercent = freezed,Object? rateMultiplier = freezed,Object? pointAmount = freezed,Object? discountYen = freezed,Object? discountMaxYen = freezed,Object? capYen = freezed,Object? minSpendYen = freezed,Object? tiers = null,Object? requiresEntry = null,Object? benefitType = freezed,Object? channels = null,Object? howToGet = freezed,Object? startDate = null,Object? endDate = freezed,Object? endAt = freezed,Object? timeWindow = freezed,Object? links = null,Object? imageUrl = freezed,Object? qrImageUrl = freezed,Object? sourceUrl = freezed,Object? sourceLabel = freezed,Object? notes = null,Object? articleSlug = freezed,}) {
  return _then(_CouponOffer(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,brand: freezed == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,ratePercent: freezed == ratePercent ? _self.ratePercent : ratePercent // ignore: cast_nullable_to_non_nullable
as double?,rateMultiplier: freezed == rateMultiplier ? _self.rateMultiplier : rateMultiplier // ignore: cast_nullable_to_non_nullable
as double?,pointAmount: freezed == pointAmount ? _self.pointAmount : pointAmount // ignore: cast_nullable_to_non_nullable
as int?,discountYen: freezed == discountYen ? _self.discountYen : discountYen // ignore: cast_nullable_to_non_nullable
as int?,discountMaxYen: freezed == discountMaxYen ? _self.discountMaxYen : discountMaxYen // ignore: cast_nullable_to_non_nullable
as int?,capYen: freezed == capYen ? _self.capYen : capYen // ignore: cast_nullable_to_non_nullable
as int?,minSpendYen: freezed == minSpendYen ? _self.minSpendYen : minSpendYen // ignore: cast_nullable_to_non_nullable
as int?,tiers: null == tiers ? _self._tiers : tiers // ignore: cast_nullable_to_non_nullable
as List<CouponTier>,requiresEntry: null == requiresEntry ? _self.requiresEntry : requiresEntry // ignore: cast_nullable_to_non_nullable
as bool,benefitType: freezed == benefitType ? _self.benefitType : benefitType // ignore: cast_nullable_to_non_nullable
as String?,channels: null == channels ? _self._channels : channels // ignore: cast_nullable_to_non_nullable
as List<String>,howToGet: freezed == howToGet ? _self.howToGet : howToGet // ignore: cast_nullable_to_non_nullable
as String?,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as String,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as String?,endAt: freezed == endAt ? _self.endAt : endAt // ignore: cast_nullable_to_non_nullable
as String?,timeWindow: freezed == timeWindow ? _self.timeWindow : timeWindow // ignore: cast_nullable_to_non_nullable
as String?,links: null == links ? _self._links : links // ignore: cast_nullable_to_non_nullable
as List<CouponLink>,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,qrImageUrl: freezed == qrImageUrl ? _self.qrImageUrl : qrImageUrl // ignore: cast_nullable_to_non_nullable
as String?,sourceUrl: freezed == sourceUrl ? _self.sourceUrl : sourceUrl // ignore: cast_nullable_to_non_nullable
as String?,sourceLabel: freezed == sourceLabel ? _self.sourceLabel : sourceLabel // ignore: cast_nullable_to_non_nullable
as String?,notes: null == notes ? _self._notes : notes // ignore: cast_nullable_to_non_nullable
as List<String>,articleSlug: freezed == articleSlug ? _self.articleSlug : articleSlug // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$CouponTier {

@JsonKey(name: 'rate_percent') double get ratePercent;@JsonKey(name: 'min_spend_yen') int get minSpendYen;
/// Create a copy of CouponTier
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CouponTierCopyWith<CouponTier> get copyWith => _$CouponTierCopyWithImpl<CouponTier>(this as CouponTier, _$identity);

  /// Serializes this CouponTier to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CouponTier&&(identical(other.ratePercent, ratePercent) || other.ratePercent == ratePercent)&&(identical(other.minSpendYen, minSpendYen) || other.minSpendYen == minSpendYen));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ratePercent,minSpendYen);

@override
String toString() {
  return 'CouponTier(ratePercent: $ratePercent, minSpendYen: $minSpendYen)';
}


}

/// @nodoc
abstract mixin class $CouponTierCopyWith<$Res>  {
  factory $CouponTierCopyWith(CouponTier value, $Res Function(CouponTier) _then) = _$CouponTierCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'rate_percent') double ratePercent,@JsonKey(name: 'min_spend_yen') int minSpendYen
});




}
/// @nodoc
class _$CouponTierCopyWithImpl<$Res>
    implements $CouponTierCopyWith<$Res> {
  _$CouponTierCopyWithImpl(this._self, this._then);

  final CouponTier _self;
  final $Res Function(CouponTier) _then;

/// Create a copy of CouponTier
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ratePercent = null,Object? minSpendYen = null,}) {
  return _then(_self.copyWith(
ratePercent: null == ratePercent ? _self.ratePercent : ratePercent // ignore: cast_nullable_to_non_nullable
as double,minSpendYen: null == minSpendYen ? _self.minSpendYen : minSpendYen // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CouponTier].
extension CouponTierPatterns on CouponTier {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CouponTier value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CouponTier() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CouponTier value)  $default,){
final _that = this;
switch (_that) {
case _CouponTier():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CouponTier value)?  $default,){
final _that = this;
switch (_that) {
case _CouponTier() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'rate_percent')  double ratePercent, @JsonKey(name: 'min_spend_yen')  int minSpendYen)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CouponTier() when $default != null:
return $default(_that.ratePercent,_that.minSpendYen);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'rate_percent')  double ratePercent, @JsonKey(name: 'min_spend_yen')  int minSpendYen)  $default,) {final _that = this;
switch (_that) {
case _CouponTier():
return $default(_that.ratePercent,_that.minSpendYen);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'rate_percent')  double ratePercent, @JsonKey(name: 'min_spend_yen')  int minSpendYen)?  $default,) {final _that = this;
switch (_that) {
case _CouponTier() when $default != null:
return $default(_that.ratePercent,_that.minSpendYen);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CouponTier implements CouponTier {
  const _CouponTier({@JsonKey(name: 'rate_percent') required this.ratePercent, @JsonKey(name: 'min_spend_yen') required this.minSpendYen});
  factory _CouponTier.fromJson(Map<String, dynamic> json) => _$CouponTierFromJson(json);

@override@JsonKey(name: 'rate_percent') final  double ratePercent;
@override@JsonKey(name: 'min_spend_yen') final  int minSpendYen;

/// Create a copy of CouponTier
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CouponTierCopyWith<_CouponTier> get copyWith => __$CouponTierCopyWithImpl<_CouponTier>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CouponTierToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CouponTier&&(identical(other.ratePercent, ratePercent) || other.ratePercent == ratePercent)&&(identical(other.minSpendYen, minSpendYen) || other.minSpendYen == minSpendYen));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ratePercent,minSpendYen);

@override
String toString() {
  return 'CouponTier(ratePercent: $ratePercent, minSpendYen: $minSpendYen)';
}


}

/// @nodoc
abstract mixin class _$CouponTierCopyWith<$Res> implements $CouponTierCopyWith<$Res> {
  factory _$CouponTierCopyWith(_CouponTier value, $Res Function(_CouponTier) _then) = __$CouponTierCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'rate_percent') double ratePercent,@JsonKey(name: 'min_spend_yen') int minSpendYen
});




}
/// @nodoc
class __$CouponTierCopyWithImpl<$Res>
    implements _$CouponTierCopyWith<$Res> {
  __$CouponTierCopyWithImpl(this._self, this._then);

  final _CouponTier _self;
  final $Res Function(_CouponTier) _then;

/// Create a copy of CouponTier
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ratePercent = null,Object? minSpendYen = null,}) {
  return _then(_CouponTier(
ratePercent: null == ratePercent ? _self.ratePercent : ratePercent // ignore: cast_nullable_to_non_nullable
as double,minSpendYen: null == minSpendYen ? _self.minSpendYen : minSpendYen // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$CouponLink {

 String get url; String get kind;@JsonKey(name: 'rate_percent') double? get ratePercent;
/// Create a copy of CouponLink
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CouponLinkCopyWith<CouponLink> get copyWith => _$CouponLinkCopyWithImpl<CouponLink>(this as CouponLink, _$identity);

  /// Serializes this CouponLink to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CouponLink&&(identical(other.url, url) || other.url == url)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.ratePercent, ratePercent) || other.ratePercent == ratePercent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,url,kind,ratePercent);

@override
String toString() {
  return 'CouponLink(url: $url, kind: $kind, ratePercent: $ratePercent)';
}


}

/// @nodoc
abstract mixin class $CouponLinkCopyWith<$Res>  {
  factory $CouponLinkCopyWith(CouponLink value, $Res Function(CouponLink) _then) = _$CouponLinkCopyWithImpl;
@useResult
$Res call({
 String url, String kind,@JsonKey(name: 'rate_percent') double? ratePercent
});




}
/// @nodoc
class _$CouponLinkCopyWithImpl<$Res>
    implements $CouponLinkCopyWith<$Res> {
  _$CouponLinkCopyWithImpl(this._self, this._then);

  final CouponLink _self;
  final $Res Function(CouponLink) _then;

/// Create a copy of CouponLink
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? url = null,Object? kind = null,Object? ratePercent = freezed,}) {
  return _then(_self.copyWith(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,ratePercent: freezed == ratePercent ? _self.ratePercent : ratePercent // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [CouponLink].
extension CouponLinkPatterns on CouponLink {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CouponLink value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CouponLink() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CouponLink value)  $default,){
final _that = this;
switch (_that) {
case _CouponLink():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CouponLink value)?  $default,){
final _that = this;
switch (_that) {
case _CouponLink() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String url,  String kind, @JsonKey(name: 'rate_percent')  double? ratePercent)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CouponLink() when $default != null:
return $default(_that.url,_that.kind,_that.ratePercent);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String url,  String kind, @JsonKey(name: 'rate_percent')  double? ratePercent)  $default,) {final _that = this;
switch (_that) {
case _CouponLink():
return $default(_that.url,_that.kind,_that.ratePercent);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String url,  String kind, @JsonKey(name: 'rate_percent')  double? ratePercent)?  $default,) {final _that = this;
switch (_that) {
case _CouponLink() when $default != null:
return $default(_that.url,_that.kind,_that.ratePercent);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CouponLink implements CouponLink {
  const _CouponLink({required this.url, required this.kind, @JsonKey(name: 'rate_percent') this.ratePercent});
  factory _CouponLink.fromJson(Map<String, dynamic> json) => _$CouponLinkFromJson(json);

@override final  String url;
@override final  String kind;
@override@JsonKey(name: 'rate_percent') final  double? ratePercent;

/// Create a copy of CouponLink
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CouponLinkCopyWith<_CouponLink> get copyWith => __$CouponLinkCopyWithImpl<_CouponLink>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CouponLinkToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CouponLink&&(identical(other.url, url) || other.url == url)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.ratePercent, ratePercent) || other.ratePercent == ratePercent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,url,kind,ratePercent);

@override
String toString() {
  return 'CouponLink(url: $url, kind: $kind, ratePercent: $ratePercent)';
}


}

/// @nodoc
abstract mixin class _$CouponLinkCopyWith<$Res> implements $CouponLinkCopyWith<$Res> {
  factory _$CouponLinkCopyWith(_CouponLink value, $Res Function(_CouponLink) _then) = __$CouponLinkCopyWithImpl;
@override @useResult
$Res call({
 String url, String kind,@JsonKey(name: 'rate_percent') double? ratePercent
});




}
/// @nodoc
class __$CouponLinkCopyWithImpl<$Res>
    implements _$CouponLinkCopyWith<$Res> {
  __$CouponLinkCopyWithImpl(this._self, this._then);

  final _CouponLink _self;
  final $Res Function(_CouponLink) _then;

/// Create a copy of CouponLink
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? url = null,Object? kind = null,Object? ratePercent = freezed,}) {
  return _then(_CouponLink(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,ratePercent: freezed == ratePercent ? _self.ratePercent : ratePercent // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on
