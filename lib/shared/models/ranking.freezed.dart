// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ranking.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RankingPayload {

@JsonKey(name: 'computed_at') String get computedAt; Map<String, RankingWindowData> get windows;
/// Create a copy of RankingPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RankingPayloadCopyWith<RankingPayload> get copyWith => _$RankingPayloadCopyWithImpl<RankingPayload>(this as RankingPayload, _$identity);

  /// Serializes this RankingPayload to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RankingPayload&&(identical(other.computedAt, computedAt) || other.computedAt == computedAt)&&const DeepCollectionEquality().equals(other.windows, windows));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,computedAt,const DeepCollectionEquality().hash(windows));

@override
String toString() {
  return 'RankingPayload(computedAt: $computedAt, windows: $windows)';
}


}

/// @nodoc
abstract mixin class $RankingPayloadCopyWith<$Res>  {
  factory $RankingPayloadCopyWith(RankingPayload value, $Res Function(RankingPayload) _then) = _$RankingPayloadCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'computed_at') String computedAt, Map<String, RankingWindowData> windows
});




}
/// @nodoc
class _$RankingPayloadCopyWithImpl<$Res>
    implements $RankingPayloadCopyWith<$Res> {
  _$RankingPayloadCopyWithImpl(this._self, this._then);

  final RankingPayload _self;
  final $Res Function(RankingPayload) _then;

/// Create a copy of RankingPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? computedAt = null,Object? windows = null,}) {
  return _then(_self.copyWith(
computedAt: null == computedAt ? _self.computedAt : computedAt // ignore: cast_nullable_to_non_nullable
as String,windows: null == windows ? _self.windows : windows // ignore: cast_nullable_to_non_nullable
as Map<String, RankingWindowData>,
  ));
}

}


/// Adds pattern-matching-related methods to [RankingPayload].
extension RankingPayloadPatterns on RankingPayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RankingPayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RankingPayload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RankingPayload value)  $default,){
final _that = this;
switch (_that) {
case _RankingPayload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RankingPayload value)?  $default,){
final _that = this;
switch (_that) {
case _RankingPayload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'computed_at')  String computedAt,  Map<String, RankingWindowData> windows)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RankingPayload() when $default != null:
return $default(_that.computedAt,_that.windows);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'computed_at')  String computedAt,  Map<String, RankingWindowData> windows)  $default,) {final _that = this;
switch (_that) {
case _RankingPayload():
return $default(_that.computedAt,_that.windows);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'computed_at')  String computedAt,  Map<String, RankingWindowData> windows)?  $default,) {final _that = this;
switch (_that) {
case _RankingPayload() when $default != null:
return $default(_that.computedAt,_that.windows);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RankingPayload extends RankingPayload {
  const _RankingPayload({@JsonKey(name: 'computed_at') this.computedAt = '', final  Map<String, RankingWindowData> windows = const <String, RankingWindowData>{}}): _windows = windows,super._();
  factory _RankingPayload.fromJson(Map<String, dynamic> json) => _$RankingPayloadFromJson(json);

@override@JsonKey(name: 'computed_at') final  String computedAt;
 final  Map<String, RankingWindowData> _windows;
@override@JsonKey() Map<String, RankingWindowData> get windows {
  if (_windows is EqualUnmodifiableMapView) return _windows;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_windows);
}


/// Create a copy of RankingPayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RankingPayloadCopyWith<_RankingPayload> get copyWith => __$RankingPayloadCopyWithImpl<_RankingPayload>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RankingPayloadToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RankingPayload&&(identical(other.computedAt, computedAt) || other.computedAt == computedAt)&&const DeepCollectionEquality().equals(other._windows, _windows));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,computedAt,const DeepCollectionEquality().hash(_windows));

@override
String toString() {
  return 'RankingPayload(computedAt: $computedAt, windows: $windows)';
}


}

/// @nodoc
abstract mixin class _$RankingPayloadCopyWith<$Res> implements $RankingPayloadCopyWith<$Res> {
  factory _$RankingPayloadCopyWith(_RankingPayload value, $Res Function(_RankingPayload) _then) = __$RankingPayloadCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'computed_at') String computedAt, Map<String, RankingWindowData> windows
});




}
/// @nodoc
class __$RankingPayloadCopyWithImpl<$Res>
    implements _$RankingPayloadCopyWith<$Res> {
  __$RankingPayloadCopyWithImpl(this._self, this._then);

  final _RankingPayload _self;
  final $Res Function(_RankingPayload) _then;

/// Create a copy of RankingPayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? computedAt = null,Object? windows = null,}) {
  return _then(_RankingPayload(
computedAt: null == computedAt ? _self.computedAt : computedAt // ignore: cast_nullable_to_non_nullable
as String,windows: null == windows ? _self._windows : windows // ignore: cast_nullable_to_non_nullable
as Map<String, RankingWindowData>,
  ));
}


}


