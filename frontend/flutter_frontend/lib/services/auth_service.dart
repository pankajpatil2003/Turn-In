import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb; 
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart'; 
import 'package:http_parser/http_parser.dart'; // REQUIRED for setting Content-Type in MultipartFile

import '../models/user_model.dart';
import '../config/api_config.dart'; 
import 'token_storage_service.dart';
import '../models/content_model.dart'; // ContentPost, TagInfo, ContentCreator

class AuthService {

	final TokenStorageService _tokenService = TokenStorageService();

	// 🔥 NEW METHOD: TOGGLE HYPE STATUS
	/// Toggles the hype status for a given content post.
	/// POST /api/content/{content_id}/hype/
	/// Returns a map containing the updated 'hyped' status and 'hype_count'.
	Future<Map<String, dynamic>> toggleHype(String contentId) async {
		final token = await _tokenService.getAccessToken();
		if (token == null) {
			throw Exception("Authentication token not found.");
		}

		final url = Uri.parse('${ApiConfig.BASE_URL}/content/$contentId/hype/');
		print('Toggling hype for content ID: $contentId at: $url');
		
		try {
			final response = await http.post(
				url,
				headers: {
					'Content-Type': 'application/json',
					'Authorization': 'Bearer $token',
				},
				body: '{}', 
			);

			final responseBody = json.decode(response.body);

			if (response.statusCode == 201 || response.statusCode == 200) {
				if (responseBody.containsKey('hyped') && responseBody.containsKey('hype_count')) {
					return {
						'hyped': responseBody['hyped'] as bool? ?? false,
						'hype_count': responseBody['hype_count'] as int? ?? 0,
					};
				} else {
					throw Exception("API response missing 'hyped' or 'hype_count' fields.");
				}
			} else if (response.statusCode == 401) {
				throw Exception('Session expired or unauthorized.');
			} else {
				print('Toggle Hype failed! Status: ${response.statusCode}');
				print('Response Body: ${response.body}');
				throw Exception("Failed to toggle hype: ${_parseApiError(response)}");
			}
		} catch (e) {
			print('Toggle Hype Error: $e');
			rethrow;
		}
	}
	// 🔥 END NEW METHOD

	// 0. Check Username Availability API (GET)
	/// Checks if a username is already taken.
	/// Returns true if the username is AVAILABLE, or false if it is taken.
	Future<bool> checkUsernameAvailability(String username) async {
		final url = Uri.parse('${ApiConfig.USERNAME_CHECK_URL}?username=$username');
		print('Checking username availability at: $url');
		
		try {
			final response = await http.get(url);
			
			if (response.statusCode == 200) {
				final Map<String, dynamic> responseBody = json.decode(response.body);
				
				if (responseBody.containsKey('available')) {
					return responseBody['available'] as bool;
				} else {
					throw Exception('API response missing "available" status.');
				}
			} else {
				throw Exception('Server error (${response.statusCode}) during username check: ${_parseApiError(response)}');
			}
		} catch (e) {
			throw Exception('Network or general error during username check: $e');
		}
	}


	// 0.5 NEW: Fetch Available feed_types API (GET)
	/// Fetches feed_types from the server, filtered by search term and sorted by method.
	/// Uses the /api/content/feed_types/ endpoint.
	Future<List<TagInfo>> fetchAvailablefeed_types({String? search, String sort = 'rank'}) async {
		final token = await _tokenService.getAccessToken();
		if (token == null) throw Exception('Authentication token not found.');

		String url = '${ApiConfig.FEED_TYPES_URL}?sort=$sort';
		
		if (search != null && search.isNotEmpty) {
			url += '&search=$search';
		}

		final parsedUrl = Uri.parse(url);
		print('Fetching available feed_types at: $parsedUrl');

		try {
			final response = await http.get(
				parsedUrl,
				headers: {
					'Content-Type': 'application/json',
					'Authorization': 'Bearer $token',
				},
			);

			if (response.statusCode == 200) {
				final List<dynamic> jsonList = json.decode(response.body);
				return jsonList.map((json) => TagInfo.fromJson(json)).toList();
			} else if (response.statusCode == 401) {
				throw Exception('Session expired or unauthorized.');
			} else {
				throw Exception('Failed to load feed_types: ${_parseApiError(response)}');
			}
		} catch (e) {
			throw Exception('Network or general error while fetching feed_types: $e');
		}
	}


