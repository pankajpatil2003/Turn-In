import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'registration/registration_flow.dart';
import '../models/user_model.dart'; // Import AuthTokens

enum AuthMode { login, register }

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  AuthMode _mode = AuthMode.login; // Default to Login
  AuthTokens? _userTokens; // Will hold tokens after successful login

  void _handleLoginSuccess(AuthTokens tokens) {
    setState(() {
      _userTokens = tokens;
      // In a real app, you would save these tokens securely here.
      print('User logged in successfully! Access Token: ${tokens.accessToken}');
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
    // --- 1. Logged In State ---
    if (_userTokens != null) {
      // In a real app, this would be the HomePage or Dashboard.
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Successfully Logged In!', style: TextStyle(fontSize: 24)),
              Text('Token received: ${_userTokens!.accessToken.substring(0, 10)}...'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => setState(() => _userTokens = null),
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      );
    }

    // --- 2. Auth State (Login or Register) ---
    if (_mode == AuthMode.login) {
      return LoginScreen(
        onLoginSuccess: _handleLoginSuccess,
        // Link to Registration
        onNavigateToRegister: _toggleMode, 
      );
    } else {
      return RegistrationFlow(
        // The registration flow must now notify the wrapper on success
        onRegistrationSuccess: _handleRegistrationSuccess, 
        // Link back to Login
        onBackToLogin: _toggleMode, 
      );
    }
  }
}