// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'article_meta.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ArticleMeta {

 String get slug; String get title; List<String> get categories; List<String> get tags; bool get published;/// 初回配信の時刻。**契約は null を許すが、配信に載るのは配信済みの記事だけ**
/// なので実際には必ず入る（web の `models/article.ts` も同じ理由で必須に
/// 狭めている）
@JsonKey(name: 'created_at') DateTime get createdAt;/// **記事の編集時刻ではなく DB 行の更新時刻。** `created_at` より前の値に
/// なりうる（web の `models/article.ts` に経緯）。「更新された」の表示に使わないこと
@JsonKey(name: 'updated_at') DateTime? get updatedAt; String get description;@JsonKey(name: 'editor_comment') String get editorComment;/// ひとことに添えるのや子の表情（`normal` / `smile` / `angry` / `confused`）。
/// **`editor_comment` が null の記事はこれも null**（配信側が揃えている）。
/// 知らない値の扱いは表示側が持つ（web の `models/expression.ts` と同じく
/// `normal` に倒す）
 String? get expression; String get thumbnail;/// 一覧用の幅 320 の webp。**配信が URL をくれる**（gyumesy は `-sm` を
/// 命名規則から導出していたが、とん速は鍵で持っている）
@JsonKey(name: 'thumbnail_sm') String get thumbnailSm;@JsonKey(name: 'thumbnail_source') String get thumbnailSource;@JsonKey(name: 'source_url') String get sourceUrl;/// 記事が生まれたきっかけ（`limited-added` / `news-post` など）。
/// **enum にせず文字列で受ける** —— 値が増えた時に落とさないため
@JsonKey(name: 'trigger_type') String get triggerType;@JsonKey(name: 'related_articles') List<String> get relatedArticles;@JsonKey(name: 'series_key') String? get seriesKey;@JsonKey(name: 'successor_slug') String? get successorSlug;
/// Create a copy of ArticleMeta
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArticleMetaCopyWith<ArticleMeta> get copyWith => _$ArticleMetaCopyWithImpl<ArticleMeta>(this as ArticleMeta, _$identity);

  /// Serializes this ArticleMeta to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArticleMeta&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other.categories, categories)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.published, published) || other.published == published)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.description, description) || other.description == description)&&(identical(other.editorComment, editorComment) || other.editorComment == editorComment)&&(identical(other.expression, expression) || other.expression == expression)&&(identical(other.thumbnail, thumbnail) || other.thumbnail == thumbnail)&&(identical(other.thumbnailSm, thumbnailSm) || other.thumbnailSm == thumbnailSm)&&(identical(other.thumbnailSource, thumbnailSource) || other.thumbnailSource == thumbnailSource)&&(identical(other.sourceUrl, sourceUrl) || other.sourceUrl == sourceUrl)&&(identical(other.triggerType, triggerType) || other.triggerType == triggerType)&&const DeepCollectionEquality().equals(other.relatedArticles, relatedArticles)&&(identical(other.seriesKey, seriesKey) || other.seriesKey == seriesKey)&&(identical(other.successorSlug, successorSlug) || other.successorSlug == successorSlug));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,slug,title,const DeepCollectionEquality().hash(categories),const DeepCollectionEquality().hash(tags),published,createdAt,updatedAt,description,editorComment,expression,thumbnail,thumbnailSm,thumbnailSource,sourceUrl,triggerType,const DeepCollectionEquality().hash(relatedArticles),seriesKey,successorSlug);

@override
String toString() {
  return 'ArticleMeta(slug: $slug, title: $title, categories: $categories, tags: $tags, published: $published, createdAt: $createdAt, updatedAt: $updatedAt, description: $description, editorComment: $editorComment, expression: $expression, thumbnail: $thumbnail, thumbnailSm: $thumbnailSm, thumbnailSource: $thumbnailSource, sourceUrl: $sourceUrl, triggerType: $triggerType, relatedArticles: $relatedArticles, seriesKey: $seriesKey, successorSlug: $successorSlug)';
}


}

