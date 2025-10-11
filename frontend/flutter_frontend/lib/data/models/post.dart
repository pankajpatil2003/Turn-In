import 'package:freezed_annotation/freezed_annotation.dart';
import 'user.dart'; // References the existing User model

part 'post.freezed.dart'; // REQUIRED for Freezed boilerplate
part 'post.g.dart';     // REQUIRED for JsonSerializable (which Freezed includes)

@freezed
// Use abstract class with _$Post mixin for Freezed structure
abstract class Post with _$Post { 
  // Freezed factory constructor defines the data model structure
  const factory Post({
    // 1. IDENTIFIERS AND RELATIONSHIPS
    
    // Maps to content_id (UUID)
    @JsonKey(name: 'content_id')
    required String id, 
    
    // Maps to the 'creator' foreign key
    required User creator, // Assuming User is Freezed/JsonSerializable
    
    // 2. CONTENT TYPE AND DATA
    
    // content_type
    @JsonKey(name: 'content_type')
    required String contentType,
    
    // text_content
    @JsonKey(name: 'text_content')
    String? content, // Nullable fields
    
    // media_file (Django sends the URL to the file)
    @JsonKey(name: 'media_file')
    String? mediaUrl,
    
    // 3. METADATA AND CREATOR
    
    // posted_by (e.g., 'USER', 'STAFF', 'ADMIN')
    @Default('USER') // Use @Default for default values
    @JsonKey(name: 'posted_by')
    String postedBy,
    
    required String description,
    
    // tags (ArrayField in Django, List<String> in Dart)
    @Default([]) // Use @Default for list initialization
    List<String> tags,
    
    // 4. STATUS AND TIME
    
    @JsonKey(name: 'created_at')
    required DateTime createdAt,

    @Default(false)
    bool updated,
    
    @JsonKey(name: 'updated_at')
    required DateTime updatedAt, 

    // 5. INTERACTIONS (Crucial for FeedNotifier logic)

    @Default(0)
    @JsonKey(name: 'hype_count')
    int hypeCount, 

    // Whether the *current* user has hyped this post
    @Default(false)
    @JsonKey(name: 'is_hyped')
    bool isHyped, 
    
    @Default(0)
    @JsonKey(name: 'comment_count')
    int commentCount,

  }) = _Post;

  /// Factory constructor to deserialize the JSON data (required by Freezed).
  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
}
