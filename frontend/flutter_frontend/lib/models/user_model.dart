// lib/models/user_model.dart

// Used for the final registration API call
class RegistrationData {
  final String email;
  final String username;
  final String password;
  final String passwordConfirm;
  final String otpCode;

  RegistrationData({
    required this.email,
    required this.username,
    required this.password,
    required this.passwordConfirm,
    required this.otpCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'username': username,
      'password': password,
      'password_confirm': passwordConfirm,
      'otp_code': otpCode,
    };
  }
}

// ----------------------------------------------------------------------

// Model used to structure the access and refresh tokens received after a successful login.
class AuthTokens {
  final String accessToken;
  final String refreshToken;

  AuthTokens({required this.accessToken, required this.refreshToken});

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    // Ensuring non-nullable strings have a safe fallback
    return AuthTokens(
      accessToken: json['access'] as String? ?? '',
      refreshToken: json['refresh'] as String? ?? '',
    );
  }
}

// ----------------------------------------------------------------------

// NEW MODEL: Used for creating a new content post (text and feed type)
class ContentCreationData {
  final String text;
  final String feedType;

  ContentCreationData({
    required this.text,
    required this.feedType,
  });

  /// Used for sending text fields in a Multipart request.
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'feed_type': feedType,
    };
  }
}

// ----------------------------------------------------------------------

/// NEW MODEL: Used to handle the full user profile data received from the /api/profile/ endpoint.
class UserProfile {
  // Non-editable fields
  final String username;
  final String email;
  final bool isActive;
  
  // FIX 1: Make feedTypes nullable (List<String>?) to handle 'null' from API
  final List<String>? feedTypes; 

  // Editable fields
  String? firstName;
  String? lastName;
  String? profileImage; // Image is editable via separate multipart request, but URL is tracked here
  String? collegeUniversity;
  String? department;
  String? course;
  int? currentYear;

  UserProfile({
    required this.username,
    required this.email,
    required this.isActive,
    // Note: feedTypes is now optional in the constructor
    this.feedTypes, 
    this.firstName,
    this.lastName,
    this.profileImage,
    this.collegeUniversity,
    this.department,
    this.course,
    this.currentYear,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final List<dynamic>? feedTypesJson = json['feed_types'] as List<dynamic>?;
    
    return UserProfile(
      // Non-nullable fields with fallbacks
      username: json['username'] as String? ?? 'Unknown',
      email: json['email'] as String? ?? 'No Email',
      isActive: json['is_active'] as bool? ?? false,
      
      // Handle the list safely: cast to List<String> or return null
      // This is necessary because the field is now nullable
      feedTypes: feedTypesJson?.cast<String>(),
      
      // Nullable fields
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      profileImage: json['profile_image'] as String?, 
      collegeUniversity: json['college_university'] as String?,
      department: json['department'] as String?,
      course: json['course'] as String?,
      currentYear: json['current_year'] as int?,
    );
  }

  /// Creates a map of ONLY the fields we intend to PATCH.
  /// We only include fields that have been explicitly set (i.e., are not null).
  Map<String, dynamic> toPatchJson() {
    final Map<String, dynamic> data = {};

    // FIX 2: Only include feed_types if it is NOT null. 
    if (feedTypes != null) {
      data['feed_types'] = feedTypes; 
    }

    // Include all editable fields only if they are not null.
    if (firstName != null) {
      data['first_name'] = firstName;
    }
    if (lastName != null) {
      data['last_name'] = lastName;
    }
    if (collegeUniversity != null) {
      data['college_university'] = collegeUniversity;
    }
    if (department != null) {
      data['department'] = department;
    }
    if (course != null) {
      data['course'] = course;
    }
    if (currentYear != null) {
      data['current_year'] = currentYear;
    }
    
    return data;
  }
}
