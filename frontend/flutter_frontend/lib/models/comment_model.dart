// lib/models/comment_model.dart

// 1. CRITICAL FIX: Ensure you have added the 'timeago' package to your pubspec.yaml
// To fix this error, run: flutter pub add timeago
import 'package:timeago/timeago.dart' as timeago;

// Assuming '../models/content_model.dart' or a similar file is available if needed.
// This file looks self-contained for the user models.

// ----------------------------------------------------------------------
// NEW MODEL: CommentUser (Handles the nested 'user' object from the Comment API)
// ----------------------------------------------------------------------

/// Helper model to hold the user data nested inside the comment response.
class CommentUser {
  final String username;
  // Use profileImageUrl for consistency with ContentCreator
  final String? profileImageUrl; 
  final String? firstName;
  final String? lastName;

  CommentUser({
    required this.username,
    this.profileImageUrl,
    this.firstName,
    this.lastName,
  });

  factory CommentUser.fromJson(Map<String, dynamic> json) {
    // Safely retrieve the nested 'profile' map
    final Map<String, dynamic>? profile = json['profile'] as Map<String, dynamic>?;

    final String resolvedUsername = json['username'] as String? ?? 'Deleted User';
    
    // Extract profile image, first name, and last name from the nested 'profile' object.
    String? imageUrl;
    String? resolvedFirstName;
    String? resolvedLastName;

    if (profile != null) {
      // ✅ Confirmed: This uses the correct 'profile_image' key
      imageUrl = profile['profile_image'] as String?; 
      resolvedFirstName = profile['first_name'] as String?;
      resolvedLastName = profile['last_name'] as String?;
    }

    return CommentUser(
      username: resolvedUsername,
      // Note: This matches the 'profileImageUrl' field name used in comment_screen.dart
      profileImageUrl: imageUrl, 
      firstName: resolvedFirstName,
      lastName: resolvedLastName,
    );
  }
}

// ----------------------------------------------------------------------
// UPDATED MODEL: CommentModel
// ----------------------------------------------------------------------

/// Represents a single comment on a content post, including nested replies.
class CommentModel {
  final int id;
  final CommentUser user; 
  final String text;
  final int? parentCommentId; // Null for top-level comments
  final DateTime createdAt;
  final List<CommentModel> replies; // Nested list of replies
  final int replyCount;

  CommentModel({
    required this.id,
    required this.user,
    required this.text,
    this.parentCommentId,
    required this.createdAt,
    this.replies = const [], 
    this.replyCount = 0, 
  });

  /// Factory method to create a CommentModel from a JSON map.
  factory CommentModel.fromJson(Map<String, dynamic> json) {
    // 1. Safely parse the nested user object
    final Map<String, dynamic>? userJson = json['user'] as Map<String, dynamic>?;

    // Handle case where user might be null or missing
    final CommentUser commentUser = (userJson != null)
        ? CommentUser.fromJson(userJson)
        : CommentUser(username: 'Unknown Creator', profileImageUrl: null);

    // 2. Parse nested replies recursively.
    final repliesJson = json['replies'] as List<dynamic>? ?? [];
    List<CommentModel> replies = repliesJson
        // Ensure map entries are cast correctly before passing to fromJson
        .map((r) => CommentModel.fromJson(r as Map<String, dynamic>)) 
        .toList();
    
    // 3. Robust ID and Date Parsing
    
    // 🔥 FIX: Ensure ID is parsed as an int, safely handling API responses
    // that might return it as a String (though the model expects int)
    final resolvedId = json['id'];
    final int commentId = (resolvedId is int) 
        ? resolvedId 
        : int.tryParse(resolvedId?.toString() ?? '0') ?? 0;
        
    final String? createdAtString = json['created_at'] as String?;

    return CommentModel(
      // Use the robustly parsed ID
      id: commentId, 
      user: commentUser, 
      text: json['text'] as String? ?? 'Error: Comment text missing.',
      // Safely parse parent_comment, which may be null
      parentCommentId: json['parent_comment'] as int?, 
      
      // Use epoch start time if date string is missing or null
      createdAt: createdAtString != null
          ? DateTime.parse(createdAtString).toLocal() 
          : DateTime.fromMillisecondsSinceEpoch(0),
          
      replies: replies,
      // Use the API count or fallback to the list length
      replyCount: json['reply_count'] as int? ?? replies.length, 
    );
  }

  // --- Helper Getters ---
  /// Helper getter to display the time difference since the comment was posted.
  String get formattedTimeAgo {
    return timeago.format(createdAt);
  }

  // Optional: A getter to display the full name if available, otherwise the username.
  String get displayName {
    if (user.firstName != null && user.lastName != null && user.firstName!.isNotEmpty && user.lastName!.isNotEmpty) {
      return '${user.firstName} ${user.lastName}';
    }
    return user.username;
  }

  @override
  String toString() {
    return 'CommentModel(id: $id, user: ${user.username}, replies: ${replies.length}, parent: $parentCommentId)';
  }
}