/// @nodoc
mixin _$RankingWindowData {

 String get start; String get end; List<RankingItem> get items;
/// Create a copy of RankingWindowData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RankingWindowDataCopyWith<RankingWindowData> get copyWith => _$RankingWindowDataCopyWithImpl<RankingWindowData>(this as RankingWindowData, _$identity);

  /// Serializes this RankingWindowData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RankingWindowData&&(identical(other.start, start) || other.start == start)&&(identical(other.end, end) || other.end == end)&&const DeepCollectionEquality().equals(other.items, items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,start,end,const DeepCollectionEquality().hash(items));

@override
String toString() {
  return 'RankingWindowData(start: $start, end: $end, items: $items)';
}


}

/// @nodoc
abstract mixin class $RankingWindowDataCopyWith<$Res>  {
  factory $RankingWindowDataCopyWith(RankingWindowData value, $Res Function(RankingWindowData) _then) = _$RankingWindowDataCopyWithImpl;
@useResult
$Res call({
 String start, String end, List<RankingItem> items
});




}
/// @nodoc
class _$RankingWindowDataCopyWithImpl<$Res>
    implements $RankingWindowDataCopyWith<$Res> {
  _$RankingWindowDataCopyWithImpl(this._self, this._then);

  final RankingWindowData _self;
  final $Res Function(RankingWindowData) _then;

/// Create a copy of RankingWindowData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? start = null,Object? end = null,Object? items = null,}) {
  return _then(_self.copyWith(
start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as String,end: null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<RankingItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [RankingWindowData].
extension RankingWindowDataPatterns on RankingWindowData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RankingWindowData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RankingWindowData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RankingWindowData value)  $default,){
final _that = this;
switch (_that) {
case _RankingWindowData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RankingWindowData value)?  $default,){
final _that = this;
switch (_that) {
case _RankingWindowData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String start,  String end,  List<RankingItem> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RankingWindowData() when $default != null:
return $default(_that.start,_that.end,_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String start,  String end,  List<RankingItem> items)  $default,) {final _that = this;
switch (_that) {
case _RankingWindowData():
return $default(_that.start,_that.end,_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String start,  String end,  List<RankingItem> items)?  $default,) {final _that = this;
switch (_that) {
case _RankingWindowData() when $default != null:
return $default(_that.start,_that.end,_that.items);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RankingWindowData implements RankingWindowData {
  const _RankingWindowData({this.start = '', this.end = '', final  List<RankingItem> items = const <RankingItem>[]}): _items = items;
  factory _RankingWindowData.fromJson(Map<String, dynamic> json) => _$RankingWindowDataFromJson(json);

@override@JsonKey() final  String start;
@override@JsonKey() final  String end;
 final  List<RankingItem> _items;
@override@JsonKey() List<RankingItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of RankingWindowData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RankingWindowDataCopyWith<_RankingWindowData> get copyWith => __$RankingWindowDataCopyWithImpl<_RankingWindowData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RankingWindowDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RankingWindowData&&(identical(other.start, start) || other.start == start)&&(identical(other.end, end) || other.end == end)&&const DeepCollectionEquality().equals(other._items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,start,end,const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'RankingWindowData(start: $start, end: $end, items: $items)';
}


}

/// @nodoc
abstract mixin class _$RankingWindowDataCopyWith<$Res> implements $RankingWindowDataCopyWith<$Res> {
  factory _$RankingWindowDataCopyWith(_RankingWindowData value, $Res Function(_RankingWindowData) _then) = __$RankingWindowDataCopyWithImpl;
@override @useResult
$Res call({
 String start, String end, List<RankingItem> items
});




}
/// @nodoc
class __$RankingWindowDataCopyWithImpl<$Res>
    implements _$RankingWindowDataCopyWith<$Res> {
  __$RankingWindowDataCopyWithImpl(this._self, this._then);

  final _RankingWindowData _self;
  final $Res Function(_RankingWindowData) _then;

/// Create a copy of RankingWindowData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? start = null,Object? end = null,Object? items = null,}) {
  return _then(_RankingWindowData(
start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as String,end: null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<RankingItem>,
  ));
}


}


/// @nodoc
mixin _$RankingItem {

 int get rank; String get slug;
/// Create a copy of RankingItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RankingItemCopyWith<RankingItem> get copyWith => _$RankingItemCopyWithImpl<RankingItem>(this as RankingItem, _$identity);

  /// Serializes this RankingItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RankingItem&&(identical(other.rank, rank) || other.rank == rank)&&(identical(other.slug, slug) || other.slug == slug));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rank,slug);

@override
String toString() {
  return 'RankingItem(rank: $rank, slug: $slug)';
}


}

/// @nodoc
abstract mixin class $RankingItemCopyWith<$Res>  {
  factory $RankingItemCopyWith(RankingItem value, $Res Function(RankingItem) _then) = _$RankingItemCopyWithImpl;
@useResult
$Res call({
 int rank, String slug
});




}
/// @nodoc
class _$RankingItemCopyWithImpl<$Res>
    implements $RankingItemCopyWith<$Res> {
  _$RankingItemCopyWithImpl(this._self, this._then);

  final RankingItem _self;
  final $Res Function(RankingItem) _then;

/// Create a copy of RankingItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rank = null,Object? slug = null,}) {
  return _then(_self.copyWith(
rank: null == rank ? _self.rank : rank // ignore: cast_nullable_to_non_nullable
as int,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [RankingItem].
extension RankingItemPatterns on RankingItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RankingItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RankingItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RankingItem value)  $default,){
final _that = this;
switch (_that) {
case _RankingItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RankingItem value)?  $default,){
final _that = this;
switch (_that) {
case _RankingItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int rank,  String slug)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RankingItem() when $default != null:
return $default(_that.rank,_that.slug);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int rank,  String slug)  $default,) {final _that = this;
switch (_that) {
case _RankingItem():
return $default(_that.rank,_that.slug);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int rank,  String slug)?  $default,) {final _that = this;
switch (_that) {
case _RankingItem() when $default != null:
return $default(_that.rank,_that.slug);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RankingItem implements RankingItem {
  const _RankingItem({required this.rank, required this.slug});
  factory _RankingItem.fromJson(Map<String, dynamic> json) => _$RankingItemFromJson(json);

@override final  int rank;
@override final  String slug;

/// Create a copy of RankingItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RankingItemCopyWith<_RankingItem> get copyWith => __$RankingItemCopyWithImpl<_RankingItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RankingItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RankingItem&&(identical(other.rank, rank) || other.rank == rank)&&(identical(other.slug, slug) || other.slug == slug));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rank,slug);

@override
String toString() {
  return 'RankingItem(rank: $rank, slug: $slug)';
}


}

/// @nodoc
abstract mixin class _$RankingItemCopyWith<$Res> implements $RankingItemCopyWith<$Res> {
  factory _$RankingItemCopyWith(_RankingItem value, $Res Function(_RankingItem) _then) = __$RankingItemCopyWithImpl;
@override @useResult
$Res call({
 int rank, String slug
});




}
/// @nodoc
class __$RankingItemCopyWithImpl<$Res>
    implements _$RankingItemCopyWith<$Res> {
  __$RankingItemCopyWithImpl(this._self, this._then);

  final _RankingItem _self;
  final $Res Function(_RankingItem) _then;

/// Create a copy of RankingItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rank = null,Object? slug = null,}) {
  return _then(_RankingItem(
rank: null == rank ? _self.rank : rank // ignore: cast_nullable_to_non_nullable
as int,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