/// @nodoc
abstract mixin class $ArticleMetaCopyWith<$Res>  {
  factory $ArticleMetaCopyWith(ArticleMeta value, $Res Function(ArticleMeta) _then) = _$ArticleMetaCopyWithImpl;
@useResult
$Res call({
 String slug, String title, List<String> categories, List<String> tags, bool published,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt, String description,@JsonKey(name: 'editor_comment') String editorComment, String? expression, String thumbnail,@JsonKey(name: 'thumbnail_sm') String thumbnailSm,@JsonKey(name: 'thumbnail_source') String thumbnailSource,@JsonKey(name: 'source_url') String sourceUrl,@JsonKey(name: 'trigger_type') String triggerType,@JsonKey(name: 'related_articles') List<String> relatedArticles,@JsonKey(name: 'series_key') String? seriesKey,@JsonKey(name: 'successor_slug') String? successorSlug
});




}
/// @nodoc
class _$ArticleMetaCopyWithImpl<$Res>
    implements $ArticleMetaCopyWith<$Res> {
  _$ArticleMetaCopyWithImpl(this._self, this._then);

  final ArticleMeta _self;
  final $Res Function(ArticleMeta) _then;

/// Create a copy of ArticleMeta
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? slug = null,Object? title = null,Object? categories = null,Object? tags = null,Object? published = null,Object? createdAt = null,Object? updatedAt = freezed,Object? description = null,Object? editorComment = null,Object? expression = freezed,Object? thumbnail = null,Object? thumbnailSm = null,Object? thumbnailSource = null,Object? sourceUrl = null,Object? triggerType = null,Object? relatedArticles = null,Object? seriesKey = freezed,Object? successorSlug = freezed,}) {
  return _then(_self.copyWith(
slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,categories: null == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as List<String>,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,published: null == published ? _self.published : published // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,editorComment: null == editorComment ? _self.editorComment : editorComment // ignore: cast_nullable_to_non_nullable
as String,expression: freezed == expression ? _self.expression : expression // ignore: cast_nullable_to_non_nullable
as String?,thumbnail: null == thumbnail ? _self.thumbnail : thumbnail // ignore: cast_nullable_to_non_nullable
as String,thumbnailSm: null == thumbnailSm ? _self.thumbnailSm : thumbnailSm // ignore: cast_nullable_to_non_nullable
as String,thumbnailSource: null == thumbnailSource ? _self.thumbnailSource : thumbnailSource // ignore: cast_nullable_to_non_nullable
as String,sourceUrl: null == sourceUrl ? _self.sourceUrl : sourceUrl // ignore: cast_nullable_to_non_nullable
as String,triggerType: null == triggerType ? _self.triggerType : triggerType // ignore: cast_nullable_to_non_nullable
as String,relatedArticles: null == relatedArticles ? _self.relatedArticles : relatedArticles // ignore: cast_nullable_to_non_nullable
as List<String>,seriesKey: freezed == seriesKey ? _self.seriesKey : seriesKey // ignore: cast_nullable_to_non_nullable
as String?,successorSlug: freezed == successorSlug ? _self.successorSlug : successorSlug // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ArticleMeta].
extension ArticleMetaPatterns on ArticleMeta {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArticleMeta value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArticleMeta() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArticleMeta value)  $default,){
final _that = this;
switch (_that) {
case _ArticleMeta():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArticleMeta value)?  $default,){
final _that = this;
switch (_that) {
case _ArticleMeta() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String slug,  String title,  List<String> categories,  List<String> tags,  bool published, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt,  String description, @JsonKey(name: 'editor_comment')  String editorComment,  String? expression,  String thumbnail, @JsonKey(name: 'thumbnail_sm')  String thumbnailSm, @JsonKey(name: 'thumbnail_source')  String thumbnailSource, @JsonKey(name: 'source_url')  String sourceUrl, @JsonKey(name: 'trigger_type')  String triggerType, @JsonKey(name: 'related_articles')  List<String> relatedArticles, @JsonKey(name: 'series_key')  String? seriesKey, @JsonKey(name: 'successor_slug')  String? successorSlug)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArticleMeta() when $default != null:
return $default(_that.slug,_that.title,_that.categories,_that.tags,_that.published,_that.createdAt,_that.updatedAt,_that.description,_that.editorComment,_that.expression,_that.thumbnail,_that.thumbnailSm,_that.thumbnailSource,_that.sourceUrl,_that.triggerType,_that.relatedArticles,_that.seriesKey,_that.successorSlug);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String slug,  String title,  List<String> categories,  List<String> tags,  bool published, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt,  String description, @JsonKey(name: 'editor_comment')  String editorComment,  String? expression,  String thumbnail, @JsonKey(name: 'thumbnail_sm')  String thumbnailSm, @JsonKey(name: 'thumbnail_source')  String thumbnailSource, @JsonKey(name: 'source_url')  String sourceUrl, @JsonKey(name: 'trigger_type')  String triggerType, @JsonKey(name: 'related_articles')  List<String> relatedArticles, @JsonKey(name: 'series_key')  String? seriesKey, @JsonKey(name: 'successor_slug')  String? successorSlug)  $default,) {final _that = this;
switch (_that) {
case _ArticleMeta():
return $default(_that.slug,_that.title,_that.categories,_that.tags,_that.published,_that.createdAt,_that.updatedAt,_that.description,_that.editorComment,_that.expression,_that.thumbnail,_that.thumbnailSm,_that.thumbnailSource,_that.sourceUrl,_that.triggerType,_that.relatedArticles,_that.seriesKey,_that.successorSlug);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String slug,  String title,  List<String> categories,  List<String> tags,  bool published, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt,  String description, @JsonKey(name: 'editor_comment')  String editorComment,  String? expression,  String thumbnail, @JsonKey(name: 'thumbnail_sm')  String thumbnailSm, @JsonKey(name: 'thumbnail_source')  String thumbnailSource, @JsonKey(name: 'source_url')  String sourceUrl, @JsonKey(name: 'trigger_type')  String triggerType, @JsonKey(name: 'related_articles')  List<String> relatedArticles, @JsonKey(name: 'series_key')  String? seriesKey, @JsonKey(name: 'successor_slug')  String? successorSlug)?  $default,) {final _that = this;
switch (_that) {
case _ArticleMeta() when $default != null:
return $default(_that.slug,_that.title,_that.categories,_that.tags,_that.published,_that.createdAt,_that.updatedAt,_that.description,_that.editorComment,_that.expression,_that.thumbnail,_that.thumbnailSm,_that.thumbnailSource,_that.sourceUrl,_that.triggerType,_that.relatedArticles,_that.seriesKey,_that.successorSlug);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ArticleMeta extends ArticleMeta {
  const _ArticleMeta({required this.slug, required this.title, final  List<String> categories = const <String>[], final  List<String> tags = const <String>[], this.published = true, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt, this.description = '', @JsonKey(name: 'editor_comment') this.editorComment = '', this.expression, this.thumbnail = '', @JsonKey(name: 'thumbnail_sm') this.thumbnailSm = '', @JsonKey(name: 'thumbnail_source') this.thumbnailSource = '', @JsonKey(name: 'source_url') this.sourceUrl = '', @JsonKey(name: 'trigger_type') this.triggerType = '', @JsonKey(name: 'related_articles') final  List<String> relatedArticles = const <String>[], @JsonKey(name: 'series_key') this.seriesKey, @JsonKey(name: 'successor_slug') this.successorSlug}): _categories = categories,_tags = tags,_relatedArticles = relatedArticles,super._();
  factory _ArticleMeta.fromJson(Map<String, dynamic> json) => _$ArticleMetaFromJson(json);

@override final  String slug;
@override final  String title;
 final  List<String> _categories;
@override@JsonKey() List<String> get categories {
  if (_categories is EqualUnmodifiableListView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categories);
}

 final  List<String> _tags;
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

@override@JsonKey() final  bool published;
/// 初回配信の時刻。**契約は null を許すが、配信に載るのは配信済みの記事だけ**
/// なので実際には必ず入る（web の `models/article.ts` も同じ理由で必須に
/// 狭めている）
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
/// **記事の編集時刻ではなく DB 行の更新時刻。** `created_at` より前の値に
/// なりうる（web の `models/article.ts` に経緯）。「更新された」の表示に使わないこと
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;
@override@JsonKey() final  String description;
@override@JsonKey(name: 'editor_comment') final  String editorComment;
/// ひとことに添えるのや子の表情（`normal` / `smile` / `angry` / `confused`）。
/// **`editor_comment` が null の記事はこれも null**（配信側が揃えている）。
/// 知らない値の扱いは表示側が持つ（web の `models/expression.ts` と同じく
/// `normal` に倒す）
@override final  String? expression;
@override@JsonKey() final  String thumbnail;
/// 一覧用の幅 320 の webp。**配信が URL をくれる**（gyumesy は `-sm` を
/// 命名規則から導出していたが、とん速は鍵で持っている）
@override@JsonKey(name: 'thumbnail_sm') final  String thumbnailSm;
@override@JsonKey(name: 'thumbnail_source') final  String thumbnailSource;
@override@JsonKey(name: 'source_url') final  String sourceUrl;
/// 記事が生まれたきっかけ（`limited-added` / `news-post` など）。
/// **enum にせず文字列で受ける** —— 値が増えた時に落とさないため
@override@JsonKey(name: 'trigger_type') final  String triggerType;
 final  List<String> _relatedArticles;
@override@JsonKey(name: 'related_articles') List<String> get relatedArticles {
  if (_relatedArticles is EqualUnmodifiableListView) return _relatedArticles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_relatedArticles);
}

@override@JsonKey(name: 'series_key') final  String? seriesKey;
@override@JsonKey(name: 'successor_slug') final  String? successorSlug;

/// Create a copy of ArticleMeta
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArticleMetaCopyWith<_ArticleMeta> get copyWith => __$ArticleMetaCopyWithImpl<_ArticleMeta>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ArticleMetaToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArticleMeta&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other._categories, _categories)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.published, published) || other.published == published)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.description, description) || other.description == description)&&(identical(other.editorComment, editorComment) || other.editorComment == editorComment)&&(identical(other.expression, expression) || other.expression == expression)&&(identical(other.thumbnail, thumbnail) || other.thumbnail == thumbnail)&&(identical(other.thumbnailSm, thumbnailSm) || other.thumbnailSm == thumbnailSm)&&(identical(other.thumbnailSource, thumbnailSource) || other.thumbnailSource == thumbnailSource)&&(identical(other.sourceUrl, sourceUrl) || other.sourceUrl == sourceUrl)&&(identical(other.triggerType, triggerType) || other.triggerType == triggerType)&&const DeepCollectionEquality().equals(other._relatedArticles, _relatedArticles)&&(identical(other.seriesKey, seriesKey) || other.seriesKey == seriesKey)&&(identical(other.successorSlug, successorSlug) || other.successorSlug == successorSlug));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,slug,title,const DeepCollectionEquality().hash(_categories),const DeepCollectionEquality().hash(_tags),published,createdAt,updatedAt,description,editorComment,expression,thumbnail,thumbnailSm,thumbnailSource,sourceUrl,triggerType,const DeepCollectionEquality().hash(_relatedArticles),seriesKey,successorSlug);

