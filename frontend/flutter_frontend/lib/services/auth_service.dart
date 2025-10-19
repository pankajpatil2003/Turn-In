// lib/services/auth_service.dart (Final Cross-Platform Version)

import 'dart:convert';
// Used for dart:io check on non-web platforms
import 'package:flutter/foundation.dart' show kIsWeb; // Used to check if running on web
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart'; // Used for platform-agnostic XFile
import '../models/user_model.dart';
import '../config/api_config.dart'; 
import 'token_storage_service.dart';
import '../models/content_model.dart';


class AuthService {

    final TokenStorageService _tokenService = TokenStorageService();

    // 0. Check Username Availability API (GET)
    /// Checks if a username is already taken.
    /// Returns true if the username is AVAILABLE, or false if it is taken.
    Future<bool> checkUsernameAvailability(String username) async {
        final url = Uri.parse('${ApiConfig.USERNAME_CHECK_URL}?username=$username');
        print('Checking username availability at: $url');
        
        try {
            final response = await http.get(url);
            
            // Assume the server always returns 200 OK with a JSON body
            // containing the 'available' status, as is common for checks.
            if (response.statusCode == 200) {
                final Map<String, dynamic> responseBody = json.decode(response.body);
                
                // CRITICAL: Read the 'available' field from the JSON body
                if (responseBody.containsKey('available')) {
                    // Returns true if available: true, or false if available: false
                    return responseBody['available'] as bool;
                } else {
                    // Handle case where 'available' field is missing unexpectedly
                    throw Exception('API response missing "available" status.');
                }
            } else {
                // Handle non-200 status codes (e.g., 500 server error)
                throw Exception('Server error (${response.statusCode}) during username check: ${_parseApiError(response)}');
            }
        } catch (e) {
            // Handle network or JSON decoding error
            throw Exception('Network or general error during username check: $e');
        }
    }


    // NEW: Fetch Social Media Posts (Updated to use 'feedTypes' from UserProfile)
    /// Fetches content posts filtered by the provided feed types (passed to the API as 'tags').
    Future<List<ContentPost>> fetchContentByFeedTypes(List<String> feedTypes) async {
      // 1. Format the feedTypes for the API query, using 'tags' as the query parameter name
      final tagsString = feedTypes.map((type) => type.trim().toUpperCase()).join(',');
      
      // 2. Build the full URL
      final url = Uri.parse('${ApiConfig.CONTENT_FILTER_URL}?tags=$tagsString');
      print('Fetching content at: $url');
      
      final token = await _tokenService.getAccessToken();

      if (token == null) {
        throw Exception("Authentication required. Access token not found.");
      }
      
      try {
        final response = await http.get(
          url,
          headers: {
            'Authorization': 'Bearer $token', // Assuming protected endpoint
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final List<dynamic> jsonList = json.decode(response.body);
          // 3. Map the JSON list to a list of ContentPost objects
          return jsonList.map((json) => ContentPost.fromJson(json)).toList();
        } else if (response.statusCode == 401) {
          // Handle token expiry or invalid token
          throw Exception("Session expired. Please log in again.");
        } else {
          // Handle other server errors
          throw Exception("Failed to load content: ${_parseApiError(response)}");
        }
      } catch (e) {
        throw Exception('Network or server error: $e');
      }
    }


    // Helper function to decode and parse common Django error responses (UNCHANGED)
    String _parseApiError(http.Response response) {
        try {
            final errorData = json.decode(response.body);
            if (errorData is Map) {
                final String? detail = errorData['detail'];
                final List<dynamic>? nonFieldErrors = errorData['non_field_errors'];
                
                if (detail != null) return detail;
                if (nonFieldErrors != null && nonFieldErrors.isNotEmpty) {
                    return nonFieldErrors.join('\n');
                }
                
                for (var key in errorData.keys) {
                    final errorValue = errorData[key];
                    if (errorValue is List && errorValue.isNotEmpty) {
                        return '${key.toUpperCase()}: ${errorValue.join('\n')}';
                    }
                }
            }
            return 'Server rejected request. Status: ${response.statusCode}';
        } catch (e) {
            return 'Failed to parse server error. Status: ${response.statusCode}';
        }
    }

    // 1. Request OTP API (UNCHANGED)
    Future<void> requestOtp(String email) async {
        final url = Uri.parse(ApiConfig.OTP_REQUEST_URL);
        final requestBody = json.encode({'email': email});
        print('Sending OTP Request to: $url with body: $requestBody');
        
        try {
            final response = await http.post(
                url,
                headers: {'Content-Type': 'application/json'},
                body: requestBody,
            );

            if (response.statusCode == 200 || response.statusCode == 201) {
                return;
            } else {
                print('OTP Request failed! Status: ${response.statusCode}');
                print('Response Body: ${response.body}'); 
                throw Exception(_parseApiError(response));
            }
        } catch (e) {
            throw Exception('Network or general error: $e');
        }
    }

    // 2. Final Registration API (UNCHANGED)
    Future<void> completeRegistration(RegistrationData data) async {
        final url = Uri.parse(ApiConfig.FINAL_REGISTER_URL);
        final requestBody = json.encode(data.toJson());
        print('Sending Registration Request to: $url with body: $requestBody');

        try {
            final response = await http.post(
                url,
                headers: {'Content-Type': 'application/json'},
                body: requestBody,
            );

            if (response.statusCode == 200 || response.statusCode == 201) {
                return;
            } else {
                print('Registration failed! Status: ${response.statusCode}');
                print('Response Body: ${response.body}');
                throw Exception(_parseApiError(response));
            }
        } catch (e) {
            throw Exception('Network or general error: $e');
        }
    }
    
    // 3. Login API (UNCHANGED)
    Future<AuthTokens> login(String email, String password) async {
        final url = Uri.parse(ApiConfig.LOGIN_URL);
        final requestBody = json.encode({
            'email': email,
            'password': password,
        });
        print('Sending Login Request to: $url with body: $requestBody');

        try {
            final response = await http.post(
                url,
                headers: {'Content-Type': 'application/json'},
                body: requestBody,
            );

            if (response.statusCode == 200) {
                final data = json.decode(response.body);
                print('Login Success! Response: $data');
                return AuthTokens.fromJson(data);
            } else {
                print('Login failed! Status: ${response.statusCode}');
                print('Response Body: ${response.body}');
                throw Exception(_parseApiError(response));
            }
        } catch (e) {
            throw Exception('Network or general error during login: $e');
        }
    }

    // 4. Get User Profile API (UNCHANGED)
    Future<UserProfile> getUserData() async {
        final accessToken = await _tokenService.getAccessToken();

        if (accessToken == null) {
            throw Exception('Not authenticated. No access token found.');
        }

        final url = Uri.parse(ApiConfig.USER_PROFILE_URL);
        
        try {
            final response = await http.get(
                url,
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': 'Bearer $accessToken', 
                },
            );

            if (response.statusCode == 200) {
                final data = json.decode(response.body);
                return UserProfile.fromJson(data);
            } else if (response.statusCode == 401) {
                throw Exception('Session expired or token invalid. Please log in again.');
            } else {
                print('User data failed! Status: ${response.statusCode}');
                print('Response Body: ${response.body}');
                throw Exception(_parseApiError(response));
            }
        } catch (e) {
            throw Exception('Network or general error fetching user data: $e');
        }
    }


