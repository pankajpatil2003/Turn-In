// lib/services/auth_service.dart (Updated to handle 400 errors better)

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../config/api_config.dart'; 

class AuthService {
  
  // Helper function to decode and parse common Django error responses
  String _parseApiError(http.Response response) {
    try {
      final errorData = json.decode(response.body);
      
      // Attempt to extract the most useful error message
      if (errorData is Map) {
        // Look for common Django Rest Framework keys
        final String? detail = errorData['detail'];
        final List<dynamic>? nonFieldErrors = errorData['non_field_errors'];
        
        if (detail != null) return detail;
        if (nonFieldErrors != null && nonFieldErrors.isNotEmpty) {
          return nonFieldErrors.join('\n');
        }
        
        // Check for specific field errors (e.g., 'email': ['This field is required.'])
        for (var key in errorData.keys) {
          final errorValue = errorData[key];
          if (errorValue is List && errorValue.isNotEmpty) {
            return '${key.toUpperCase()}: ${errorValue.join('\n')}';
          }
        }
      }
      
      // Fallback if the error format is unexpected
      return 'Server rejected request. Status: ${response.statusCode}';
    } catch (e) {
      return 'Failed to parse server error. Status: ${response.statusCode}';
    }
  }

  // 1. Request OTP API
  Future<void> requestOtp(String email) async {
    final url = Uri.parse(ApiConfig.OTP_REQUEST_URL);
    
    // Log the payload being sent for debugging the 400 error
    final requestBody = json.encode({'email': email});
    print('Sending OTP Request to: $url with body: $requestBody');
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return; // Success
      } else {
        // Log the full response body for debugging the 400 error
        print('OTP Request failed! Status: ${response.statusCode}');
        print('Response Body: ${response.body}'); 
        
        // Throw an exception with the parsed backend error message
        throw Exception(_parseApiError(response));
      }
    } catch (e) {
      // Re-throw exceptions for network issues
      throw Exception('Network or general error: $e');
    }
  }

  // 2. Final Registration API
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
        return; // Success
      } else {
        print('Registration failed! Status: ${response.statusCode}');
        print('Response Body: ${response.body}');
        
        // Throw an exception with the parsed backend error message
        throw Exception(_parseApiError(response));
      }
    } catch (e) {
      throw Exception('Network or general error: $e');
    }
  }
}