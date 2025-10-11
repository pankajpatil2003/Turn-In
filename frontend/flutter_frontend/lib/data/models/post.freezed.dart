// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'post.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Post {

// 1. IDENTIFIERS AND RELATIONSHIPS
// Maps to content_id (UUID)
@JsonKey(name: 'content_id') String get id;// Maps to the 'creator' foreign key
 User get creator;// Assuming User is Freezed/JsonSerializable
// 2. CONTENT TYPE AND DATA
// content_type
@JsonKey(name: 'content_type') String get contentType;// text_content
@JsonKey(name: 'text_content') String? get content;// Nullable fields
// media_file (Django sends the URL to the file)
@JsonKey(name: 'media_file') String? get mediaUrl;// 3. METADATA AND CREATOR
// posted_by (e.g., 'USER', 'STAFF', 'ADMIN')
@JsonKey(name: 'posted_by') String get postedBy; String get description;// tags (ArrayField in Django, List<String> in Dart)
 List<String> get tags;// 4. STATUS AND TIME
@JsonKey(name: 'created_at') DateTime get createdAt; bool get updated;@JsonKey(name: 'updated_at') DateTime get updatedAt;// 5. INTERACTIONS (Crucial for FeedNotifier logic)
@JsonKey(name: 'hype_count') int get hypeCount;// Whether the *current* user has hyped this post
@JsonKey(name: 'is_hyped') bool get isHyped;@JsonKey(name: 'comment_count') int get commentCount;
/// Create a copy of Post
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PostCopyWith<Post> get copyWith => _$PostCopyWithImpl<Post>(this as Post, _$identity);

  /// Serializes this Post to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Post&&(identical(other.id, id) || other.id == id)&&(identical(other.creator, creator) || other.creator == creator)&&(identical(other.contentType, contentType) || other.contentType == contentType)&&(identical(other.content, content) || other.content == content)&&(identical(other.mediaUrl, mediaUrl) || other.mediaUrl == mediaUrl)&&(identical(other.postedBy, postedBy) || other.postedBy == postedBy)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updated, updated) || other.updated == updated)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.hypeCount, hypeCount) || other.hypeCount == hypeCount)&&(identical(other.isHyped, isHyped) || other.isHyped == isHyped)&&(identical(other.commentCount, commentCount) || other.commentCount == commentCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,creator,contentType,content,mediaUrl,postedBy,description,const DeepCollectionEquality().hash(tags),createdAt,updated,updatedAt,hypeCount,isHyped,commentCount);

@override
String toString() {
  return 'Post(id: $id, creator: $creator, contentType: $contentType, content: $content, mediaUrl: $mediaUrl, postedBy: $postedBy, description: $description, tags: $tags, createdAt: $createdAt, updated: $updated, updatedAt: $updatedAt, hypeCount: $hypeCount, isHyped: $isHyped, commentCount: $commentCount)';
}


}

