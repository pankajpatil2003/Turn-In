// lib/screens/registration/final_registration_screen.dart (Final Working Version)

import 'package:flutter/material.dart';
import 'dart:async'; // REQUIRED: For the Timer class
import '../../services/auth_service.dart';
import '../../models/user_model.dart';

class FinalRegistrationScreen extends StatefulWidget {
  final String email;
  final VoidCallback onRegistrationSuccess;
  final VoidCallback onBack;

  const FinalRegistrationScreen({
    super.key,
    required this.email,
    required this.onRegistrationSuccess,
    required this.onBack,
  });

  @override
  State<FinalRegistrationScreen> createState() => _FinalRegistrationScreenState();
}

class _FinalRegistrationScreenState extends State<FinalRegistrationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _otpCodeController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String _errorMessage = '';
  String? _usernameErrorText; // State to hold the asynchronous username error

  // Debounce logic for better real-time user feedback
  Timer? _debounce; 

  // Function to perform the asynchronous username availability check
  void _performUsernameCheck(String username) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Only check if the input is not empty
    if (username.isEmpty) {
      setState(() {
        _usernameErrorText = null;
      });
      return;
    }

    // Start a new timer to wait 500ms after the user stops typing
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      
      try {
        final isAvailable = await _authService.checkUsernameAvailability(username);
        
        setState(() {
          if (!isAvailable) {
            _usernameErrorText = 'This username is already taken. Choose another.';
          } else {
            _usernameErrorText = null; // Clear error if available
          }
        });
      } catch (e) {
        // Handle network error during live check by showing a generic message
        setState(() {
          _usernameErrorText = 'Could not check availability.';
        });
      }
    });
  }

  Future<void> _handleRegistration() async {
    // 1. Run synchronous form validation (checks required fields, password length, etc.)
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match.';
      });
      return;
    }
    
    // Check if real-time check already failed and prevented submission
    if (_usernameErrorText != null) {
      // Ensure the error is visible and halt submission
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // 2. Perform FINAL asynchronous username check before sending registration data
    try {
      final username = _usernameController.text.trim();
      final isAvailable = await _authService.checkUsernameAvailability(username);

      if (!isAvailable) {
        setState(() {
          _usernameErrorText = 'This username is already taken. Please choose another.';
          _isLoading = false;
        });
        return; // Stop registration
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to verify username: ${e.toString().replaceFirst('Exception: ', '')}';
        _isLoading = false;
      });
      return;
    }
    
    // 3. Complete Registration
    try {
      final registrationData = RegistrationData(
        email: widget.email,
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        passwordConfirm: _confirmPasswordController.text,
        otpCode: _otpCodeController.text.trim(),
      );

      await _authService.completeRegistration(registrationData);

      // Success: Notify parent AuthFlow/AuthWrapper
      widget.onRegistrationSuccess();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel(); // Cancel the timer to prevent memory leaks
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Registration (Step 2 of 2)'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Final Step',
                  style: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),

                TextFormField(
                  controller: _otpCodeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'OTP Code',
                    hintText: 'Enter 6-digit code',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.vpn_key),
                  ),
                  validator: (value) => (value == null || value.length != 6) ? 'Enter the exact 6-digit OTP.' : null,
                ),
                const SizedBox(height: 15),

                // --- UPDATED: Username TextFormField ---
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person),
                    errorText: _usernameErrorText, // Use state for async error message
                  ),
                  // Run synchronous validation only
                  validator: (value) => (value == null || value.isEmpty) ? 'Username is required.' : null, 
                  
                  // Trigger the real-time asynchronous check on change
                  onChanged: _performUsernameCheck,
                  
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (value) => (value == null || value.length < 8) ? 'Password must be at least 8 characters.' : null,
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_reset),
                  ),
                  validator: (value) => (value == null || value.isEmpty) ? 'Confirm your password.' : null,
                ),
                const SizedBox(height: 20),
                
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                    
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    // Disable if loading or if the live checker has flagged an error
                    onPressed: (_isLoading || _usernameErrorText != null) ? null : _handleRegistration,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Register Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                
                TextButton(
                  onPressed: widget.onBack,
                  child: const Text('← Change Email / Resend OTP'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}