	// NEW: Fetch Social Media Posts
	/// Fetches content posts filtered by the provided feed types (passed to the API as 'feed_types').
	Future<List<ContentPost>> fetchContentByFeedTypes(List<String> feedTypes) async {
		// 1. Format the feedTypes for the API query, using 'feed_types' as the query parameter name
		final feedTypesString = feedTypes.map((type) => type.trim().toUpperCase()).join(',');
		
		// 2. Build the full URL
		final url = Uri.parse('${ApiConfig.CONTENT_FILTER_URL}?feed_types=$feedTypesString');
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
				
				// 3. Map the JSON list and correct the media file URL field name
				return jsonList.map((json) {
					
					// Server sends 'media_file', client model expects 'media_file_url'
					String? mediaUrl = json['media_file']; 
					
					// Create a mutable map to substitute the corrected URL 
					final Map<String, dynamic> mutableJson = Map<String, dynamic>.from(json);
					
					// Map server field to client field name
					mutableJson['media_file_url'] = mediaUrl;
					
					return ContentPost.fromJson(mutableJson);
				}).toList();
			} else if (response.statusCode == 401) {
				// Handle token expiry or invalid token
				throw Exception("Session expired. Please log in again.");
			} else {
				// Handle other server errors
				throw Exception("Failed to load content: ${_parseApiError(response)}");
			}
		} catch (e) {
			throw Exception('Network or server error while fetching content: $e');
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

	// 4. Get User Profile API (FETCH)
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
				
				// 🔥 FIX: Only prepend BASE_MEDIA_URL if the image path is relative AND not already a full URL
				final String? imagePath = data['profile_image'];

				if (imagePath != null && imagePath.startsWith('/') && !imagePath.startsWith('http')) {
					data['profile_image'] = ApiConfig.BASE_MEDIA_URL + imagePath;
				}
				
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
		// Get JSON fields (which excludes profile_image if null)
		final updateData = updatedProfile.toPatchJson();

		http.Response response;

		// --- Logic for File Upload (Multipart/Form-Data) ---
		if (imageXFile != null) {
			print('Executing Multipart PATCH (Image and Text)');
			final request = http.MultipartRequest('PATCH', url);
			
			request.headers['Authorization'] = 'Bearer $accessToken';

            // --- CRITICAL FIX: Determine and set Content-Type ---
            final String? fileName = imageXFile.name;
            // Default to 'jpeg' if no extension or unknown extension
            String fileExtension = 'jpeg'; 
            if (fileName != null && fileName.contains('.')) {
                fileExtension = fileName.split('.').last.toLowerCase();
            }
            
            // Simple mapping for common image types
            final String mimeSubtype = ['png', 'gif', 'bmp', 'webp'].contains(fileExtension) ? fileExtension : 'jpeg';
            final MediaType contentType = MediaType('image', mimeSubtype);
            // --- END CRITICAL FIX ---


			// --- PLATFORM-AGNOSTIC FILE HANDLING ---
			if (kIsWeb) {
				// WEB: Read bytes directly from XFile
				final bytes = await imageXFile.readAsBytes();
				request.files.add(
					http.MultipartFile.fromBytes(
						'profile_image', 
						bytes,
						filename: imageXFile.name,
                        contentType: contentType, // <<< ADDED CONTENT TYPE
					),
				);
			} else {
				// MOBILE/DESKTOP: Use the file path
				request.files.add(
					await http.MultipartFile.fromPath(
						'profile_image', 
						imageXFile.path, 
                        contentType: contentType, // <<< ADDED CONTENT TYPE
					),
				);
			}
			// --- END PLATFORM-AGNOSTIC FILE HANDLING ---


			// Add text fields (non-null from model) to the multipart request
			updateData.forEach((key, value) {
				// Arrays (like 'feed_types') must be JSON-encoded for multipart forms.
				if (key == 'feed_types' && value is List) {
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
			
			// 🔥 FIX: Correct the returned image URL using the new, safer logic
			final String? imagePath = data['profile_image'];

			if (imagePath != null && imagePath.startsWith('/') && !imagePath.startsWith('http')) {
				data['profile_image'] = ApiConfig.BASE_MEDIA_URL + imagePath;
			}
			
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