    // 5. Unified Profile Update API (PATCH)
    /// Sends a PATCH request to update user data. Handles both JSON (text data)
    /// and Multipart (file upload) requests based on whether `imageXFile` is provided.
    /// Returns the updated UserProfile object from the API response.
    Future<UserProfile> patchProfile({
        required UserProfile updatedProfile, 
        XFile? imageXFile, // Use XFile for platform compatibility
    }) async {
        final accessToken = await _tokenService.getAccessToken();

        if (accessToken == null) {
            throw Exception('Not authenticated. No access token found.');
        }

        final url = Uri.parse(ApiConfig.USER_PROFILE_URL);
        final updateData = updatedProfile.toPatchJson();

        http.Response response;

        // --- Logic for File Upload (Multipart/Form-Data) ---
        if (imageXFile != null) {
            print('Executing Multipart PATCH (Image and Text)');
            final request = http.MultipartRequest('PATCH', url);
            
            request.headers['Authorization'] = 'Bearer $accessToken';

            // --- PLATFORM-AGNOSTIC FILE HANDLING ---
            if (kIsWeb) {
                // WEB: Read bytes directly from XFile (bypassing dart:io)
                final bytes = await imageXFile.readAsBytes();
                request.files.add(
                    http.MultipartFile.fromBytes(
                        'profile_image', 
                        bytes,
                        filename: imageXFile.name,
                    ),
                );
            } else {
                // MOBILE/DESKTOP: Use the file path (dart:io supported)
                request.files.add(
                    await http.MultipartFile.fromPath(
                        'profile_image', 
                        imageXFile.path, 
                    ),
                );
            }
            // --- END PLATFORM-AGNOSTIC FILE HANDLING ---


            // Add text fields (non-null and non-empty from the model)
            updateData.forEach((key, value) {
                // Ensure array types like 'feed_types' are converted to JSON strings 
                // for multipart form data, which only handles strings or files.
                if (value is List) {
                    request.fields[key] = json.encode(value);
                } else if (value != null) {
                    request.fields[key] = value.toString();
                }
            });

            try {
                final streamedResponse = await request.send();
                response = await http.Response.fromStream(streamedResponse);
            } catch (e) {
                throw Exception('Network or general error during profile update: $e');
            }

        // --- Logic for Text-Only Update (JSON) ---
        } else {
            print('Executing JSON PATCH (Text Only)');
            try {
                response = await http.patch(
                    url,
                    headers: {
                        'Content-Type': 'application/json', // JSON Header
                        'Authorization': 'Bearer $accessToken',
                    },
                    body: json.encode(updateData),
                );
            } catch (e) {
                throw Exception('Network or general error during profile update: $e');
            }
        }
        
        // --- Process Response ---
        if (response.statusCode == 200) {
            // SUCCESS: Decode the JSON and return the new UserProfile
            final data = json.decode(response.body);
            return UserProfile.fromJson(data); 
        } else if (response.statusCode == 401) {
            throw Exception('Session expired or token invalid.');
        } else {
            print('Profile update failed! Status: ${response.statusCode}');
            print('Response Body: ${response.body}');
            throw Exception(_parseApiError(response));
        }
    }
}
