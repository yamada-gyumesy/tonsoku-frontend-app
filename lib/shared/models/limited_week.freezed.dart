// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'limited_week.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LimitedWeeks {

 List<LimitedWeek> get weeks;
/// Create a copy of LimitedWeeks
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LimitedWeeksCopyWith<LimitedWeeks> get copyWith => _$LimitedWeeksCopyWithImpl<LimitedWeeks>(this as LimitedWeeks, _$identity);

  /// Serializes this LimitedWeeks to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LimitedWeeks&&const DeepCollectionEquality().equals(other.weeks, weeks));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(weeks));

@override
String toString() {
  return 'LimitedWeeks(weeks: $weeks)';
}


}

/// @nodoc
abstract mixin class $LimitedWeeksCopyWith<$Res>  {
  factory $LimitedWeeksCopyWith(LimitedWeeks value, $Res Function(LimitedWeeks) _then) = _$LimitedWeeksCopyWithImpl;
@useResult
$Res call({
 List<LimitedWeek> weeks
});




}
/// @nodoc
class _$LimitedWeeksCopyWithImpl<$Res>
    implements $LimitedWeeksCopyWith<$Res> {
  _$LimitedWeeksCopyWithImpl(this._self, this._then);

  final LimitedWeeks _self;
  final $Res Function(LimitedWeeks) _then;

/// Create a copy of LimitedWeeks
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? weeks = null,}) {
  return _then(_self.copyWith(
weeks: null == weeks ? _self.weeks : weeks // ignore: cast_nullable_to_non_nullable
as List<LimitedWeek>,
  ));
}

}


/// Adds pattern-matching-related methods to [LimitedWeeks].
extension LimitedWeeksPatterns on LimitedWeeks {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LimitedWeeks value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LimitedWeeks() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LimitedWeeks value)  $default,){
final _that = this;
switch (_that) {
case _LimitedWeeks():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LimitedWeeks value)?  $default,){
final _that = this;
switch (_that) {
case _LimitedWeeks() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<LimitedWeek> weeks)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LimitedWeeks() when $default != null:
return $default(_that.weeks);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<LimitedWeek> weeks)  $default,) {final _that = this;
switch (_that) {
case _LimitedWeeks():
return $default(_that.weeks);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<LimitedWeek> weeks)?  $default,) {final _that = this;
switch (_that) {
case _LimitedWeeks() when $default != null:
return $default(_that.weeks);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LimitedWeeks implements LimitedWeeks {
  const _LimitedWeeks({final  List<LimitedWeek> weeks = const <LimitedWeek>[]}): _weeks = weeks;
  factory _LimitedWeeks.fromJson(Map<String, dynamic> json) => _$LimitedWeeksFromJson(json);

 final  List<LimitedWeek> _weeks;
@override@JsonKey() List<LimitedWeek> get weeks {
  if (_weeks is EqualUnmodifiableListView) return _weeks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_weeks);
}


/// Create a copy of LimitedWeeks
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LimitedWeeksCopyWith<_LimitedWeeks> get copyWith => __$LimitedWeeksCopyWithImpl<_LimitedWeeks>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LimitedWeeksToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LimitedWeeks&&const DeepCollectionEquality().equals(other._weeks, _weeks));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_weeks));

@override
String toString() {
  return 'LimitedWeeks(weeks: $weeks)';
}


}

/// @nodoc
abstract mixin class _$LimitedWeeksCopyWith<$Res> implements $LimitedWeeksCopyWith<$Res> {
  factory _$LimitedWeeksCopyWith(_LimitedWeeks value, $Res Function(_LimitedWeeks) _then) = __$LimitedWeeksCopyWithImpl;
@override @useResult
$Res call({
 List<LimitedWeek> weeks
});




}
/// @nodoc
class __$LimitedWeeksCopyWithImpl<$Res>
    implements _$LimitedWeeksCopyWith<$Res> {
  __$LimitedWeeksCopyWithImpl(this._self, this._then);

  final _LimitedWeeks _self;
  final $Res Function(_LimitedWeeks) _then;

/// Create a copy of LimitedWeeks
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? weeks = null,}) {
  return _then(_LimitedWeeks(
weeks: null == weeks ? _self._weeks : weeks // ignore: cast_nullable_to_non_nullable
as List<LimitedWeek>,
  ));
}


}


