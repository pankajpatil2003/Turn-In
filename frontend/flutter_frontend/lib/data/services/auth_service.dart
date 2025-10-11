import 'package:dio/dio.dart';
import 'package:flutter_frontend/data/models/user.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/constants/api_constants.dart';
import 'dio_client.dart';

part 'auth_service.g.dart';

/// Riverpod provider for AuthService.
@Riverpod(keepAlive: true)
AuthService authService(Ref ref) {
  // Inject the Dio client (with interceptor) and secure storage
  return AuthService(ref.read(dioClientProvider), ref.read(secureStorageProvider));
}

/// Handles all authentication-related API calls and token management.
class AuthService {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  static const String _kAuthTokenKey = 'auth_token';

  AuthService(this._dio, this._storage);

  /// Stores the JWT authentication token securely.
  Future<void> _saveToken(String token) async {
    await _storage.write(key: _kAuthTokenKey, value: token);
  }

  /// Retrieves the JWT authentication token.
  Future<String?> getToken() async {
    return _storage.read(key: _kAuthTokenKey);
  }

  /// Handles user login. Returns the authenticated User object.
  Future<User> login(String username, String password) async {
    try {
      final response = await _dio.post(
        kLoginEndpoint,
        data: {
          'username': username,
          'password': password,
        },
      );

      // API expected to return: {"token": "...", "user": {...}}
      final token = response.data['token'] as String;
      final userJson = response.data['user'];

      await _saveToken(token);
      // Ensure we return the User object here
      return User.fromJson(userJson); 
    } on DioException {
      rethrow;
    }
  }

  /// Handles user registration. Returns the newly created User object.
  Future<User> register(String username, String email, String password) async {
    try {
      final response = await _dio.post(
        kRegisterEndpoint,
        data: {
          'username': username,
          'email': email,
          'password': password,
        },
      );

      // API expected to return: {"token": "...", "user": {...}}
      final token = response.data['token'] as String;
      final userJson = response.data['user'];

      await _saveToken(token);
      // Ensure we return the User object here
      return User.fromJson(userJson);
    } on DioException {
      rethrow;
    }
  }

  /// Logs the user out by deleting the stored token.
  Future<void> logout() async {
    await _storage.delete(key: _kAuthTokenKey);
  }
}
