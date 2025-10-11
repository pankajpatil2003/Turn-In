import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

/// Represents a combined User and StudentProfile object from the Django backend.
@JsonSerializable()
class User {
  // --- Core User Fields ---
  // Maps to user_is (UUID) from Django's Custom User Model
  @JsonKey(name: 'user_is', required: true)
  final String id; 
  
  // Note: Django uses 'username' and 'email' for login.
  final String username;
  final String email;

  // --- Profile Fields (From StudentProfile Model) ---
  // Django sends the URL to the profile image
  @JsonKey(name: 'profile_image', nullable: true)
  final String? profileImageUrl; 

  @JsonKey(name: 'first_name', nullable: true)
  final String? firstName;

  @JsonKey(name: 'last_name', nullable: true)
  final String? lastName;

  @JsonKey(name: 'college_university', nullable: true)
  final String? college;

  @JsonKey(name: 'department', nullable: true)
  final String? department;

  @JsonKey(name: 'course', nullable: true)
  final String? course;

  @JsonKey(name: 'current_year', nullable: true)
  final int? currentYear;

  // feed_types is an ArrayField in Django, mapped to a Dart List<String>
  @JsonKey(name: 'feed_types', defaultValue: [])
  final List<String> feedTypes;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.profileImageUrl,
    this.firstName,
    this.lastName,
    this.college,
    this.department,
    this.course,
    this.currentYear,
    required this.feedTypes,
  });

  /// Factory constructor to create a User object from a JSON map.
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  /// Method to convert a User object into a JSON map.
  Map<String, dynamic> toJson() => _$UserToJson(this);

  // Helper getter for full name
  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return username;
  }
}
