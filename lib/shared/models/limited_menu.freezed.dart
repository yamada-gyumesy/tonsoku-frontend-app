// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'limited_menu.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LimitedMenu {

/// 識別子。**昼の品の `cms_id`**（深夜料金版は配信側で 1 つにまとめてある）。
/// とん速にキャンペーンという単位は無いが、鍵の名前は牛めしレーダーに揃えてある
@JsonKey(name: 'campaign_id') String get campaignId;/// 品名。**英語・中国語の面（`i18n/{en,zh}/app/limited.json`）では公式訳か
/// 訳語辞書の訳で、どちらも無ければ null**（日本語に落とさない。
/// tonsoku-backend-batch#286）。**null の品は地図に出さない**
/// （`MapRepository.isShown`）
 String? get name;/// 発売の時刻（JST `YYYY-MM-DD HH:mm`）。
@JsonKey(name: 'start_date') String? get startDate;/// **いま掲載がある店**（売り切れ中の店も含む）。
 List<String> get shops;/// [shops] のうち、**いま売り切れの店**（15 分ごとの巡回で更新される）。
@JsonKey(name: 'sold_out_shops') List<String> get soldOutShops;/// 扱っていたが掲載が外れた店と、その時刻。**記事の取扱店の表の
/// 「（9/13 21時 終売）」と同じ答え**。記事になっていない品は空。
@JsonKey(name: 'ended_shops') List<EndedShop> get endedShops;/// **全店で終売した時刻。売っている間は null。** 時刻が分からない品だけ
/// 日付（`YYYY-MM-DD`）で来る。
@JsonKey(name: 'ended_at') String? get endedAt;/// その品の記事（配信済みのものだけ）。
@JsonKey(name: 'article_slug') String? get articleSlug;/// 記事の一覧用サムネイル。
@JsonKey(name: 'thumbnail_url') String? get thumbnailUrl;/// 品の写真（自前の CDN に写したもの）。
@JsonKey(name: 'image_url') String? get imageUrl;
/// Create a copy of LimitedMenu
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LimitedMenuCopyWith<LimitedMenu> get copyWith => _$LimitedMenuCopyWithImpl<LimitedMenu>(this as LimitedMenu, _$identity);

  /// Serializes this LimitedMenu to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LimitedMenu&&(identical(other.campaignId, campaignId) || other.campaignId == campaignId)&&(identical(other.name, name) || other.name == name)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&const DeepCollectionEquality().equals(other.shops, shops)&&const DeepCollectionEquality().equals(other.soldOutShops, soldOutShops)&&const DeepCollectionEquality().equals(other.endedShops, endedShops)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt)&&(identical(other.articleSlug, articleSlug) || other.articleSlug == articleSlug)&&(identical(other.thumbnailUrl, thumbnailUrl) || other.thumbnailUrl == thumbnailUrl)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,campaignId,name,startDate,const DeepCollectionEquality().hash(shops),const DeepCollectionEquality().hash(soldOutShops),const DeepCollectionEquality().hash(endedShops),endedAt,articleSlug,thumbnailUrl,imageUrl);

@override
String toString() {
  return 'LimitedMenu(campaignId: $campaignId, name: $name, startDate: $startDate, shops: $shops, soldOutShops: $soldOutShops, endedShops: $endedShops, endedAt: $endedAt, articleSlug: $articleSlug, thumbnailUrl: $thumbnailUrl, imageUrl: $imageUrl)';
}


}