/// @nodoc
abstract mixin class $PostCopyWith<$Res>  {
  factory $PostCopyWith(Post value, $Res Function(Post) _then) = _$PostCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'content_id') String id, User creator,@JsonKey(name: 'content_type') String contentType,@JsonKey(name: 'text_content') String? content,@JsonKey(name: 'media_file') String? mediaUrl,@JsonKey(name: 'posted_by') String postedBy, String description, List<String> tags,@JsonKey(name: 'created_at') DateTime createdAt, bool updated,@JsonKey(name: 'updated_at') DateTime updatedAt,@JsonKey(name: 'hype_count') int hypeCount,@JsonKey(name: 'is_hyped') bool isHyped,@JsonKey(name: 'comment_count') int commentCount
});




}
/// @nodoc
class _$PostCopyWithImpl<$Res>
    implements $PostCopyWith<$Res> {
  _$PostCopyWithImpl(this._self, this._then);

  final Post _self;
  final $Res Function(Post) _then;

/// Create a copy of Post
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? creator = null,Object? contentType = null,Object? content = freezed,Object? mediaUrl = freezed,Object? postedBy = null,Object? description = null,Object? tags = null,Object? createdAt = null,Object? updated = null,Object? updatedAt = null,Object? hypeCount = null,Object? isHyped = null,Object? commentCount = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,creator: null == creator ? _self.creator : creator // ignore: cast_nullable_to_non_nullable
as User,contentType: null == contentType ? _self.contentType : contentType // ignore: cast_nullable_to_non_nullable
as String,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,mediaUrl: freezed == mediaUrl ? _self.mediaUrl : mediaUrl // ignore: cast_nullable_to_non_nullable
as String?,postedBy: null == postedBy ? _self.postedBy : postedBy // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updated: null == updated ? _self.updated : updated // ignore: cast_nullable_to_non_nullable
as bool,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,hypeCount: null == hypeCount ? _self.hypeCount : hypeCount // ignore: cast_nullable_to_non_nullable
as int,isHyped: null == isHyped ? _self.isHyped : isHyped // ignore: cast_nullable_to_non_nullable
as bool,commentCount: null == commentCount ? _self.commentCount : commentCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Post].
extension PostPatterns on Post {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Post value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Post() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Post value)  $default,){
final _that = this;
switch (_that) {
case _Post():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Post value)?  $default,){
final _that = this;
switch (_that) {
case _Post() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'content_id')  String id,  User creator, @JsonKey(name: 'content_type')  String contentType, @JsonKey(name: 'text_content')  String? content, @JsonKey(name: 'media_file')  String? mediaUrl, @JsonKey(name: 'posted_by')  String postedBy,  String description,  List<String> tags, @JsonKey(name: 'created_at')  DateTime createdAt,  bool updated, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'hype_count')  int hypeCount, @JsonKey(name: 'is_hyped')  bool isHyped, @JsonKey(name: 'comment_count')  int commentCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Post() when $default != null:
return $default(_that.id,_that.creator,_that.contentType,_that.content,_that.mediaUrl,_that.postedBy,_that.description,_that.tags,_that.createdAt,_that.updated,_that.updatedAt,_that.hypeCount,_that.isHyped,_that.commentCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'content_id')  String id,  User creator, @JsonKey(name: 'content_type')  String contentType, @JsonKey(name: 'text_content')  String? content, @JsonKey(name: 'media_file')  String? mediaUrl, @JsonKey(name: 'posted_by')  String postedBy,  String description,  List<String> tags, @JsonKey(name: 'created_at')  DateTime createdAt,  bool updated, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'hype_count')  int hypeCount, @JsonKey(name: 'is_hyped')  bool isHyped, @JsonKey(name: 'comment_count')  int commentCount)  $default,) {final _that = this;
switch (_that) {
case _Post():
return $default(_that.id,_that.creator,_that.contentType,_that.content,_that.mediaUrl,_that.postedBy,_that.description,_that.tags,_that.createdAt,_that.updated,_that.updatedAt,_that.hypeCount,_that.isHyped,_that.commentCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'content_id')  String id,  User creator, @JsonKey(name: 'content_type')  String contentType, @JsonKey(name: 'text_content')  String? content, @JsonKey(name: 'media_file')  String? mediaUrl, @JsonKey(name: 'posted_by')  String postedBy,  String description,  List<String> tags, @JsonKey(name: 'created_at')  DateTime createdAt,  bool updated, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'hype_count')  int hypeCount, @JsonKey(name: 'is_hyped')  bool isHyped, @JsonKey(name: 'comment_count')  int commentCount)?  $default,) {final _that = this;
switch (_that) {
case _Post() when $default != null:
return $default(_that.id,_that.creator,_that.contentType,_that.content,_that.mediaUrl,_that.postedBy,_that.description,_that.tags,_that.createdAt,_that.updated,_that.updatedAt,_that.hypeCount,_that.isHyped,_that.commentCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Post implements Post {
  const _Post({@JsonKey(name: 'content_id') required this.id, required this.creator, @JsonKey(name: 'content_type') required this.contentType, @JsonKey(name: 'text_content') this.content, @JsonKey(name: 'media_file') this.mediaUrl, @JsonKey(name: 'posted_by') this.postedBy = 'USER', required this.description, final  List<String> tags = const [], @JsonKey(name: 'created_at') required this.createdAt, this.updated = false, @JsonKey(name: 'updated_at') required this.updatedAt, @JsonKey(name: 'hype_count') this.hypeCount = 0, @JsonKey(name: 'is_hyped') this.isHyped = false, @JsonKey(name: 'comment_count') this.commentCount = 0}): _tags = tags;
  factory _Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);

// 1. IDENTIFIERS AND RELATIONSHIPS
// Maps to content_id (UUID)
@override@JsonKey(name: 'content_id') final  String id;
// Maps to the 'creator' foreign key
@override final  User creator;
// Assuming User is Freezed/JsonSerializable
// 2. CONTENT TYPE AND DATA
// content_type
@override@JsonKey(name: 'content_type') final  String contentType;
// text_content
@override@JsonKey(name: 'text_content') final  String? content;
// Nullable fields
// media_file (Django sends the URL to the file)
@override@JsonKey(name: 'media_file') final  String? mediaUrl;
// 3. METADATA AND CREATOR
// posted_by (e.g., 'USER', 'STAFF', 'ADMIN')
@override@JsonKey(name: 'posted_by') final  String postedBy;
@override final  String description;
// tags (ArrayField in Django, List<String> in Dart)
 final  List<String> _tags;
// tags (ArrayField in Django, List<String> in Dart)
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

// 4. STATUS AND TIME
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey() final  bool updated;
@override@JsonKey(name: 'updated_at') final  DateTime updatedAt;
// 5. INTERACTIONS (Crucial for FeedNotifier logic)
@override@JsonKey(name: 'hype_count') final  int hypeCount;
// Whether the *current* user has hyped this post
@override@JsonKey(name: 'is_hyped') final  bool isHyped;
@override@JsonKey(name: 'comment_count') final  int commentCount;

/// Create a copy of Post
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PostCopyWith<_Post> get copyWith => __$PostCopyWithImpl<_Post>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PostToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Post&&(identical(other.id, id) || other.id == id)&&(identical(other.creator, creator) || other.creator == creator)&&(identical(other.contentType, contentType) || other.contentType == contentType)&&(identical(other.content, content) || other.content == content)&&(identical(other.mediaUrl, mediaUrl) || other.mediaUrl == mediaUrl)&&(identical(other.postedBy, postedBy) || other.postedBy == postedBy)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updated, updated) || other.updated == updated)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.hypeCount, hypeCount) || other.hypeCount == hypeCount)&&(identical(other.isHyped, isHyped) || other.isHyped == isHyped)&&(identical(other.commentCount, commentCount) || other.commentCount == commentCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,creator,contentType,content,mediaUrl,postedBy,description,const DeepCollectionEquality().hash(_tags),createdAt,updated,updatedAt,hypeCount,isHyped,commentCount);

