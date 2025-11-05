class TagInfo {
  // Renamed to match the JSON key "tag"
  final String tag; 
  // Added to match the JSON key "total_used"
  final int totalUsed; 
  // Renamed to match the JSON key "Rank" (Capital R)
  final double rank; 
  // Removed 'slug' and 'id' as they are not in the sample data, 
  // but keeping them if the API provides them elsewhere.
  final String? slug; 
  final int? id;

  final String? createdAt;
  final String? lastUsedAt;
  
  TagInfo({
    required this.tag, 
    required this.totalUsed, 
    required this.rank, 
    this.slug, 
    this.id,
    this.createdAt,
    this.lastUsedAt,
  });

  /// Factory constructor to parse JSON data.
  factory TagInfo.fromJson(dynamic json) {
    if (json is String) {
      // Handle the case where the API returns a raw string (e.g., "GENERAL")
      return TagInfo(
        tag: json,
        totalUsed: 0, 
        rank: 0.0,
      );
    }
    
    // Assume it is a Map<String, dynamic> otherwise
    final Map<String, dynamic> map = json as Map<String, dynamic>;

    return TagInfo(
      // CRITICAL FIX: Use backend key "tag"
      tag: map['tag'] as String? ?? map['name'] as String? ?? '', 
      // CRITICAL FIX: Use backend key "total_used"
      totalUsed: map['total_used'] as int? ?? 0, 
      // CRITICAL FIX: Use backend key "Rank" (with capital 'R') and cast to double
      rank: (map['Rank'] as num?)?.toDouble() ?? 0.0, 
      
      // Kept for backward compatibility or other endpoints:
      slug: map['slug'] as String?,
      id: map['id'] as int?,
      
      // Parsing date fields
      createdAt: map['created_at'] as String?,
      lastUsedAt: map['last_used_at'] as String?,
    );
  }

  // Method to convert back to JSON for PATCH/POST
  Map<String, dynamic> toJson() {
    return {
      // Assuming your server expects the full object structure
      'tag': tag,
      'total_used': totalUsed,
      'Rank': rank,
      'slug': slug,
      'id': id,
      'created_at': createdAt,
      'last_used_at': lastUsedAt,
    };
  }
}
// ----------------------------------------------------------------------


/// 1. Data collected for the final registration step.
class RegistrationData {
  final String email;
  final String username;
  final String password;
  final String passwordConfirm;
  final String otp; 

  RegistrationData({
    required this.email,
    required this.username,
    required this.password,
    required this.passwordConfirm,
    required this.otp, 
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'username': username,
      'password': password,
      'password_confirm': passwordConfirm, 
      'otp_code': otp, 
    };
  }
}

// ----------------------------------------------------------------------

/// 2. Model used to structure the access and refresh tokens received after a successful login.
class AuthTokens {
  final String accessToken;
  final String refreshToken;

  AuthTokens({required this.accessToken, required this.refreshToken});

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['access'] as String? ?? '', 
      refreshToken: json['refresh'] as String? ?? '',
    );
  }
}

// ----------------------------------------------------------------------

/// 3. Model used to handle the full user profile data received from the /api/profile/ endpoint.
class UserProfile {
  final String id; 
  final String username;
  final String email;
  final bool isActive;
  
  final List<TagInfo>? feedTypes; 

  String? firstName;
  String? lastName;
  String? profileImage; 
  String? collegeUniversity;
  String? department;
  String? course;
  int? currentYear;
  String? bio; 

  UserProfile({
    required this.id, 
    required this.username,
    required this.email,
    required this.isActive,
    this.feedTypes, 
    this.firstName,
    this.lastName,
    this.profileImage,
    this.collegeUniversity,
    this.department,
    this.course,
    this.currentYear,
    this.bio,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // Safely parse ID from int or string to String
    final idValue = json['id'];
    String idString;
    if (idValue is int) {
      idString = idValue.toString();
    } else {
      idString = idValue as String? ?? 'unknown'; 
    }

    final List<dynamic>? feedTypesJson = json['feed_types'] as List<dynamic>?;
    
    return UserProfile(
      id: idString, 
      username: json['username'] as String? ?? 'Unknown',
      email: json['email'] as String? ?? 'No Email',
      isActive: json['is_active'] as bool? ?? false,
      
      // Map the JSON list to TagInfo objects, passing the dynamic 'e' 
      feedTypes: feedTypesJson
          ?.map((e) => TagInfo.fromJson(e)) 
          .toList(),
      
      // Nullable fields
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      profileImage: json['profile_image'] as String?,
      collegeUniversity: json['college_university'] as String?,
      department: json['department'] as String?,
      course: json['course'] as String?,
      currentYear: json['current_year'] as int?,
      bio: json['bio'] as String?,
    );
  }

  /// Creates a map of ONLY the fields we intend to PATCH for the JSON request.
  Map<String, dynamic> toPatchJson() {
    final Map<String, dynamic> data = {};

    // Map TagInfo objects back to JSON map structure for the server
    if (feedTypes != null) {
      // Assuming your server expects the full tag object for PATCH requests.
      data['feed_types'] = feedTypes!.map((tag) => tag.toJson()).toList(); 
    }
    
    void addIfNotNull(String key, dynamic value) {
      if (value != null) {
        data[key] = value;
      }
    }

    addIfNotNull('first_name', firstName);
    addIfNotNull('last_name', lastName);
    addIfNotNull('college_university', collegeUniversity);
    addIfNotNull('department', department);
    addIfNotNull('course', course);
    addIfNotNull('current_year', currentYear);
    addIfNotNull('bio', bio);
    
    return data;
  }
}