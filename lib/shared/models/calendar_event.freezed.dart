// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'calendar_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CalendarEvent {

 String get id; String get title; String get category;@JsonKey(name: 'start_date') String get startDate;/// 終了日。単日の予定や終わりが決まっていないものは null。
@JsonKey(name: 'end_date') String? get endDate;/// 終わりが決まっていない継続中の予定。
 bool get ongoing;/// 発売前の予告か（web の `preview`）。**いまは常に false。**
 bool get preview; List<String> get tags;/// 対応する記事。**無い予定がある**（本番の 23 件中 8 件）ので null を想定する。
@JsonKey(name: 'article_slug') String? get articleSlug;/// 公式ソースの URL。無ければ null。
@JsonKey(name: 'source_url') String? get sourceUrl;/// 公式ソースの表示ラベル。**画面には出さない**（全ロケールで日本語のまま
/// 届くので、`SourceChip` は固定語の「公式」を出す。gyumesy と同じ）。
@JsonKey(name: 'source_label') String? get sourceLabel;
/// Create a copy of CalendarEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CalendarEventCopyWith<CalendarEvent> get copyWith => _$CalendarEventCopyWithImpl<CalendarEvent>(this as CalendarEvent, _$identity);

  /// Serializes this CalendarEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CalendarEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.category, category) || other.category == category)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.ongoing, ongoing) || other.ongoing == ongoing)&&(identical(other.preview, preview) || other.preview == preview)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.articleSlug, articleSlug) || other.articleSlug == articleSlug)&&(identical(other.sourceUrl, sourceUrl) || other.sourceUrl == sourceUrl)&&(identical(other.sourceLabel, sourceLabel) || other.sourceLabel == sourceLabel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,category,startDate,endDate,ongoing,preview,const DeepCollectionEquality().hash(tags),articleSlug,sourceUrl,sourceLabel);

@override
String toString() {
  return 'CalendarEvent(id: $id, title: $title, category: $category, startDate: $startDate, endDate: $endDate, ongoing: $ongoing, preview: $preview, tags: $tags, articleSlug: $articleSlug, sourceUrl: $sourceUrl, sourceLabel: $sourceLabel)';
}


}