/// @nodoc
abstract mixin class $LimitedMenuCopyWith<$Res>  {
  factory $LimitedMenuCopyWith(LimitedMenu value, $Res Function(LimitedMenu) _then) = _$LimitedMenuCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'campaign_id') String campaignId, String? name,@JsonKey(name: 'start_date') String? startDate, List<String> shops,@JsonKey(name: 'sold_out_shops') List<String> soldOutShops,@JsonKey(name: 'ended_shops') List<EndedShop> endedShops,@JsonKey(name: 'ended_at') String? endedAt,@JsonKey(name: 'article_slug') String? articleSlug,@JsonKey(name: 'thumbnail_url') String? thumbnailUrl,@JsonKey(name: 'image_url') String? imageUrl
});




}
/// @nodoc
class _$LimitedMenuCopyWithImpl<$Res>
    implements $LimitedMenuCopyWith<$Res> {
  _$LimitedMenuCopyWithImpl(this._self, this._then);

  final LimitedMenu _self;
  final $Res Function(LimitedMenu) _then;

/// Create a copy of LimitedMenu
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? campaignId = null,Object? name = freezed,Object? startDate = freezed,Object? shops = null,Object? soldOutShops = null,Object? endedShops = null,Object? endedAt = freezed,Object? articleSlug = freezed,Object? thumbnailUrl = freezed,Object? imageUrl = freezed,}) {
  return _then(_self.copyWith(
campaignId: null == campaignId ? _self.campaignId : campaignId // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as String?,shops: null == shops ? _self.shops : shops // ignore: cast_nullable_to_non_nullable
as List<String>,soldOutShops: null == soldOutShops ? _self.soldOutShops : soldOutShops // ignore: cast_nullable_to_non_nullable
as List<String>,endedShops: null == endedShops ? _self.endedShops : endedShops // ignore: cast_nullable_to_non_nullable
as List<EndedShop>,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as String?,articleSlug: freezed == articleSlug ? _self.articleSlug : articleSlug // ignore: cast_nullable_to_non_nullable
as String?,thumbnailUrl: freezed == thumbnailUrl ? _self.thumbnailUrl : thumbnailUrl // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [LimitedMenu].
extension LimitedMenuPatterns on LimitedMenu {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LimitedMenu value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LimitedMenu() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LimitedMenu value)  $default,){
final _that = this;
switch (_that) {
case _LimitedMenu():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LimitedMenu value)?  $default,){
final _that = this;
switch (_that) {
case _LimitedMenu() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'campaign_id')  String campaignId,  String? name, @JsonKey(name: 'start_date')  String? startDate,  List<String> shops, @JsonKey(name: 'sold_out_shops')  List<String> soldOutShops, @JsonKey(name: 'ended_shops')  List<EndedShop> endedShops, @JsonKey(name: 'ended_at')  String? endedAt, @JsonKey(name: 'article_slug')  String? articleSlug, @JsonKey(name: 'thumbnail_url')  String? thumbnailUrl, @JsonKey(name: 'image_url')  String? imageUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LimitedMenu() when $default != null:
return $default(_that.campaignId,_that.name,_that.startDate,_that.shops,_that.soldOutShops,_that.endedShops,_that.endedAt,_that.articleSlug,_that.thumbnailUrl,_that.imageUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'campaign_id')  String campaignId,  String? name, @JsonKey(name: 'start_date')  String? startDate,  List<String> shops, @JsonKey(name: 'sold_out_shops')  List<String> soldOutShops, @JsonKey(name: 'ended_shops')  List<EndedShop> endedShops, @JsonKey(name: 'ended_at')  String? endedAt, @JsonKey(name: 'article_slug')  String? articleSlug, @JsonKey(name: 'thumbnail_url')  String? thumbnailUrl, @JsonKey(name: 'image_url')  String? imageUrl)  $default,) {final _that = this;
switch (_that) {
case _LimitedMenu():
return $default(_that.campaignId,_that.name,_that.startDate,_that.shops,_that.soldOutShops,_that.endedShops,_that.endedAt,_that.articleSlug,_that.thumbnailUrl,_that.imageUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'campaign_id')  String campaignId,  String? name, @JsonKey(name: 'start_date')  String? startDate,  List<String> shops, @JsonKey(name: 'sold_out_shops')  List<String> soldOutShops, @JsonKey(name: 'ended_shops')  List<EndedShop> endedShops, @JsonKey(name: 'ended_at')  String? endedAt, @JsonKey(name: 'article_slug')  String? articleSlug, @JsonKey(name: 'thumbnail_url')  String? thumbnailUrl, @JsonKey(name: 'image_url')  String? imageUrl)?  $default,) {final _that = this;
switch (_that) {
case _LimitedMenu() when $default != null:
return $default(_that.campaignId,_that.name,_that.startDate,_that.shops,_that.soldOutShops,_that.endedShops,_that.endedAt,_that.articleSlug,_that.thumbnailUrl,_that.imageUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LimitedMenu implements LimitedMenu {
  const _LimitedMenu({@JsonKey(name: 'campaign_id') required this.campaignId, this.name, @JsonKey(name: 'start_date') this.startDate, final  List<String> shops = const <String>[], @JsonKey(name: 'sold_out_shops') final  List<String> soldOutShops = const <String>[], @JsonKey(name: 'ended_shops') final  List<EndedShop> endedShops = const <EndedShop>[], @JsonKey(name: 'ended_at') this.endedAt, @JsonKey(name: 'article_slug') this.articleSlug, @JsonKey(name: 'thumbnail_url') this.thumbnailUrl, @JsonKey(name: 'image_url') this.imageUrl}): _shops = shops,_soldOutShops = soldOutShops,_endedShops = endedShops;
  factory _LimitedMenu.fromJson(Map<String, dynamic> json) => _$LimitedMenuFromJson(json);

/// 識別子。**昼の品の `cms_id`**（深夜料金版は配信側で 1 つにまとめてある）。
/// とん速にキャンペーンという単位は無いが、鍵の名前は牛めしレーダーに揃えてある
@override@JsonKey(name: 'campaign_id') final  String campaignId;
/// 品名。**英語・中国語の面（`i18n/{en,zh}/app/limited.json`）では公式訳か
/// 訳語辞書の訳で、どちらも無ければ null**（日本語に落とさない。
/// tonsoku-backend-batch#286）。**null の品は地図に出さない**
/// （`MapRepository.isShown`）
@override final  String? name;
/// 発売の時刻（JST `YYYY-MM-DD HH:mm`）。
@override@JsonKey(name: 'start_date') final  String? startDate;
/// **いま掲載がある店**（売り切れ中の店も含む）。
 final  List<String> _shops;
/// **いま掲載がある店**（売り切れ中の店も含む）。
@override@JsonKey() List<String> get shops {
  if (_shops is EqualUnmodifiableListView) return _shops;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_shops);
}

/// [shops] のうち、**いま売り切れの店**（15 分ごとの巡回で更新される）。
 final  List<String> _soldOutShops;
/// [shops] のうち、**いま売り切れの店**（15 分ごとの巡回で更新される）。
@override@JsonKey(name: 'sold_out_shops') List<String> get soldOutShops {
  if (_soldOutShops is EqualUnmodifiableListView) return _soldOutShops;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_soldOutShops);
}

/// 扱っていたが掲載が外れた店と、その時刻。**記事の取扱店の表の
/// 「（9/13 21時 終売）」と同じ答え**。記事になっていない品は空。
 final  List<EndedShop> _endedShops;
/// 扱っていたが掲載が外れた店と、その時刻。**記事の取扱店の表の
/// 「（9/13 21時 終売）」と同じ答え**。記事になっていない品は空。
@override@JsonKey(name: 'ended_shops') List<EndedShop> get endedShops {
  if (_endedShops is EqualUnmodifiableListView) return _endedShops;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_endedShops);
}

/// **全店で終売した時刻。売っている間は null。** 時刻が分からない品だけ
/// 日付（`YYYY-MM-DD`）で来る。
@override@JsonKey(name: 'ended_at') final  String? endedAt;
/// その品の記事（配信済みのものだけ）。
@override@JsonKey(name: 'article_slug') final  String? articleSlug;
/// 記事の一覧用サムネイル。
@override@JsonKey(name: 'thumbnail_url') final  String? thumbnailUrl;
/// 品の写真（自前の CDN に写したもの）。
@override@JsonKey(name: 'image_url') final  String? imageUrl;

/// Create a copy of LimitedMenu
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LimitedMenuCopyWith<_LimitedMenu> get copyWith => __$LimitedMenuCopyWithImpl<_LimitedMenu>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LimitedMenuToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LimitedMenu&&(identical(other.campaignId, campaignId) || other.campaignId == campaignId)&&(identical(other.name, name) || other.name == name)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&const DeepCollectionEquality().equals(other._shops, _shops)&&const DeepCollectionEquality().equals(other._soldOutShops, _soldOutShops)&&const DeepCollectionEquality().equals(other._endedShops, _endedShops)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt)&&(identical(other.articleSlug, articleSlug) || other.articleSlug == articleSlug)&&(identical(other.thumbnailUrl, thumbnailUrl) || other.thumbnailUrl == thumbnailUrl)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,campaignId,name,startDate,const DeepCollectionEquality().hash(_shops),const DeepCollectionEquality().hash(_soldOutShops),const DeepCollectionEquality().hash(_endedShops),endedAt,articleSlug,thumbnailUrl,imageUrl);