@override
String toString() {
  return 'ArticleMeta(slug: $slug, title: $title, categories: $categories, tags: $tags, published: $published, createdAt: $createdAt, updatedAt: $updatedAt, description: $description, editorComment: $editorComment, expression: $expression, thumbnail: $thumbnail, thumbnailSm: $thumbnailSm, thumbnailSource: $thumbnailSource, sourceUrl: $sourceUrl, triggerType: $triggerType, relatedArticles: $relatedArticles, seriesKey: $seriesKey, successorSlug: $successorSlug)';
}


}

/// @nodoc
abstract mixin class _$ArticleMetaCopyWith<$Res> implements $ArticleMetaCopyWith<$Res> {
  factory _$ArticleMetaCopyWith(_ArticleMeta value, $Res Function(_ArticleMeta) _then) = __$ArticleMetaCopyWithImpl;
@override @useResult
$Res call({
 String slug, String title, List<String> categories, List<String> tags, bool published,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt, String description,@JsonKey(name: 'editor_comment') String editorComment, String? expression, String thumbnail,@JsonKey(name: 'thumbnail_sm') String thumbnailSm,@JsonKey(name: 'thumbnail_source') String thumbnailSource,@JsonKey(name: 'source_url') String sourceUrl,@JsonKey(name: 'trigger_type') String triggerType,@JsonKey(name: 'related_articles') List<String> relatedArticles,@JsonKey(name: 'series_key') String? seriesKey,@JsonKey(name: 'successor_slug') String? successorSlug
});




}
/// @nodoc
class __$ArticleMetaCopyWithImpl<$Res>
    implements _$ArticleMetaCopyWith<$Res> {
  __$ArticleMetaCopyWithImpl(this._self, this._then);

  final _ArticleMeta _self;
  final $Res Function(_ArticleMeta) _then;

/// Create a copy of ArticleMeta
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? slug = null,Object? title = null,Object? categories = null,Object? tags = null,Object? published = null,Object? createdAt = null,Object? updatedAt = freezed,Object? description = null,Object? editorComment = null,Object? expression = freezed,Object? thumbnail = null,Object? thumbnailSm = null,Object? thumbnailSource = null,Object? sourceUrl = null,Object? triggerType = null,Object? relatedArticles = null,Object? seriesKey = freezed,Object? successorSlug = freezed,}) {
  return _then(_ArticleMeta(
slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<String>,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,published: null == published ? _self.published : published // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,editorComment: null == editorComment ? _self.editorComment : editorComment // ignore: cast_nullable_to_non_nullable
as String,expression: freezed == expression ? _self.expression : expression // ignore: cast_nullable_to_non_nullable
as String?,thumbnail: null == thumbnail ? _self.thumbnail : thumbnail // ignore: cast_nullable_to_non_nullable
as String,thumbnailSm: null == thumbnailSm ? _self.thumbnailSm : thumbnailSm // ignore: cast_nullable_to_non_nullable
as String,thumbnailSource: null == thumbnailSource ? _self.thumbnailSource : thumbnailSource // ignore: cast_nullable_to_non_nullable
as String,sourceUrl: null == sourceUrl ? _self.sourceUrl : sourceUrl // ignore: cast_nullable_to_non_nullable
as String,triggerType: null == triggerType ? _self.triggerType : triggerType // ignore: cast_nullable_to_non_nullable
as String,relatedArticles: null == relatedArticles ? _self._relatedArticles : relatedArticles // ignore: cast_nullable_to_non_nullable
as List<String>,seriesKey: freezed == seriesKey ? _self.seriesKey : seriesKey // ignore: cast_nullable_to_non_nullable
as String?,successorSlug: freezed == successorSlug ? _self.successorSlug : successorSlug // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
