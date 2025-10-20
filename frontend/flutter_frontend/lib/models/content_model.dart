// lib/models/content_model.dart

class CreatorProfile { 
  final String userId;
  final String username;
  final String? profileImageUrl;

  CreatorProfile({
    required this.userId,
    required this.username,
    this.profileImageUrl,
  });

  factory CreatorProfile.fromJson(Map<String, dynamic> json) {
    // The server JSON uses 'user_is' and 'profile' (not 'profile_image_url')
    // We are ensuring non-nullable fields have a fallback.
    return CreatorProfile(
      // ✅ FIX 1: The API JSON uses 'user_is' for the ID.
      userId: json['user_is'] as String? ?? '', 
      username: json['username'] as String? ?? 'Unknown Creator',
      
      // The API JSON uses 'profile' for the profile image URL.
      profileImageUrl: json['profile'] as String?, 
    );
  }
}

// ----------------------------------------------------------------------

class ContentPost {
  final String contentId;
  final CreatorProfile creator;
  final String contentType;
  final String? textContent;
  final String? mediaFileUrl; // This is the Dart property name
  final String description;
  final List<String> feedTypes; 
  
  final int hypeCount;
  final bool isHyped; 
  final int commentCount;
  
  final String postedBy;
  final DateTime createdAt;
  
  // NOTE: I added 'updated_at' to the model to match your JSON data structure, 
  // though it is not used in the constructor arguments.

  ContentPost({
    required this.contentId,
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
    
    // Safely extract date string to prevent calling DateTime.parse(null)
    final String? createdAtString = json['created_at'] as String?;
    
    // Safely extract post ID, defaulting to a UUID-like placeholder if missing
    final String contentIdString = json['content_id'] as String? ?? 'missing_id_${DateTime.now().microsecondsSinceEpoch}';
    
    // Safely extract required fields, providing fallbacks
    final String contentTypeString = json['content_type'] as String? ?? 'TEXT';
    final String postedByString = json['posted_by'] as String? ?? ''; 
    
    // Handle the CreatorProfile parsing safely
    CreatorProfile creatorProfile;
    try {
        creatorProfile = CreatorProfile.fromJson(json['creator'] as Map<String, dynamic>? ?? {});
    } catch (e) {
        // Fallback to a default profile if the creator object is missing or malformed
        creatorProfile = CreatorProfile(userId: '0', username: 'Deleted User');
    }
    
    return ContentPost(
      contentId: contentIdString,
      creator: creatorProfile,
      contentType: contentTypeString,
      
      // Nullable fields
      textContent: json['text_content'] as String?,
      
      // ✅ FIX 2: Read the 'media_file' field directly from the API response JSON.
      // This is the source of truth for the image URL.
      mediaFileUrl: json['media_file'] as String?,
      
      // Non-nullable fields with defaults
      description: json['description'] as String? ?? '', 
      feedTypes: List<String>.from(json['feed_types'] as List? ?? []),
      
      hypeCount: json['hype_count'] as int? ?? 0, 
      isHyped: json['is_hyped'] as bool? ?? false,
      commentCount: json['comment_count'] as int? ?? 0, 
      
      postedBy: postedByString,
      
      // CRITICAL FIX: Prevent crash on null date
      createdAt: createdAtString != null
          ? DateTime.parse(createdAtString)
          : DateTime.fromMillisecondsSinceEpoch(0), // Safe fallback date (epoch)
    );
  }
  
  ContentPost copyWith({
    String? contentId, 
    CreatorProfile? creator, 
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
      contentId: contentId ?? this.contentId,
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
    // Check for null/missing date fields here too, as they are required
    final String? createdAtString = json['created_at'] as String?;
    final String? lastUsedAtString = json['last_used_at'] as String?;

    return TagInfo(
      tag: json['tag'] as String? ?? '',
      totalUsed: json['total_used'] as int? ?? 0,
      // The API uses 'rank' with a capital 'R' here, but based on your previous models 
      // I'll assume it should be lowercased to 'rank' or use the safest cast.
      // Assuming 'rank' is the intended field from your previous models.
      rank: (json['rank'] as num?)?.toDouble() ?? 0.0, 
      
      // Critical null checks for required DateTimes
      createdAt: createdAtString != null ? DateTime.parse(createdAtString) : DateTime.fromMillisecondsSinceEpoch(0),
      lastUsedAt: lastUsedAtString != null ? DateTime.parse(lastUsedAtString) : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