/// @nodoc
mixin _$LimitedWeek {

@JsonKey(name: 'week_start') String get weekStart;@JsonKey(name: 'week_end') String get weekEnd;/// **enum にせず文字列で受ける。** 知らない値が増えた時に一覧ごと
/// 読めなくなるのを避ける（知らない値は `pending` と同じく出さない）
 String get status; List<LimitedWeekItem> get items;
/// Create a copy of LimitedWeek
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LimitedWeekCopyWith<LimitedWeek> get copyWith => _$LimitedWeekCopyWithImpl<LimitedWeek>(this as LimitedWeek, _$identity);

  /// Serializes this LimitedWeek to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LimitedWeek&&(identical(other.weekStart, weekStart) || other.weekStart == weekStart)&&(identical(other.weekEnd, weekEnd) || other.weekEnd == weekEnd)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.items, items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,weekStart,weekEnd,status,const DeepCollectionEquality().hash(items));

@override
String toString() {
  return 'LimitedWeek(weekStart: $weekStart, weekEnd: $weekEnd, status: $status, items: $items)';
}


}

/// @nodoc
abstract mixin class $LimitedWeekCopyWith<$Res>  {
  factory $LimitedWeekCopyWith(LimitedWeek value, $Res Function(LimitedWeek) _then) = _$LimitedWeekCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'week_start') String weekStart,@JsonKey(name: 'week_end') String weekEnd, String status, List<LimitedWeekItem> items
});




}
/// @nodoc
class _$LimitedWeekCopyWithImpl<$Res>
    implements $LimitedWeekCopyWith<$Res> {
  _$LimitedWeekCopyWithImpl(this._self, this._then);

  final LimitedWeek _self;
  final $Res Function(LimitedWeek) _then;

/// Create a copy of LimitedWeek
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? weekStart = null,Object? weekEnd = null,Object? status = null,Object? items = null,}) {
  return _then(_self.copyWith(
weekStart: null == weekStart ? _self.weekStart : weekStart // ignore: cast_nullable_to_non_nullable
as String,weekEnd: null == weekEnd ? _self.weekEnd : weekEnd // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<LimitedWeekItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [LimitedWeek].
extension LimitedWeekPatterns on LimitedWeek {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LimitedWeek value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LimitedWeek() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LimitedWeek value)  $default,){
final _that = this;
switch (_that) {
case _LimitedWeek():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LimitedWeek value)?  $default,){
final _that = this;
switch (_that) {
case _LimitedWeek() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'week_start')  String weekStart, @JsonKey(name: 'week_end')  String weekEnd,  String status,  List<LimitedWeekItem> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LimitedWeek() when $default != null:
return $default(_that.weekStart,_that.weekEnd,_that.status,_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'week_start')  String weekStart, @JsonKey(name: 'week_end')  String weekEnd,  String status,  List<LimitedWeekItem> items)  $default,) {final _that = this;
switch (_that) {
case _LimitedWeek():
return $default(_that.weekStart,_that.weekEnd,_that.status,_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'week_start')  String weekStart, @JsonKey(name: 'week_end')  String weekEnd,  String status,  List<LimitedWeekItem> items)?  $default,) {final _that = this;
switch (_that) {
case _LimitedWeek() when $default != null:
return $default(_that.weekStart,_that.weekEnd,_that.status,_that.items);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LimitedWeek extends LimitedWeek {
  const _LimitedWeek({@JsonKey(name: 'week_start') required this.weekStart, @JsonKey(name: 'week_end') required this.weekEnd, required this.status, final  List<LimitedWeekItem> items = const <LimitedWeekItem>[]}): _items = items,super._();
  factory _LimitedWeek.fromJson(Map<String, dynamic> json) => _$LimitedWeekFromJson(json);

@override@JsonKey(name: 'week_start') final  String weekStart;
@override@JsonKey(name: 'week_end') final  String weekEnd;
/// **enum にせず文字列で受ける。** 知らない値が増えた時に一覧ごと
/// 読めなくなるのを避ける（知らない値は `pending` と同じく出さない）
@override final  String status;
 final  List<LimitedWeekItem> _items;
@override@JsonKey() List<LimitedWeekItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of LimitedWeek
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LimitedWeekCopyWith<_LimitedWeek> get copyWith => __$LimitedWeekCopyWithImpl<_LimitedWeek>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LimitedWeekToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LimitedWeek&&(identical(other.weekStart, weekStart) || other.weekStart == weekStart)&&(identical(other.weekEnd, weekEnd) || other.weekEnd == weekEnd)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,weekStart,weekEnd,status,const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'LimitedWeek(weekStart: $weekStart, weekEnd: $weekEnd, status: $status, items: $items)';
}


}

/// @nodoc
abstract mixin class _$LimitedWeekCopyWith<$Res> implements $LimitedWeekCopyWith<$Res> {
  factory _$LimitedWeekCopyWith(_LimitedWeek value, $Res Function(_LimitedWeek) _then) = __$LimitedWeekCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'week_start') String weekStart,@JsonKey(name: 'week_end') String weekEnd, String status, List<LimitedWeekItem> items
});




}
/// @nodoc
class __$LimitedWeekCopyWithImpl<$Res>
    implements _$LimitedWeekCopyWith<$Res> {
  __$LimitedWeekCopyWithImpl(this._self, this._then);

  final _LimitedWeek _self;
  final $Res Function(_LimitedWeek) _then;

/// Create a copy of LimitedWeek
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? weekStart = null,Object? weekEnd = null,Object? status = null,Object? items = null,}) {
  return _then(_LimitedWeek(
weekStart: null == weekStart ? _self.weekStart : weekStart // ignore: cast_nullable_to_non_nullable
as String,weekEnd: null == weekEnd ? _self.weekEnd : weekEnd // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<LimitedWeekItem>,
  ));
}


}


