// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) {
  $checkKeys(json, requiredKeys: const ['user_is']);
  return User(
    id: json['user_is'] as String,
    username: json['username'] as String,
    email: json['email'] as String,
    profileImageUrl: json['profile_image'] as String?,
    firstName: json['first_name'] as String?,
    lastName: json['last_name'] as String?,
    college: json['college_university'] as String?,
    department: json['department'] as String?,
    course: json['course'] as String?,
    currentYear: (json['current_year'] as num?)?.toInt(),
    feedTypes:
        (json['feed_types'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [],
  );
}

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'user_is': instance.id,
  'username': instance.username,
  'email': instance.email,
  'profile_image': instance.profileImageUrl,
  'first_name': instance.firstName,
  'last_name': instance.lastName,
  'college_university': instance.college,
  'department': instance.department,
  'course': instance.course,
  'current_year': instance.currentYear,
  'feed_types': instance.feedTypes,
};
