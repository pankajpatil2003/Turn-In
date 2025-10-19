// lib/models/content_model.dart

class ContentCreator {
  final String userId;
  final String username;
  final String? profileImageUrl;

  ContentCreator({
    required this.userId,
    required this.username,
    this.profileImageUrl,
  });

  factory ContentCreator.fromJson(Map<String, dynamic> json) {
    return ContentCreator(
      userId: json['user_is'] as String,
      username: json['username'] as String,
      profileImageUrl: json['profile'] as String?, // Assuming 'profile' is the URL
    );
  }
}

class ContentPost {
  final String contentId;
  final ContentCreator creator;
  final String contentType;
  final String? textContent;
  final String? mediaFileUrl;
  final String description;
  final List<String> tags;
  final int hypeCount;
  final int commentCount;
  final String postedBy;
  final DateTime createdAt;

  ContentPost({
    required this.contentId,
    required this.creator,
    required this.contentType,
    this.textContent,
    this.mediaFileUrl,
    required this.description,
    required this.tags,
    required this.hypeCount,
    required this.commentCount,
    required this.postedBy,
    required this.createdAt,
  });

  factory ContentPost.fromJson(Map<String, dynamic> json) {
    return ContentPost(
      contentId: json['content_id'] as String,
      creator: ContentCreator.fromJson(json['creator'] as Map<String, dynamic>),
      contentType: json['content_type'] as String,
      textContent: json['text_content'] as String?,
      mediaFileUrl: json['media_file'] as String?,
      description: json['description'] as String,
      tags: List<String>.from(json['tags'] as List),
      hypeCount: json['hype_count'] as int,
      commentCount: json['comment_count'] as int,
      postedBy: json['posted_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}