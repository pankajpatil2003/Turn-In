// lib/models/content_model.dart
// 🔥 FIX: TagInfo class REMOVED from this file to resolve dart(ambiguous_import) 
// You must define TagInfo in its own file (e.g., tag_model.dart) or in user_model.dart
// and import it using 'as' prefixes to keep only one definition.

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
    // 🔥 FIX: Ensure userId handles both int and String coming from the API
    final dynamic rawUserId = json['user_id'] ?? json['id'];
    String resolvedUserId;
    if (rawUserId is int) {
        resolvedUserId = rawUserId.toString();
    } else {
        resolvedUserId = rawUserId as String? ?? '0';
    }

    // 1. Prioritize checking multiple common keys for the username.
    final String resolvedUsername = json['username'] as String? ??
        json['name'] as String? ??
        json['display_name'] as String? ??
        'Unknown Creator';

    // 2. Safely get the nested 'profile' map
    final Map<String, dynamic>? nestedProfileJson =
        json['profile'] as Map<String, dynamic>?;

    // 3. Extract 'profile_image' ONLY IF the nested 'profile' map exists.
    final String? resolvedProfileImage = nestedProfileJson?['profile_image'] as String?;
    
    return ContentCreator(
      userId: resolvedUserId, // Using the resolved String ID
      username: resolvedUsername,
      profileImageUrl: resolvedProfileImage,
    );
  }
}

// ----------------------------------------------------------------------
// ContentPost (The main post model)
// ----------------------------------------------------------------------

class ContentPost {
  // ID is correctly a String for consistency across the client.
  final String id; 
  final ContentCreator creator;
  final String contentType;
  final String? textContent;
  final String? mediaFileUrl;
  final String description;
  final List<String> feedTypes; // Assumes simple string list from API

  final int hypeCount;
  final bool isHyped;
  final int commentCount;

  final String postedBy;
  final DateTime createdAt;

  ContentPost({
    required this.id, // Must be String
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

    // 🔥 FIX: Safely read ID from 'id' or 'content_id', converting int to String.
    final dynamic rawId = json['id'] ?? json['content_id'];
    String resolvedId;
    if (rawId is int) {
        resolvedId = rawId.toString();
    } else {
        resolvedId = rawId as String? ?? '0';
    }

    final String contentTypeString = json['content_type'] as String? ?? 'TEXT';
    final String postedByString = json['posted_by'] as String? ?? '';

    // Handle the ContentCreator parsing safely
    ContentCreator creatorProfile;
    try {
      // Pass the 'creator' JSON block to ContentCreator.fromJson
      creatorProfile =
          ContentCreator.fromJson(json['creator'] as Map<String, dynamic>? ?? {});
    } catch (e) {
      print("Error parsing ContentCreator for post ID $resolvedId: $e"); 
      creatorProfile = ContentCreator(userId: '0', username: 'Deleted User');
    }

    return ContentPost(
      id: resolvedId, // Using the resolved String ID
      creator: creatorProfile,
      contentType: contentTypeString,

      // Nullable fields (API fields: text_content, media_file)
      textContent: json['text_content'] as String?,
      mediaFileUrl: json['media_file'] as String?, // Assuming API uses 'media_file'

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

  // The copyWith method is correct
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
      id: id ?? this.id, 
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
// ❌ TagInfo REMOVED: Define TagInfo in ONLY ONE model file 
// (e.g., tag_model.dart) to fix the 'ambiguous_import' error.
// ----------------------------------------------------------------------