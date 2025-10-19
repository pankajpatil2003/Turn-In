import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'registration/registration_flow.dart';
import '../models/user_model.dart';
import '../services/token_storage_service.dart';
import 'home_screen.dart'; 

enum AuthMode { login, register }

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  AuthMode _mode = AuthMode.login; // Default to Login
  AuthTokens? _userTokens;
  final TokenStorageService _tokenService = TokenStorageService(); // <-- INSTANTIATE TOKEN SERVICE
  bool _isInitializing = true; // <-- NEW: State to show loading while checking tokens

  @override
  void initState() {
    super.initState();
    _checkInitialAuthStatus(); // Check for existing token on launch
  }

  // NEW: Checks shared preferences for an existing token on app start
  Future<void> _checkInitialAuthStatus() async {
    final accessToken = await _tokenService.getAccessToken();
    if (accessToken != null) {
      // If token found, set the user as logged in. (Refresh token is optional here)
      _userTokens = AuthTokens(accessToken: accessToken, refreshToken: 'placeholder'); 
    }
    setState(() {
      _isInitializing = false;
    });
  }

  void _handleLoginSuccess(AuthTokens tokens) async { // <-- NOW ASYNC TO SAVE TOKENS
    await _tokenService.saveTokens(tokens); // Save tokens persistently
    setState(() {
      _userTokens = tokens;
      print('User logged in and tokens saved.');
    });
  }

  // NEW: Handles the logout action from the HomeScreen
  void _handleLogout() async {
    await _tokenService.clearTokens(); // Clear tokens from storage
    setState(() {
      _userTokens = null;
      _mode = AuthMode.login; // Reset to login view
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logged out successfully.')),
      );
    });
  }

  void _handleRegistrationSuccess() {
    // After successful registration, switch the user back to the Login screen
    setState(() {
      _mode = AuthMode.login;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration complete! Please log in.')),
      );
    });
  }
  
  void _toggleMode() {
    setState(() {
      _mode = _mode == AuthMode.login ? AuthMode.register : AuthMode.login;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show a spinner while checking storage for an initial token
    if (_isInitializing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    // --- 1. Logged In State ---
    if (_userTokens != null) {
      // Use the HomeScreen and pass the logout handler and token
      return HomeScreen(
        onLogout: _handleLogout,
        accessToken: _userTokens!.accessToken,
      );
    }

    // --- 2. Auth State (Login or Register) ---
    if (_mode == AuthMode.login) {
      return LoginScreen(
        onLoginSuccess: _handleLoginSuccess,
        onNavigateToRegister: _toggleMode, 
      );
    } else {
      return RegistrationFlow(
        onRegistrationSuccess: _handleRegistrationSuccess, 
        onBackToLogin: _toggleMode, 
      );
    }
  }
}