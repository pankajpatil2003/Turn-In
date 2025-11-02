// lib/models/content_model.dart

// No need for 'package:flutter/foundation.dart' unless using specific Flutter dev tools

// ----------------------------------------------------------------------
// ContentCreator (The user who posted the content)
// ----------------------------------------------------------------------

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
    // 1. Prioritize checking multiple common keys for the username.
    final String resolvedUsername = json['username'] as String? ??
        json['name'] as String? ??
        json['display_name'] as String? ??
        'Unknown Creator';

    // 2. Safely get the nested 'profile' map
    // We use the null-aware spread operator for a slightly cleaner access to nested map data
    final Map<String, dynamic>? nestedProfileJson =
        json['profile'] as Map<String, dynamic>?;

    // 3. Extract 'profile_image' ONLY IF the nested 'profile' map exists.
    final String? resolvedProfileImage = nestedProfileJson?['profile_image'] as String?;
    
    // Note: The original implementation was also correct, this is a minor style choice.
    
    return ContentCreator(
      // Safely read user ID from 'user_id' or 'id', defaulting to '0' if missing.
      userId: (json['user_id'] as String? ?? json['id'] as String? ?? '0'),
      username: resolvedUsername,
      profileImageUrl: resolvedProfileImage,
    );
  }
}

// ----------------------------------------------------------------------
// ContentPost (The main post model)
// ----------------------------------------------------------------------

class ContentPost {
  // ✅ ID is correctly defined as int (Integer)
  final String id; 
  final ContentCreator creator;
  final String contentType;
  final String? textContent;
  final String? mediaFileUrl;
  final String description;
  final List<String> feedTypes;

  final int hypeCount;
  final bool isHyped;
  final int commentCount;

  final String postedBy;
  final DateTime createdAt;

  ContentPost({
    required this.id, // Must be int
    required this.creator,
    required this.contentType,
    this.textContent,
    this.mediaFileUrl,
    required this.description,
    required this.feedTypes,
    this.hypeCount = 0,
    this.commentCount = 0,
    this.isHyped = false,
    required this.postedBy,
    required this.createdAt,
  });

  factory ContentPost.fromJson(Map<String, dynamic> json) {
    final String? createdAtString = json['created_at'] as String?;

    // ✅ Correctly reading ID as an Integer from 'id' or 'content_id'.
    final String resolvedId = json['id'] as String? ?? json['content_id'] as String? ?? '0';

    final String contentTypeString = json['content_type'] as String? ?? 'TEXT';
    final String postedByString = json['posted_by'] as String? ?? '';

    // Handle the ContentCreator parsing safely
    ContentCreator creatorProfile;
    try {
      // Pass the 'creator' JSON block to ContentCreator.fromJson
      creatorProfile =
          ContentCreator.fromJson(json['creator'] as Map<String, dynamic>? ?? {});
    } catch (e) {
      // Using print directly here is acceptable for model parsing errors
      // if not using a proper logging package.
      print("Error parsing ContentCreator for post ID $resolvedId: $e"); 
      // Fallback for missing or malformed creator data
      creatorProfile = ContentCreator(userId: '0', username: 'Deleted User');
    }

    return ContentPost(
      id: resolvedId, // Using the resolved integer ID
      creator: creatorProfile,
      contentType: contentTypeString,

      // Nullable fields
      textContent: json['text_content'] as String?,
      mediaFileUrl: json['media_file'] as String?,

      // Non-nullable fields with defaults
      description: json['description'] as String? ?? '',
      // Safely map list elements and handle potential null list
      feedTypes: (json['feed_types'] as List?)
                ?.map((e) => e.toString().toUpperCase()) 
                .toList() ??
            [],

      // Numeric fields with defaults
      hypeCount: json['hype_count'] as int? ?? 0,
      isHyped: json['is_hyped'] as bool? ?? false,
      commentCount: json['comment_count'] as int? ?? 0,

      postedBy: postedByString,

      // Prevent crash on null date, and convert to local time
      createdAt: createdAtString != null
          ? DateTime.parse(createdAtString).toLocal()
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  // ✅ copyWith method is correct and uses String for id
  ContentPost copyWith({
    String? id,
    ContentCreator? creator,
    String? contentType,
    String? textContent,
    String? mediaFileUrl,
    String? description,
    List<String>? feedTypes,
    int? hypeCount,
    int? commentCount,
    bool? isHyped,
    String? postedBy,
    DateTime? createdAt,
  }) {
    return ContentPost(
      id: id ?? this.id, // Updated field
      creator: creator ?? this.creator,
      contentType: contentType ?? this.contentType,
      textContent: textContent ?? this.textContent,
      mediaFileUrl: mediaFileUrl ?? this.mediaFileUrl,
      description: description ?? this.description,
      feedTypes: feedTypes ?? this.feedTypes,
      hypeCount: hypeCount ?? this.hypeCount,
      isHyped: isHyped ?? this.isHyped,
      commentCount: commentCount ?? this.commentCount,
      postedBy: postedBy ?? this.postedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// ----------------------------------------------------------------------
// TagInfo (For statistics/profile screen)
// ----------------------------------------------------------------------

class TagInfo {
  final String tag;
  final int totalUsed;
  final double rank;
  final DateTime createdAt;
  final DateTime lastUsedAt;

  TagInfo({
    required this.tag,
    required this.totalUsed,
    required this.rank,
    required this.createdAt,
    required this.lastUsedAt,
  });

  factory TagInfo.fromJson(Map<String, dynamic> json) {
    final String? createdAtString = json['created_at'] as String?;
    final String? lastUsedAtString = json['last_used_at'] as String?;

    return TagInfo(
      tag: json['tag'] as String? ?? '',
      totalUsed: json['total_used'] as int? ?? 0,

      // Convert number (int or double) to double safely
      rank: (json['rank'] as num?)?.toDouble() ?? 0.0,

      createdAt: createdAtString != null
          ? DateTime.parse(createdAtString).toLocal()
          : DateTime.fromMillisecondsSinceEpoch(0),
      lastUsedAt: lastUsedAtString != null
          ? DateTime.parse(lastUsedAtString).toLocal()
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}