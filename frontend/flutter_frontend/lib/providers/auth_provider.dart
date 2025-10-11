import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_frontend/data/models/user.dart';
import 'package:flutter_frontend/data/services/auth_service.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_provider.freezed.dart';
part 'auth_provider.g.dart';

/// 1. Auth State Model (Freezed)
@freezed
// FIX: AuthState must be defined as an abstract class to use the _$AuthState mixin.
abstract class AuthState with _$AuthState {
  // FIX: The constructor must be a private factory that defines the state shape.
  const factory AuthState({
    @Default(false) bool isLoading,
    @Default(false) bool isAuthenticated,
    @Default(false) bool isLoggingIn,
    @Default(false) bool isRegistering,
    User? user,
    String? error,
  }) = _AuthState;
}

/// 2. Auth State Notifier (Riverpod)
@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  late final AuthService _authService;

  @override
  AuthState build() {
    _authService = ref.read(authServiceProvider);
    
    // Check local storage for existing token and attempt to authenticate user
    _checkAuthenticationStatus();

    return const AuthState();
  }

  /// Checks for an existing token and sets isAuthenticated flag.
  Future<void> _checkAuthenticationStatus() async {
    final token = await _authService.getToken();

    if (token != null) {
      // If a token exists, assume authenticated (or add a validation call here)
      state = state.copyWith(isAuthenticated: true);
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Attempts to log the user in.
  Future<void> login(String username, String password) async {
    state = state.copyWith(isLoggingIn: true, error: null);

    try {
      // FIX: Explicitly assign the result of the async call to a User variable
      final User loggedInUser = await _authService.login(username, password);

      state = state.copyWith(
        user: loggedInUser, // Use the fixed variable
        isAuthenticated: true,
        isLoggingIn: false,
      );
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Invalid credentials or network error.';
      state = state.copyWith(
        error: message,
        isLoggingIn: false,
      );
    }
  }

  /// Attempts to register a new user.
  Future<void> register(String username, String email, String password) async {
    state = state.copyWith(isRegistering: true, error: null);

    try {
      // FIX: Explicitly assign the result of the async call to a User variable
      final User newUser = await _authService.register(username, email, password);

      // Automatically log the user in after successful registration
      state = state.copyWith(
        user: newUser, // Use the fixed variable
        isAuthenticated: true,
        isRegistering: false,
      );
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Registration failed. Username/Email may be taken.';
      state = state.copyWith(
        error: message,
        isRegistering: false,
      );
    }
  }

  /// Logs the user out and clears the state.
  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState(isAuthenticated: false, isLoading: false);
  }

  /// Clears the current error message.
  void clearError() {
    state = state.copyWith(error: null);
  }
}
