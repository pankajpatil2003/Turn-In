// lib/models/user_model.dart (Updated with feedTypes in toPatchJson)

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
    return AuthTokens(
      accessToken: json['access'] as String,
      refreshToken: json['refresh'] as String,
    );
  }
}

// ----------------------------------------------------------------------

/// NEW MODEL: Used to handle the full user profile data received from the /api/profile/ endpoint.
class UserProfile {
  // Non-editable fields
  final String username;
  final String email;
  final bool isActive;
  final List<String> feedTypes; // Should be treated as editable/updatable

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
    required this.feedTypes,
    this.firstName,
    this.lastName,
    this.profileImage,
    this.collegeUniversity,
    this.department,
    this.course,
    this.currentYear,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      username: json['username'] as String,
      email: json['email'] as String,
      isActive: json['is_active'] as bool? ?? false,
      feedTypes: (json['feed_types'] as List<dynamic>?)?.cast<String>() ?? [],
      
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      profileImage: json['profile_image'] as String?,
      collegeUniversity: json['college_university'] as String?,
      department: json['department'] as String?,
      course: json['course'] as String?,
      currentYear: json['current_year'] as int?,
    );
  }

  /// Creates a map of ONLY the editable fields, suitable for a PATCH request.
  Map<String, dynamic> toPatchJson() {
    // Note: We include profileImage here just to ensure it is not unintentionally
    // cleared if the user profile includes it, but the profile screen handles
    // image upload separately via multipart/form-data.
    return {
      // --- IMPORTANT ADDITION: Include feedTypes for updating the feed preferences ---
      'feed_types': feedTypes, 
      // --- END IMPORTANT ADDITION ---

      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (collegeUniversity != null) 'college_university': collegeUniversity,
      if (department != null) 'department': department,
      if (course != null) 'course': course,
      if (currentYear != null) 'current_year': currentYear,
      
      // If the API accepts this field for non-image updates, it ensures the URL is not accidentally removed.
      if (profileImage != null) 'profile_image': profileImage, 
    };
  }
}