@override
String toString() {
  return 'Post(id: $id, creator: $creator, contentType: $contentType, content: $content, mediaUrl: $mediaUrl, postedBy: $postedBy, description: $description, tags: $tags, createdAt: $createdAt, updated: $updated, updatedAt: $updatedAt, hypeCount: $hypeCount, isHyped: $isHyped, commentCount: $commentCount)';
}


}

/// @nodoc
abstract mixin class _$PostCopyWith<$Res> implements $PostCopyWith<$Res> {
  factory _$PostCopyWith(_Post value, $Res Function(_Post) _then) = __$PostCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'content_id') String id, User creator,@JsonKey(name: 'content_type') String contentType,@JsonKey(name: 'text_content') String? content,@JsonKey(name: 'media_file') String? mediaUrl,@JsonKey(name: 'posted_by') String postedBy, String description, List<String> tags,@JsonKey(name: 'created_at') DateTime createdAt, bool updated,@JsonKey(name: 'updated_at') DateTime updatedAt,@JsonKey(name: 'hype_count') int hypeCount,@JsonKey(name: 'is_hyped') bool isHyped,@JsonKey(name: 'comment_count') int commentCount
});




}
/// @nodoc
class __$PostCopyWithImpl<$Res>
    implements _$PostCopyWith<$Res> {
  __$PostCopyWithImpl(this._self, this._then);

  final _Post _self;
  final $Res Function(_Post) _then;

/// Create a copy of Post
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? creator = null,Object? contentType = null,Object? content = freezed,Object? mediaUrl = freezed,Object? postedBy = null,Object? description = null,Object? tags = null,Object? createdAt = null,Object? updated = null,Object? updatedAt = null,Object? hypeCount = null,Object? isHyped = null,Object? commentCount = null,}) {
  return _then(_Post(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,creator: null == creator ? _self.creator : creator // ignore: cast_nullable_to_non_nullable
as User,contentType: null == contentType ? _self.contentType : contentType // ignore: cast_nullable_to_non_nullable
as String,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,mediaUrl: freezed == mediaUrl ? _self.mediaUrl : mediaUrl // ignore: cast_nullable_to_non_nullable
as String?,postedBy: null == postedBy ? _self.postedBy : postedBy // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updated: null == updated ? _self.updated : updated // ignore: cast_nullable_to_non_nullable
as bool,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,hypeCount: null == hypeCount ? _self.hypeCount : hypeCount // ignore: cast_nullable_to_non_nullable
as int,isHyped: null == isHyped ? _self.isHyped : isHyped // ignore: cast_nullable_to_non_nullable
as bool,commentCount: null == commentCount ? _self.commentCount : commentCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