/// @nodoc
abstract mixin class $CalendarEventCopyWith<$Res>  {
  factory $CalendarEventCopyWith(CalendarEvent value, $Res Function(CalendarEvent) _then) = _$CalendarEventCopyWithImpl;
@useResult
$Res call({
 String id, String title, String category,@JsonKey(name: 'start_date') String startDate,@JsonKey(name: 'end_date') String? endDate, bool ongoing, bool preview, List<String> tags,@JsonKey(name: 'article_slug') String? articleSlug,@JsonKey(name: 'source_url') String? sourceUrl,@JsonKey(name: 'source_label') String? sourceLabel
});




}
/// @nodoc
class _$CalendarEventCopyWithImpl<$Res>
    implements $CalendarEventCopyWith<$Res> {
  _$CalendarEventCopyWithImpl(this._self, this._then);

  final CalendarEvent _self;
  final $Res Function(CalendarEvent) _then;

/// Create a copy of CalendarEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? category = null,Object? startDate = null,Object? endDate = freezed,Object? ongoing = null,Object? preview = null,Object? tags = null,Object? articleSlug = freezed,Object? sourceUrl = freezed,Object? sourceLabel = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as String,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as String?,ongoing: null == ongoing ? _self.ongoing : ongoing // ignore: cast_nullable_to_non_nullable
as bool,preview: null == preview ? _self.preview : preview // ignore: cast_nullable_to_non_nullable
as bool,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,articleSlug: freezed == articleSlug ? _self.articleSlug : articleSlug // ignore: cast_nullable_to_non_nullable
as String?,sourceUrl: freezed == sourceUrl ? _self.sourceUrl : sourceUrl // ignore: cast_nullable_to_non_nullable
as String?,sourceLabel: freezed == sourceLabel ? _self.sourceLabel : sourceLabel // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CalendarEvent].
extension CalendarEventPatterns on CalendarEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CalendarEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CalendarEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CalendarEvent value)  $default,){
final _that = this;
switch (_that) {
case _CalendarEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CalendarEvent value)?  $default,){
final _that = this;
switch (_that) {
case _CalendarEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String category, @JsonKey(name: 'start_date')  String startDate, @JsonKey(name: 'end_date')  String? endDate,  bool ongoing,  bool preview,  List<String> tags, @JsonKey(name: 'article_slug')  String? articleSlug, @JsonKey(name: 'source_url')  String? sourceUrl, @JsonKey(name: 'source_label')  String? sourceLabel)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CalendarEvent() when $default != null:
return $default(_that.id,_that.title,_that.category,_that.startDate,_that.endDate,_that.ongoing,_that.preview,_that.tags,_that.articleSlug,_that.sourceUrl,_that.sourceLabel);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String category, @JsonKey(name: 'start_date')  String startDate, @JsonKey(name: 'end_date')  String? endDate,  bool ongoing,  bool preview,  List<String> tags, @JsonKey(name: 'article_slug')  String? articleSlug, @JsonKey(name: 'source_url')  String? sourceUrl, @JsonKey(name: 'source_label')  String? sourceLabel)  $default,) {final _that = this;
switch (_that) {
case _CalendarEvent():
return $default(_that.id,_that.title,_that.category,_that.startDate,_that.endDate,_that.ongoing,_that.preview,_that.tags,_that.articleSlug,_that.sourceUrl,_that.sourceLabel);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String category, @JsonKey(name: 'start_date')  String startDate, @JsonKey(name: 'end_date')  String? endDate,  bool ongoing,  bool preview,  List<String> tags, @JsonKey(name: 'article_slug')  String? articleSlug, @JsonKey(name: 'source_url')  String? sourceUrl, @JsonKey(name: 'source_label')  String? sourceLabel)?  $default,) {final _that = this;
switch (_that) {
case _CalendarEvent() when $default != null:
return $default(_that.id,_that.title,_that.category,_that.startDate,_that.endDate,_that.ongoing,_that.preview,_that.tags,_that.articleSlug,_that.sourceUrl,_that.sourceLabel);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CalendarEvent extends CalendarEvent {
  const _CalendarEvent({required this.id, required this.title, required this.category, @JsonKey(name: 'start_date') required this.startDate, @JsonKey(name: 'end_date') this.endDate, this.ongoing = false, this.preview = false, final  List<String> tags = const <String>[], @JsonKey(name: 'article_slug') this.articleSlug, @JsonKey(name: 'source_url') this.sourceUrl, @JsonKey(name: 'source_label') this.sourceLabel}): _tags = tags,super._();
  factory _CalendarEvent.fromJson(Map<String, dynamic> json) => _$CalendarEventFromJson(json);

@override final  String id;
@override final  String title;
@override final  String category;
@override@JsonKey(name: 'start_date') final  String startDate;
/// 終了日。単日の予定や終わりが決まっていないものは null。
@override@JsonKey(name: 'end_date') final  String? endDate;
/// 終わりが決まっていない継続中の予定。
@override@JsonKey() final  bool ongoing;
/// 発売前の予告か（web の `preview`）。**いまは常に false。**
@override@JsonKey() final  bool preview;
 final  List<String> _tags;
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

/// 対応する記事。**無い予定がある**（本番の 23 件中 8 件）ので null を想定する。
@override@JsonKey(name: 'article_slug') final  String? articleSlug;
/// 公式ソースの URL。無ければ null。
@override@JsonKey(name: 'source_url') final  String? sourceUrl;
/// 公式ソースの表示ラベル。**画面には出さない**（全ロケールで日本語のまま
/// 届くので、`SourceChip` は固定語の「公式」を出す。gyumesy と同じ）。
@override@JsonKey(name: 'source_label') final  String? sourceLabel;

/// Create a copy of CalendarEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CalendarEventCopyWith<_CalendarEvent> get copyWith => __$CalendarEventCopyWithImpl<_CalendarEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CalendarEventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CalendarEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.category, category) || other.category == category)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.ongoing, ongoing) || other.ongoing == ongoing)&&(identical(other.preview, preview) || other.preview == preview)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.articleSlug, articleSlug) || other.articleSlug == articleSlug)&&(identical(other.sourceUrl, sourceUrl) || other.sourceUrl == sourceUrl)&&(identical(other.sourceLabel, sourceLabel) || other.sourceLabel == sourceLabel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,category,startDate,endDate,ongoing,preview,const DeepCollectionEquality().hash(_tags),articleSlug,sourceUrl,sourceLabel);

@override
String toString() {
  return 'CalendarEvent(id: $id, title: $title, category: $category, startDate: $startDate, endDate: $endDate, ongoing: $ongoing, preview: $preview, tags: $tags, articleSlug: $articleSlug, sourceUrl: $sourceUrl, sourceLabel: $sourceLabel)';
}


}

/// @nodoc
abstract mixin class _$CalendarEventCopyWith<$Res> implements $CalendarEventCopyWith<$Res> {
  factory _$CalendarEventCopyWith(_CalendarEvent value, $Res Function(_CalendarEvent) _then) = __$CalendarEventCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String category,@JsonKey(name: 'start_date') String startDate,@JsonKey(name: 'end_date') String? endDate, bool ongoing, bool preview, List<String> tags,@JsonKey(name: 'article_slug') String? articleSlug,@JsonKey(name: 'source_url') String? sourceUrl,@JsonKey(name: 'source_label') String? sourceLabel
});




}
/// @nodoc
class __$CalendarEventCopyWithImpl<$Res>
    implements _$CalendarEventCopyWith<$Res> {
  __$CalendarEventCopyWithImpl(this._self, this._then);

  final _CalendarEvent _self;
  final $Res Function(_CalendarEvent) _then;

/// Create a copy of CalendarEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? category = null,Object? startDate = null,Object? endDate = freezed,Object? ongoing = null,Object? preview = null,Object? tags = null,Object? articleSlug = freezed,Object? sourceUrl = freezed,Object? sourceLabel = freezed,}) {
  return _then(_CalendarEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as String,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as String?,ongoing: null == ongoing ? _self.ongoing : ongoing // ignore: cast_nullable_to_non_nullable
as bool,preview: null == preview ? _self.preview : preview // ignore: cast_nullable_to_non_nullable
as bool,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,articleSlug: freezed == articleSlug ? _self.articleSlug : articleSlug // ignore: cast_nullable_to_non_nullable
as String?,sourceUrl: freezed == sourceUrl ? _self.sourceUrl : sourceUrl // ignore: cast_nullable_to_non_nullable
as String?,sourceLabel: freezed == sourceLabel ? _self.sourceLabel : sourceLabel // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$CalendarPayload {

@JsonKey(name: 'generated_at') String get generatedAt; List<CalendarEvent> get events;
/// Create a copy of CalendarPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CalendarPayloadCopyWith<CalendarPayload> get copyWith => _$CalendarPayloadCopyWithImpl<CalendarPayload>(this as CalendarPayload, _$identity);

  /// Serializes this CalendarPayload to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CalendarPayload&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt)&&const DeepCollectionEquality().equals(other.events, events));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,generatedAt,const DeepCollectionEquality().hash(events));

@override
String toString() {
  return 'CalendarPayload(generatedAt: $generatedAt, events: $events)';
}


}

/// @nodoc
abstract mixin class $CalendarPayloadCopyWith<$Res>  {
  factory $CalendarPayloadCopyWith(CalendarPayload value, $Res Function(CalendarPayload) _then) = _$CalendarPayloadCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'generated_at') String generatedAt, List<CalendarEvent> events
});




}
/// @nodoc
class _$CalendarPayloadCopyWithImpl<$Res>
    implements $CalendarPayloadCopyWith<$Res> {
  _$CalendarPayloadCopyWithImpl(this._self, this._then);

  final CalendarPayload _self;
  final $Res Function(CalendarPayload) _then;

/// Create a copy of CalendarPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? generatedAt = null,Object? events = null,}) {
  return _then(_self.copyWith(
generatedAt: null == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as String,events: null == events ? _self.events : events // ignore: cast_nullable_to_non_nullable
as List<CalendarEvent>,
  ));
}

}