@override
String toString() {
  return 'LimitedMenu(campaignId: $campaignId, name: $name, startDate: $startDate, shops: $shops, soldOutShops: $soldOutShops, endedShops: $endedShops, endedAt: $endedAt, articleSlug: $articleSlug, thumbnailUrl: $thumbnailUrl, imageUrl: $imageUrl)';
}


}

/// @nodoc
abstract mixin class _$LimitedMenuCopyWith<$Res> implements $LimitedMenuCopyWith<$Res> {
  factory _$LimitedMenuCopyWith(_LimitedMenu value, $Res Function(_LimitedMenu) _then) = __$LimitedMenuCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'campaign_id') String campaignId, String? name,@JsonKey(name: 'start_date') String? startDate, List<String> shops,@JsonKey(name: 'sold_out_shops') List<String> soldOutShops,@JsonKey(name: 'ended_shops') List<EndedShop> endedShops,@JsonKey(name: 'ended_at') String? endedAt,@JsonKey(name: 'article_slug') String? articleSlug,@JsonKey(name: 'thumbnail_url') String? thumbnailUrl,@JsonKey(name: 'image_url') String? imageUrl
});




}
/// @nodoc
class __$LimitedMenuCopyWithImpl<$Res>
    implements _$LimitedMenuCopyWith<$Res> {
  __$LimitedMenuCopyWithImpl(this._self, this._then);

  final _LimitedMenu _self;
  final $Res Function(_LimitedMenu) _then;

/// Create a copy of LimitedMenu
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? campaignId = null,Object? name = freezed,Object? startDate = freezed,Object? shops = null,Object? soldOutShops = null,Object? endedShops = null,Object? endedAt = freezed,Object? articleSlug = freezed,Object? thumbnailUrl = freezed,Object? imageUrl = freezed,}) {
  return _then(_LimitedMenu(
campaignId: null == campaignId ? _self.campaignId : campaignId // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as String?,shops: null == shops ? _self._shops : shops // ignore: cast_nullable_to_non_nullable
as List<String>,soldOutShops: null == soldOutShops ? _self._soldOutShops : soldOutShops // ignore: cast_nullable_to_non_nullable
as List<String>,endedShops: null == endedShops ? _self._endedShops : endedShops // ignore: cast_nullable_to_non_nullable
as List<EndedShop>,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as String?,articleSlug: freezed == articleSlug ? _self.articleSlug : articleSlug // ignore: cast_nullable_to_non_nullable
as String?,thumbnailUrl: freezed == thumbnailUrl ? _self.thumbnailUrl : thumbnailUrl // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$EndedShop {

 String get code;@JsonKey(name: 'ended_at') String get endedAt;
/// Create a copy of EndedShop
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EndedShopCopyWith<EndedShop> get copyWith => _$EndedShopCopyWithImpl<EndedShop>(this as EndedShop, _$identity);

  /// Serializes this EndedShop to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EndedShop&&(identical(other.code, code) || other.code == code)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,endedAt);

@override
String toString() {
  return 'EndedShop(code: $code, endedAt: $endedAt)';
}


}

/// @nodoc
abstract mixin class $EndedShopCopyWith<$Res>  {
  factory $EndedShopCopyWith(EndedShop value, $Res Function(EndedShop) _then) = _$EndedShopCopyWithImpl;
@useResult
$Res call({
 String code,@JsonKey(name: 'ended_at') String endedAt
});




}
/// @nodoc
class _$EndedShopCopyWithImpl<$Res>
    implements $EndedShopCopyWith<$Res> {
  _$EndedShopCopyWithImpl(this._self, this._then);

  final EndedShop _self;
  final $Res Function(EndedShop) _then;

/// Create a copy of EndedShop
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? endedAt = null,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,endedAt: null == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [EndedShop].
extension EndedShopPatterns on EndedShop {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EndedShop value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EndedShop() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EndedShop value)  $default,){
final _that = this;
switch (_that) {
case _EndedShop():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EndedShop value)?  $default,){
final _that = this;
switch (_that) {
case _EndedShop() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code, @JsonKey(name: 'ended_at')  String endedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EndedShop() when $default != null:
return $default(_that.code,_that.endedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code, @JsonKey(name: 'ended_at')  String endedAt)  $default,) {final _that = this;
switch (_that) {
case _EndedShop():
return $default(_that.code,_that.endedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code, @JsonKey(name: 'ended_at')  String endedAt)?  $default,) {final _that = this;
switch (_that) {
case _EndedShop() when $default != null:
return $default(_that.code,_that.endedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EndedShop implements EndedShop {
  const _EndedShop({required this.code, @JsonKey(name: 'ended_at') required this.endedAt});
  factory _EndedShop.fromJson(Map<String, dynamic> json) => _$EndedShopFromJson(json);

@override final  String code;
@override@JsonKey(name: 'ended_at') final  String endedAt;

/// Create a copy of EndedShop
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EndedShopCopyWith<_EndedShop> get copyWith => __$EndedShopCopyWithImpl<_EndedShop>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EndedShopToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EndedShop&&(identical(other.code, code) || other.code == code)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,endedAt);

@override
String toString() {
  return 'EndedShop(code: $code, endedAt: $endedAt)';
}


}

/// @nodoc
abstract mixin class _$EndedShopCopyWith<$Res> implements $EndedShopCopyWith<$Res> {
  factory _$EndedShopCopyWith(_EndedShop value, $Res Function(_EndedShop) _then) = __$EndedShopCopyWithImpl;
@override @useResult
$Res call({
 String code,@JsonKey(name: 'ended_at') String endedAt
});




}
/// @nodoc
class __$EndedShopCopyWithImpl<$Res>
    implements _$EndedShopCopyWith<$Res> {
  __$EndedShopCopyWithImpl(this._self, this._then);

  final _EndedShop _self;
  final $Res Function(_EndedShop) _then;

/// Create a copy of EndedShop
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? endedAt = null,}) {
  return _then(_EndedShop(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,endedAt: null == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
