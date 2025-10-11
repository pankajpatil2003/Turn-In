// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Post _$PostFromJson(Map<String, dynamic> json) => _Post(
  id: json['content_id'] as String,
  creator: User.fromJson(json['creator'] as Map<String, dynamic>),
  contentType: json['content_type'] as String,
  content: json['text_content'] as String?,
  mediaUrl: json['media_file'] as String?,
  postedBy: json['posted_by'] as String? ?? 'USER',
  description: json['description'] as String,
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  createdAt: DateTime.parse(json['created_at'] as String),
  updated: json['updated'] as bool? ?? false,
  updatedAt: DateTime.parse(json['updated_at'] as String),
  hypeCount: (json['hype_count'] as num?)?.toInt() ?? 0,
  isHyped: json['is_hyped'] as bool? ?? false,
  commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$PostToJson(_Post instance) => <String, dynamic>{
  'content_id': instance.id,
  'creator': instance.creator,
  'content_type': instance.contentType,
  'text_content': instance.content,
  'media_file': instance.mediaUrl,
  'posted_by': instance.postedBy,
  'description': instance.description,
  'tags': instance.tags,
  'created_at': instance.createdAt.toIso8601String(),
  'updated': instance.updated,
  'updated_at': instance.updatedAt.toIso8601String(),
  'hype_count': instance.hypeCount,
  'is_hyped': instance.isHyped,
  'comment_count': instance.commentCount,
};
