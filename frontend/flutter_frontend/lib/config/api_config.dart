// lib/config/api_config.dart

import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform; // Note: Requires dart:io, which is not available on web

/// Configuration class for all API endpoints and constants.
class ApiConfig {
  // Determine the correct host based on the environment.
  // - Web: uses 'localhost'
  // - Android Emulator: uses '10.0.2.2' (a special alias for the host loopback interface)
  // - iOS Simulator/Real Device: uses 'localhost' or a machine's local IP (you might need to adjust this)
  
  // 🔥 FIX 1: Use 10.0.2.2 for Android Emulator, which is essential for mobile testing.
  static final String _baseHost = kIsWeb
      ? 'localhost'
      : (Platform.isAndroid ? '10.0.2.2' : 'localhost');

  // Define the base port.
  static const String _port = "8000";
  
  // Full URL for the server root.
  static final String BASE_ROOT_URL = "http://$_baseHost:$_port";

  // Base URL for the entire API.
  static final String BASE_URL = "$BASE_ROOT_URL/api";
  
  // 💡 FIX 2: Set BASE_MEDIA_URL dynamically using the correct host/port.
  static final String BASE_MEDIA_URL = BASE_ROOT_URL;

  // ----------------------------------------------------------------------
  // Full API Endpoints
  // ----------------------------------------------------------------------

  // Full URLs for the specific registration endpoints
  static final String OTP_REQUEST_URL = '$BASE_URL/register/request-otp/';
  static final String FINAL_REGISTER_URL = '$BASE_URL/register/final/';

  // Login Endpoint
  static final String LOGIN_URL = '$BASE_URL/login/';
  static final String USER_PROFILE_URL = '$BASE_URL/profile/';

  // Endpoint for fetching content by feed_types
  static final String CONTENT_FILTER_URL = '$BASE_URL/content/filter-by-feed_types/';

  static final String USERNAME_CHECK_URL = '$BASE_URL/check-username/';

  /// Endpoint for fetching all available feed_types (used for feed selection).
  static final String FEED_TYPES_URL = '$BASE_URL/content/feed_types/';

  // Note: The Content ID must be added to this path in AuthService.
  static final String hypeToggleUrl = '$BASE_URL/content';
}