/// @nodoc
mixin _$LimitedWeekItem {

@JsonKey(name: 'cms_id') String get cmsId;/// 品名。ロケール別の面では公式訳（無ければ日本語）
 String get name;@JsonKey(name: 'image_url') String get imageUrl;/// 配信済みの記事だけ。無ければ null
@JsonKey(name: 'article_slug') String? get articleSlug;/// 取扱店を確定した時点の数。**常に `shops_live + shops_ended`**
@JsonKey(name: 'shop_count') int get shopCount;/// いま売っている店の数。**全店で終売した品（`ended_at` あり）は 0**
@JsonKey(name: 'shops_live') int get shopsLive;/// 売り終わった店の数
@JsonKey(name: 'shops_ended') int get shopsEnded;/// 全店から消えて終売が確定した日。売っている間と、分からない間は null
@JsonKey(name: 'ended_at') String? get endedAt;
/// Create a copy of LimitedWeekItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LimitedWeekItemCopyWith<LimitedWeekItem> get copyWith => _$LimitedWeekItemCopyWithImpl<LimitedWeekItem>(this as LimitedWeekItem, _$identity);

  /// Serializes this LimitedWeekItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LimitedWeekItem&&(identical(other.cmsId, cmsId) || other.cmsId == cmsId)&&(identical(other.name, name) || other.name == name)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.articleSlug, articleSlug) || other.articleSlug == articleSlug)&&(identical(other.shopCount, shopCount) || other.shopCount == shopCount)&&(identical(other.shopsLive, shopsLive) || other.shopsLive == shopsLive)&&(identical(other.shopsEnded, shopsEnded) || other.shopsEnded == shopsEnded)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,cmsId,name,imageUrl,articleSlug,shopCount,shopsLive,shopsEnded,endedAt);

@override
String toString() {
  return 'LimitedWeekItem(cmsId: $cmsId, name: $name, imageUrl: $imageUrl, articleSlug: $articleSlug, shopCount: $shopCount, shopsLive: $shopsLive, shopsEnded: $shopsEnded, endedAt: $endedAt)';
}


}

