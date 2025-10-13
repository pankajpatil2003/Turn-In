import 'package:flutter/material.dart';
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

  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final registrationData = RegistrationData(
        email: widget.email,
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        passwordConfirm: _confirmPasswordController.text,
        otpCode: _otpCodeController.text.trim(),
      );

      await _authService.completeRegistration(registrationData);

      // Success: Notify parent and show success screen
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Registration'),
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
                const SizedBox(height: 8),
                Text(
                  'Enter details and the OTP sent to: ${widget.email}',
                  style: const TextStyle(fontSize: 16.0, color: Colors.grey),
                ),
                const SizedBox(height: 30),

                // OTP Code Field
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

                // Username Field
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) => (value == null || value.isEmpty) ? 'Username is required.' : null,
                ),
                const SizedBox(height: 15),

                // Password Field
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

                // Confirm Password Field
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
                    onPressed: _isLoading ? null : _handleRegistration,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: Colors.green, // Use a distinct color for registration
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
                  child: const Text('← Go Back to OTP Request'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}