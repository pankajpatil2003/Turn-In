// lib/screens/registration/registration_flow.dart (Modified)

// Update the imports and the class definition:
import 'package:flutter/material.dart';
import 'otp_request_screen.dart';
import 'final_registration_screen.dart';

class RegistrationFlow extends StatefulWidget {
  final VoidCallback onRegistrationSuccess; // <-- New requirement
  final VoidCallback onBackToLogin; // <-- New requirement

  const RegistrationFlow({
    super.key,
    required this.onRegistrationSuccess,
    required this.onBackToLogin,
  });

  @override
  State<RegistrationFlow> createState() => _RegistrationFlowState();
}

class _RegistrationFlowState extends State<RegistrationFlow> {
  String? _registrationEmail; 
  // bool _registrationSuccessful is NO LONGER NEEDED here, 
  // we use the callback to notify the AuthWrapper
  
  void _handleOtpRequested(String email) {
    setState(() {
      _registrationEmail = email;
    });
  }

  // Final step success handler calls the parent's success method
  void _handleFinalRegistrationSuccess() {
     widget.onRegistrationSuccess(); 
  }

  void _resetFlow() {
    setState(() {
      _registrationEmail = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_registrationEmail == null) {
      // Step 1: Request OTP
      return OtpRequestScreen(
        onOtpRequested: _handleOtpRequested,
        onBackToLogin: widget.onBackToLogin, // Pass link to login
      );
    } else {
      // Step 2: Final Registration
      return FinalRegistrationScreen(
        email: _registrationEmail!,
        onRegistrationSuccess: _handleFinalRegistrationSuccess,
        onBack: _resetFlow,
      );
    }
  }
}