/// Adds pattern-matching-related methods to [CalendarPayload].
extension CalendarPayloadPatterns on CalendarPayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CalendarPayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CalendarPayload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CalendarPayload value)  $default,){
final _that = this;
switch (_that) {
case _CalendarPayload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CalendarPayload value)?  $default,){
final _that = this;
switch (_that) {
case _CalendarPayload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'generated_at')  String generatedAt,  List<CalendarEvent> events)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CalendarPayload() when $default != null:
return $default(_that.generatedAt,_that.events);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'generated_at')  String generatedAt,  List<CalendarEvent> events)  $default,) {final _that = this;
switch (_that) {
case _CalendarPayload():
return $default(_that.generatedAt,_that.events);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'generated_at')  String generatedAt,  List<CalendarEvent> events)?  $default,) {final _that = this;
switch (_that) {
case _CalendarPayload() when $default != null:
return $default(_that.generatedAt,_that.events);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CalendarPayload implements CalendarPayload {
  const _CalendarPayload({@JsonKey(name: 'generated_at') this.generatedAt = '', final  List<CalendarEvent> events = const <CalendarEvent>[]}): _events = events;
  factory _CalendarPayload.fromJson(Map<String, dynamic> json) => _$CalendarPayloadFromJson(json);

@override@JsonKey(name: 'generated_at') final  String generatedAt;
 final  List<CalendarEvent> _events;
@override@JsonKey() List<CalendarEvent> get events {
  if (_events is EqualUnmodifiableListView) return _events;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_events);
}


/// Create a copy of CalendarPayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CalendarPayloadCopyWith<_CalendarPayload> get copyWith => __$CalendarPayloadCopyWithImpl<_CalendarPayload>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CalendarPayloadToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CalendarPayload&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt)&&const DeepCollectionEquality().equals(other._events, _events));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,generatedAt,const DeepCollectionEquality().hash(_events));

@override
String toString() {
  return 'CalendarPayload(generatedAt: $generatedAt, events: $events)';
}


}

/// @nodoc
abstract mixin class _$CalendarPayloadCopyWith<$Res> implements $CalendarPayloadCopyWith<$Res> {
  factory _$CalendarPayloadCopyWith(_CalendarPayload value, $Res Function(_CalendarPayload) _then) = __$CalendarPayloadCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'generated_at') String generatedAt, List<CalendarEvent> events
});




}
/// @nodoc
class __$CalendarPayloadCopyWithImpl<$Res>
    implements _$CalendarPayloadCopyWith<$Res> {
  __$CalendarPayloadCopyWithImpl(this._self, this._then);

  final _CalendarPayload _self;
  final $Res Function(_CalendarPayload) _then;

/// Create a copy of CalendarPayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? generatedAt = null,Object? events = null,}) {
  return _then(_CalendarPayload(
generatedAt: null == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as String,events: null == events ? _self._events : events // ignore: cast_nullable_to_non_nullable
as List<CalendarEvent>,
  ));
}


}

// dart format on
