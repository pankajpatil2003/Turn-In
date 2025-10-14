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