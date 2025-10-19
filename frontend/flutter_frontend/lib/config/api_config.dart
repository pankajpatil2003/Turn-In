// lib/config/api_config.dart

/// Configuration class for all API endpoints and constants.
class ApiConfig {
  // Base URL for the entire API.
  // Using localhost for development as per your request.
  // IMPORTANT: For real mobile devices, 'http://10.0.2.2:8000' 
  // (Android Emulator) or your machine's local IP is often needed.
  static const String BASE_URL = "http://localhost:8000/api";
  static const String BASE_MEDIA_URL = "";

  // Full URLs for the specific registration endpoints
  static const String OTP_REQUEST_URL = '$BASE_URL/register/request-otp/';
  static const String FINAL_REGISTER_URL = '$BASE_URL/register/final/';

  // Login Endpoint
  static const String LOGIN_URL = '$BASE_URL/login/';
  static const String USER_PROFILE_URL = '$BASE_URL/profile/';

  // NEW: Endpoint for fetching content by tags
    static const String CONTENT_FILTER_URL = '$BASE_URL/content/filter-by-tags/';

  static const String USERNAME_CHECK_URL = '$BASE_URL/check-username/';
}