/// @nodoc
abstract mixin class $LimitedWeekItemCopyWith<$Res>  {
  factory $LimitedWeekItemCopyWith(LimitedWeekItem value, $Res Function(LimitedWeekItem) _then) = _$LimitedWeekItemCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'cms_id') String cmsId, String name,@JsonKey(name: 'image_url') String imageUrl,@JsonKey(name: 'article_slug') String? articleSlug,@JsonKey(name: 'shop_count') int shopCount,@JsonKey(name: 'shops_live') int shopsLive,@JsonKey(name: 'shops_ended') int shopsEnded,@JsonKey(name: 'ended_at') String? endedAt
});




}
/// @nodoc
class _$LimitedWeekItemCopyWithImpl<$Res>
    implements $LimitedWeekItemCopyWith<$Res> {
  _$LimitedWeekItemCopyWithImpl(this._self, this._then);

  final LimitedWeekItem _self;
  final $Res Function(LimitedWeekItem) _then;

/// Create a copy of LimitedWeekItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cmsId = null,Object? name = null,Object? imageUrl = null,Object? articleSlug = freezed,Object? shopCount = null,Object? shopsLive = null,Object? shopsEnded = null,Object? endedAt = freezed,}) {
  return _then(_self.copyWith(
cmsId: null == cmsId ? _self.cmsId : cmsId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,imageUrl: null == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String,articleSlug: freezed == articleSlug ? _self.articleSlug : articleSlug // ignore: cast_nullable_to_non_nullable
as String?,shopCount: null == shopCount ? _self.shopCount : shopCount // ignore: cast_nullable_to_non_nullable
as int,shopsLive: null == shopsLive ? _self.shopsLive : shopsLive // ignore: cast_nullable_to_non_nullable
as int,shopsEnded: null == shopsEnded ? _self.shopsEnded : shopsEnded // ignore: cast_nullable_to_non_nullable
as int,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [LimitedWeekItem].
extension LimitedWeekItemPatterns on LimitedWeekItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LimitedWeekItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LimitedWeekItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LimitedWeekItem value)  $default,){
final _that = this;
switch (_that) {
case _LimitedWeekItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LimitedWeekItem value)?  $default,){
final _that = this;
switch (_that) {
case _LimitedWeekItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'cms_id')  String cmsId,  String name, @JsonKey(name: 'image_url')  String imageUrl, @JsonKey(name: 'article_slug')  String? articleSlug, @JsonKey(name: 'shop_count')  int shopCount, @JsonKey(name: 'shops_live')  int shopsLive, @JsonKey(name: 'shops_ended')  int shopsEnded, @JsonKey(name: 'ended_at')  String? endedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LimitedWeekItem() when $default != null:
return $default(_that.cmsId,_that.name,_that.imageUrl,_that.articleSlug,_that.shopCount,_that.shopsLive,_that.shopsEnded,_that.endedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'cms_id')  String cmsId,  String name, @JsonKey(name: 'image_url')  String imageUrl, @JsonKey(name: 'article_slug')  String? articleSlug, @JsonKey(name: 'shop_count')  int shopCount, @JsonKey(name: 'shops_live')  int shopsLive, @JsonKey(name: 'shops_ended')  int shopsEnded, @JsonKey(name: 'ended_at')  String? endedAt)  $default,) {final _that = this;
switch (_that) {
case _LimitedWeekItem():
return $default(_that.cmsId,_that.name,_that.imageUrl,_that.articleSlug,_that.shopCount,_that.shopsLive,_that.shopsEnded,_that.endedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'cms_id')  String cmsId,  String name, @JsonKey(name: 'image_url')  String imageUrl, @JsonKey(name: 'article_slug')  String? articleSlug, @JsonKey(name: 'shop_count')  int shopCount, @JsonKey(name: 'shops_live')  int shopsLive, @JsonKey(name: 'shops_ended')  int shopsEnded, @JsonKey(name: 'ended_at')  String? endedAt)?  $default,) {final _that = this;
switch (_that) {
case _LimitedWeekItem() when $default != null:
return $default(_that.cmsId,_that.name,_that.imageUrl,_that.articleSlug,_that.shopCount,_that.shopsLive,_that.shopsEnded,_that.endedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LimitedWeekItem extends LimitedWeekItem {
  const _LimitedWeekItem({@JsonKey(name: 'cms_id') required this.cmsId, required this.name, @JsonKey(name: 'image_url') this.imageUrl = '', @JsonKey(name: 'article_slug') this.articleSlug, @JsonKey(name: 'shop_count') this.shopCount = 0, @JsonKey(name: 'shops_live') this.shopsLive = 0, @JsonKey(name: 'shops_ended') this.shopsEnded = 0, @JsonKey(name: 'ended_at') this.endedAt}): super._();
  factory _LimitedWeekItem.fromJson(Map<String, dynamic> json) => _$LimitedWeekItemFromJson(json);

@override@JsonKey(name: 'cms_id') final  String cmsId;
/// 品名。ロケール別の面では公式訳（無ければ日本語）
@override final  String name;
@override@JsonKey(name: 'image_url') final  String imageUrl;
/// 配信済みの記事だけ。無ければ null
@override@JsonKey(name: 'article_slug') final  String? articleSlug;
/// 取扱店を確定した時点の数。**常に `shops_live + shops_ended`**
@override@JsonKey(name: 'shop_count') final  int shopCount;
/// いま売っている店の数。**全店で終売した品（`ended_at` あり）は 0**
@override@JsonKey(name: 'shops_live') final  int shopsLive;
/// 売り終わった店の数
@override@JsonKey(name: 'shops_ended') final  int shopsEnded;
/// 全店から消えて終売が確定した日。売っている間と、分からない間は null
@override@JsonKey(name: 'ended_at') final  String? endedAt;

/// Create a copy of LimitedWeekItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LimitedWeekItemCopyWith<_LimitedWeekItem> get copyWith => __$LimitedWeekItemCopyWithImpl<_LimitedWeekItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LimitedWeekItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LimitedWeekItem&&(identical(other.cmsId, cmsId) || other.cmsId == cmsId)&&(identical(other.name, name) || other.name == name)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.articleSlug, articleSlug) || other.articleSlug == articleSlug)&&(identical(other.shopCount, shopCount) || other.shopCount == shopCount)&&(identical(other.shopsLive, shopsLive) || other.shopsLive == shopsLive)&&(identical(other.shopsEnded, shopsEnded) || other.shopsEnded == shopsEnded)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,cmsId,name,imageUrl,articleSlug,shopCount,shopsLive,shopsEnded,endedAt);

@override
String toString() {
  return 'LimitedWeekItem(cmsId: $cmsId, name: $name, imageUrl: $imageUrl, articleSlug: $articleSlug, shopCount: $shopCount, shopsLive: $shopsLive, shopsEnded: $shopsEnded, endedAt: $endedAt)';
}


}

/// @nodoc
abstract mixin class _$LimitedWeekItemCopyWith<$Res> implements $LimitedWeekItemCopyWith<$Res> {
  factory _$LimitedWeekItemCopyWith(_LimitedWeekItem value, $Res Function(_LimitedWeekItem) _then) = __$LimitedWeekItemCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'cms_id') String cmsId, String name,@JsonKey(name: 'image_url') String imageUrl,@JsonKey(name: 'article_slug') String? articleSlug,@JsonKey(name: 'shop_count') int shopCount,@JsonKey(name: 'shops_live') int shopsLive,@JsonKey(name: 'shops_ended') int shopsEnded,@JsonKey(name: 'ended_at') String? endedAt
});




}
/// @nodoc
class __$LimitedWeekItemCopyWithImpl<$Res>
    implements _$LimitedWeekItemCopyWith<$Res> {
  __$LimitedWeekItemCopyWithImpl(this._self, this._then);

  final _LimitedWeekItem _self;
  final $Res Function(_LimitedWeekItem) _then;

/// Create a copy of LimitedWeekItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? cmsId = null,Object? name = null,Object? imageUrl = null,Object? articleSlug = freezed,Object? shopCount = null,Object? shopsLive = null,Object? shopsEnded = null,Object? endedAt = freezed,}) {
  return _then(_LimitedWeekItem(
cmsId: null == cmsId ? _self.cmsId : cmsId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,imageUrl: null == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String,articleSlug: freezed == articleSlug ? _self.articleSlug : articleSlug // ignore: cast_nullable_to_non_nullable
as String?,shopCount: null == shopCount ? _self.shopCount : shopCount // ignore: cast_nullable_to_non_nullable
as int,shopsLive: null == shopsLive ? _self.shopsLive : shopsLive // ignore: cast_nullable_to_non_nullable
as int,shopsEnded: null == shopsEnded ? _self.shopsEnded : shopsEnded // ignore: cast_nullable_to_non_nullable
as int,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
